//
//  NSObject+GHKVO.m
//  GHBlockKVO
//
//  Created by GuangHui Zhao on 2020/1/3.
//  Copyright © 2020 GuangHui Zhao. All rights reserved.
//

#import "NSObject+GHKVO.h"
#import <objc/runtime.h>

@interface GHEventToken : NSObject

@property (nonatomic,assign) BOOL onMain;
@property (nonatomic,copy) NSString *tid;

- (NSString *)key;

@end

@implementation GHEventToken

- (instancetype)initWithOnMain:(BOOL)onMain {
    self = [super init];
    if (self) {
        self.onMain = onMain;
        self.tid = [NSUUID UUID].UUIDString;
    }
    return self;
}

- (NSString *)key {
    return nil;
}

@end

@interface GHKVOEventToken : GHEventToken

@property (nonatomic,copy) NSString *keyPath;
@property (nonatomic,copy) GHKVOCallback callBack;

@end

@implementation GHKVOEventToken

- (instancetype)initWithCallBack:(GHKVOCallback)callBack keyPath:(NSString *)keyPath onMain:(BOOL)onMain{
    self = [super initWithOnMain:onMain];
    if (self) {
        self.callBack = callBack;
        self.keyPath = keyPath;
    }
    return self;
}

- (NSString *)key {
    return self.keyPath;
}

@end

@interface GHNotiEventToken : GHEventToken

@property (nonatomic,copy) NSNotificationName name;
@property (nonatomic,copy) GHNotiCallback callBack;

@end

@implementation GHNotiEventToken

- (instancetype)initWithCallBack:(GHNotiCallback)callBack name:(NSNotificationName)name onMain:(BOOL)onMain{
    self = [super initWithOnMain:onMain];
    if (self) {
        self.callBack = callBack;
        self.name = name;
    }
    return self;
}


- (NSString *)key {
    return self.name;
}

@end


@interface GHEventBags : NSObject

@property (nonatomic,strong) NSMutableDictionary <NSString*,NSMutableArray *> *kvoEventDict;
@property (nonatomic,strong) NSMutableDictionary <NSString*,NSMutableArray *> *notiEventDict;
@property (nonatomic,weak) id observed;
@property (nonatomic,strong) dispatch_semaphore_t kvolock;
@property (nonatomic,strong) dispatch_semaphore_t notilock;

@end

@implementation GHEventBags

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

typedef void (^GHSafeEvecuteBlk)(void);

#pragma mark base
- (void)safeExecute:(GHSafeEvecuteBlk)blk isKVO:(BOOL)isKVO{
    dispatch_semaphore_t lock = self.notilock;
    if (isKVO) {
        lock = self.kvolock;
    }
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    blk();
    dispatch_semaphore_signal(lock);
}

- (void)removeObserver: (GHEventToken *)token isKVO:(BOOL)isKVO{
    [self safeExecute:^{
        NSDictionary *opDict = self.notiEventDict;
        if (isKVO) {
            opDict = self.kvoEventDict;
        }
        NSMutableArray *tokens = opDict[token.key];
        GHEventToken *rt = nil;
        for (GHEventToken *token in tokens) {
            if ([token.tid isEqualToString:token.tid]) {
                rt = token;
                break;
            }
        }
        if (rt) {
            [tokens removeObject:rt];
        }
    } isKVO:isKVO];
}

- (void)removeKey: (NSString *)key object:(id)object isKVO:(BOOL)isKVO{
    [self safeExecute:^{
        NSMutableDictionary *opDict = self.notiEventDict;
        if (isKVO) {
            opDict = self.kvoEventDict;
        }
        if (opDict[key]) {
            if (isKVO) {
                [opDict removeObjectForKey:key];
            } else {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:key object:object];
            }
            [opDict removeObjectForKey:key];
        }
    } isKVO:isKVO];
}

- (GHEventToken *)addTokenForKey: (NSString *)key object:(id)object options:(NSKeyValueObservingOptions)options callBack:(id)callBack onMain:(BOOL)onMain isKVO:(BOOL)isKVO{
    __block GHEventToken *res = nil;
    [self safeExecute:^{
        GHEventToken *token = nil;
        NSMutableDictionary *opDict = nil;
        if (isKVO) {
            token = [[GHKVOEventToken alloc]initWithCallBack:callBack keyPath:key onMain:onMain];
            opDict = self.kvoEventDict;
            if (!opDict[key]) {
                 [self.observed addObserver:self forKeyPath:key options:options context:NULL];
            }
        } else {
            token = [[GHNotiEventToken alloc]initWithCallBack:callBack name:key onMain:onMain];
            opDict = self.notiEventDict;
            if (!opDict[key]) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:key object:object];
            }
        }
        NSMutableArray *tokens = opDict[key];
        if (!tokens) {
            tokens = [NSMutableArray new];
        }
        [tokens addObject:token];
        opDict[key] = tokens;
        res = token;
    } isKVO:isKVO];
    return res;
}

#pragma mark KVO

- (void)safeKVOExecute:(GHSafeEvecuteBlk)blk {
    [self safeExecute:blk isKVO:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self postAllMsg:object change:change context:context keyPath:keyPath];
}

- (GHEventToken *)addObservedKeyPath: (NSString *)keypath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack onMain:(BOOL)onMain {
    return [self addTokenForKey:keypath object:nil options:options callBack:callBack onMain:onMain isKVO:YES];
}

- (void)removeObserver: (GHKVOEventToken *)token{
    [self removeObserver:token isKVO:YES];
}

- (void)removeKeyPath: (NSString *)keyPath {
    [self removeKey:keyPath object:nil isKVO:YES];
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

- (void)safeNotiExecute:(GHSafeEvecuteBlk)blk {
    [self safeExecute:blk isKVO:NO];
}

- (void)removeNotiName:(NSNotificationName)name object:(id)object{
     [self removeKey:name object:object isKVO:NO];
}

- (void)removeNotiToken: (GHNotiEventToken *)token {
    [self removeObserver:token isKVO:NO];
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

- (GHEventToken *)addNotificationForName: (NSNotificationName)name object:(id)object callBack:(GHNotiCallback)callBack onMain:(BOOL)onMain{
    return [self addTokenForKey:name object:object options:NSKeyValueObservingOptionNew callBack:callBack onMain:onMain isKVO:NO];
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

- (GHEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack onMain:(BOOL)onMain {
    __block GHEventBags *bags = self.eventBags;
    if (!bags) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bags = [[GHEventBags alloc]init];
            bags.observed = self;
            self.eventBags = bags;
        });
    }
    return [bags addObservedKeyPath:keyPath options:options callBack:callBack onMain:onMain];
}

- (GHEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack {
    return [self gh_addKeypath:keyPath options:options callBack:callBack onMain:NO];
}

- (GHEventToken *)gh_addKeypathOnMain:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack {
    return [self gh_addKeypath:keyPath options:options callBack:callBack onMain:YES];
}

- (void)gh_removeObserver: (GHKVOEventToken *)token {
    [self.eventBags removeObserver:token];
}

- (void)gh_removeKeyPath: (NSString *)keyPath {
    [self.eventBags removeKeyPath:keyPath];
}

#pragma mark Noti

- (GHEventToken *)gh_addNotification: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack {
    return [self.eventBags addNotificationForName:name object:object callBack:callBack onMain:NO];
}

- (GHEventToken *)gh_addNotificationOnMain: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack {
    return [self.eventBags addNotificationForName:name object:object callBack:callBack onMain:NO];
}

- (void)gh_removeNotiName: (NSNotificationName)name object:(_Nullable id)object{
    [self.eventBags removeNotiName:name object:object];
}


- (void)gh_removeNotiObserver: (GHNotiEventToken *)token {
    [self.eventBags removeNotiToken:token];
}


void * const kEventBagsKey = "kEventBagsKey";

- (GHEventBags *)eventBags {
    return objc_getAssociatedObject(self, kEventBagsKey);
}

- (void)setEventBags:(GHEventBags *)eventBags {
    return objc_setAssociatedObject(self, kEventBagsKey, eventBags, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
