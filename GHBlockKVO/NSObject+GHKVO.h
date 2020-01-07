//
//  NSObject+GHKVO.h
//  GHBlockKVO
//
//  Created by GuangHui Zhao on 2020/1/3.
//  Copyright © 2020 GuangHui Zhao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GHEventToken;

typedef void(^GHKVOCallback)(id object,NSDictionary<NSKeyValueChangeKey,id> *change,void * context);
typedef void(^GHNotiCallback)(NSNotification *nf);

@interface NSObject (GHKVO)

- (GHEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack;
- (GHEventToken *)gh_addKeypathOnMain:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack;

- (void)gh_removeObserver: (GHEventToken *)token;
- (void)gh_removeKeyPath: (NSString *)keyPath;


- (GHEventToken *)gh_addNotification: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack;
- (GHEventToken *)gh_addNotificationOnMain: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack;

- (void)gh_removeNotiName: (NSNotificationName)name object:(_Nullable id)object;
- (void)gh_removeNotiObserver: (GHEventToken *)token;

@end

NS_ASSUME_NONNULL_END
