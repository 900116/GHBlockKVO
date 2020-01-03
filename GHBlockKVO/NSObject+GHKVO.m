//
//  NSObject+GHKVO.m
//  GHBlockKVO
//
//  Created by GuangHui Zhao on 2020/1/3.
//  Copyright © 2020 GuangHui Zhao. All rights reserved.
//

#import "NSObject+GHKVO.h"
#import <objc/runtime.h>

@interface GHKVOEventToken : NSObject

@property (nonatomic,assign) BOOL onMain;
@property (nonatomic,copy) NSString *tid;
@property (nonatomic,copy) NSString *keyPath;
@property (nonatomic,copy) GHKVOCallback callBack;

@end

@implementation GHKVOEventToken

- (instancetype)initWithCallBack:(GHKVOCallback)callBack keyPath:(NSString *)keyPath onMain:(BOOL)onMain{
    self = [super init];
    if (self) {
        self.callBack = callBack;
        self.onMain = onMain;
        self.tid = [NSUUID UUID].UUIDString;
        self.keyPath = keyPath;
    }
    return self;
}

@end


@interface GHKVOEventBags : NSObject

@property (nonatomic,strong) NSMutableDictionary <NSString*,NSMutableArray *> *eventDict;
@property (nonatomic,weak) id observed;
@property (nonatomic,strong) dispatch_semaphore_t lock;

@end

@implementation GHKVOEventBags

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.eventDict = [NSMutableDictionary new];
        self.lock = dispatch_semaphore_create(1);
    }
    return self;
}

typedef void (^GHKVOSafeEvecuteBlk)(void);

- (void)safeExecute:(GHKVOSafeEvecuteBlk)blk {
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    blk();
    dispatch_semaphore_signal(self.lock);
}

- (void)postAllMsg: (id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context keyPath:(NSString *)keyPath{
    [self safeExecute:^{
        NSArray<GHKVOEventToken *> *tokens = self.eventDict[keyPath];
        for (GHKVOEventToken *token in tokens) {
            if (token.callBack) {
                if (token.onMain) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        token.callBack(object, change, context);
                    });
                } else {
                    token.callBack(object, change, context);
                }
            }
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self postAllMsg:object change:change context:context keyPath:keyPath];
}

- (GHKVOEventToken *)addObservedKeyPath: (NSString *)keypath callBack:(GHKVOCallback)callBack onMain:(BOOL)onMain {
    __block GHKVOEventToken *res = nil;
    [self safeExecute:^{
        GHKVOEventToken *token = [[GHKVOEventToken alloc]initWithCallBack:callBack keyPath:keypath onMain:onMain];
        NSMutableArray *blocks = self.eventDict[keypath];
        if (!blocks) {
            blocks = [NSMutableArray new];
        }
        [blocks addObject:token];
        self.eventDict[keypath] = blocks;
        res = token;
    }];
    return res;
}

- (void)removeObserved: (GHKVOEventToken *)token{
    [self safeExecute:^{
        NSMutableArray *tokens = self.eventDict[token.keyPath];
        GHKVOEventToken *rt = nil;
        for (GHKVOEventToken *token in tokens) {
            if ([token.tid isEqualToString:token.tid]) {
                rt = token;
                break;
            }
        }
        if (rt) {
            [tokens removeObject:rt];
        }
    }];
}

- (void)dealloc {
    //移除所有监听
    [self safeExecute:^{
        [self.eventDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
             [self.observed removeObserver:self forKeyPath:key];
        }];
    }];
}
@end


@implementation NSObject (GHKVO)

- (GHKVOEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack onMain:(BOOL)onMain {
    __block GHKVOEventBags *bags = self.eventBags;
    if (!bags) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bags = [[GHKVOEventBags alloc]init];
            bags.observed = self;
            self.eventBags = bags;
        });
    }
    [self addObserver:self.eventBags forKeyPath:keyPath options:options context:NULL];
    return [bags addObservedKeyPath:keyPath callBack:callBack onMain:onMain];
}

- (GHKVOEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack {
    return [self gh_addKeypath:keyPath options:options callBack:callBack onMain:NO];
}

- (GHKVOEventToken *)gh_addKeypathOnMain:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack {
    return [self gh_addKeypath:keyPath options:options callBack:callBack onMain:YES];
}

- (void)gh_removeObserved: (GHKVOEventToken *)token {
    [self.eventBags removeObserved:token];
}

void * const kEventBagsKey = "kEventBagsKey";

- (GHKVOEventBags *)eventBags {
    return objc_getAssociatedObject(self, kEventBagsKey);
}

- (void)setEventBags:(GHKVOEventBags *)eventBags {
    return objc_setAssociatedObject(self, kEventBagsKey, eventBags, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
