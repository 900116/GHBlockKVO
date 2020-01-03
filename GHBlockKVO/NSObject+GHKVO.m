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

@interface GHNotiEventToken : NSObject

@property (nonatomic,assign) BOOL onMain;
@property (nonatomic,copy) NSString *tid;
@property (nonatomic,copy) NSNotificationName name;
@property (nonatomic,copy) GHNotiCallback callBack;

@end

@implementation GHNotiEventToken

- (instancetype)initWithCallBack:(GHNotiCallback)callBack name:(NSNotificationName)name onMain:(BOOL)onMain{
    self = [super init];
    if (self) {
        self.callBack = callBack;
        self.onMain = onMain;
        self.tid = [NSUUID UUID].UUIDString;
        self.name = name;
    }
    return self;
}

@end


@interface GHKVOEventBags : NSObject

@property (nonatomic,strong) NSMutableDictionary <NSString*,NSMutableArray *> *kvoEventDict;
@property (nonatomic,strong) NSMutableDictionary <NSString*,NSMutableArray *> *notiEventDict;
@property (nonatomic,weak) id observed;
@property (nonatomic,strong) dispatch_semaphore_t kvolock;
@property (nonatomic,strong) dispatch_semaphore_t notilock;

@end

@implementation GHKVOEventBags

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.kvoEventDict = [NSMutableDictionary new];
        self.notiEventDict = [NSMutableDictionary new];
        self.kvolock = dispatch_semaphore_create(1);
        self.notilock = dispatch_semaphore_create(1);
    }
    return self;
}

typedef void (^GHKVOSafeEvecuteBlk)(void);

#pragma mark KVO

- (void)safeKVOExecute:(GHKVOSafeEvecuteBlk)blk {
    dispatch_semaphore_wait(self.kvolock, DISPATCH_TIME_FOREVER);
    blk();
    dispatch_semaphore_signal(self.kvolock);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self postAllMsg:object change:change context:context keyPath:keyPath];
}

- (GHKVOEventToken *)addObservedKeyPath: (NSString *)keypath callBack:(GHKVOCallback)callBack onMain:(BOOL)onMain {
    __block GHKVOEventToken *res = nil;
    [self safeKVOExecute:^{
        GHKVOEventToken *token = [[GHKVOEventToken alloc]initWithCallBack:callBack keyPath:keypath onMain:onMain];
        NSMutableArray *tokens = self.kvoEventDict[keypath];
        if (!tokens) {
            tokens = [NSMutableArray new];
        }
        [tokens addObject:token];
        self.kvoEventDict[keypath] = tokens;
        res = token;
    }];
    return res;
}

- (void)removeObserved: (GHKVOEventToken *)token{
    [self safeKVOExecute:^{
        NSMutableArray *tokens = self.kvoEventDict[token.keyPath];
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

- (void)removeKeyPath: (NSString *)keyPath {
    [self safeKVOExecute:^{
        if (self.kvoEventDict[keyPath]) {
            [self.kvoEventDict removeObjectForKey:keyPath];
            [self.observed removeObserver:self forKeyPath:keyPath];
        }
    }];
}


- (void)postAllMsg: (id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context keyPath:(NSString *)keyPath{
    [self safeKVOExecute:^{
        NSArray<GHKVOEventToken *> *tokens = self.kvoEventDict[keyPath];
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


#pragma mark Notification

- (void)safeNotiExecute:(GHKVOSafeEvecuteBlk)blk {
    dispatch_semaphore_wait(self.notilock, DISPATCH_TIME_FOREVER);
    blk();
    dispatch_semaphore_signal(self.notilock);
}

- (void)removeNotiName:(NSNotificationName)name object:(id)object{
    [self safeNotiExecute:^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:object];
        [self.notiEventDict removeObjectForKey:name];
    }];
}

- (void)removeNotiToken: (GHNotiEventToken *)token {
    [self safeNotiExecute:^{
        NSMutableArray *tokens = self.notiEventDict[token.name];
        GHNotiEventToken *rt = nil;
        for (GHNotiEventToken *token in tokens) {
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

- (void)receiveNotification:(NSNotification *)nf {
    [self safeNotiExecute:^{
        NSArray<GHNotiEventToken *> *tokens = self.notiEventDict[nf.name];
        for (GHNotiEventToken *token in tokens) {
            if (token.callBack) {
                if (token.onMain) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        token.callBack(nf);
                    });
                } else {
                    token.callBack(nf);
                }
            }
        }
    }];
}

- (GHNotiEventToken *)addNotificationForName: (NSNotificationName)name object:(id)object callBack:(GHNotiCallback)callBack onMain:(BOOL)onMain{
    if (![self.notiEventDict objectForKey:name]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:name object:object];
    }
    __block GHNotiEventToken *resToken = nil;
    [self safeNotiExecute:^{
        GHNotiEventToken *token = [[GHNotiEventToken alloc]initWithCallBack:callBack name:name onMain:onMain];
        NSMutableArray *tokens = self.notiEventDict[name];
        if (!tokens) {
            tokens = [NSMutableArray new];
        }
        [tokens addObject:token];
        self.notiEventDict[name] = tokens;
        resToken = token;
    }];
    return resToken;
}

- (void)dealloc {
    //移除所有监听
    [self safeKVOExecute:^{
        [self.kvoEventDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
             [self.observed removeObserver:self forKeyPath:key];
        }];
    }];
    
    if (self.notiEventDict.count > 0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}
@end


@implementation NSObject (GHKVO)

#pragma mark KVO

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
    if (!self.eventBags.kvoEventDict[keyPath]) {
         [self addObserver:self.eventBags forKeyPath:keyPath options:options context:NULL];
    }
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

- (void)gh_removeKeyPath: (NSString *)keyPath {
    [self.eventBags removeKeyPath:keyPath];
}

#pragma mark Noti

- (GHNotiEventToken *)gh_addNotification: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack {
    return [self.eventBags addNotificationForName:name object:object callBack:callBack onMain:NO];
}

- (GHNotiEventToken *)gh_addNotificationOnMain: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack {
    return [self.eventBags addNotificationForName:name object:object callBack:callBack onMain:NO];
}

- (void)gh_removeNotiName: (NSNotificationName)name object:(_Nullable id)object{
    [self.eventBags removeNotiName:name object:object];
}


- (void)gh_removeNotiToken: (GHNotiEventToken *)token {
    [self.eventBags removeNotiToken:token];
}


void * const kEventBagsKey = "kEventBagsKey";

- (GHKVOEventBags *)eventBags {
    return objc_getAssociatedObject(self, kEventBagsKey);
}

- (void)setEventBags:(GHKVOEventBags *)eventBags {
    return objc_setAssociatedObject(self, kEventBagsKey, eventBags, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
