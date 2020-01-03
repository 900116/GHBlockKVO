//
//  NSObject+GHKVO.h
//  GHBlockKVO
//
//  Created by GuangHui Zhao on 2020/1/3.
//  Copyright © 2020 GuangHui Zhao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GHKVOEventToken;
@class GHNotiEventToken;
typedef void(^GHKVOCallback)(id object,NSDictionary<NSKeyValueChangeKey,id> *change,void * context);
typedef void(^GHNotiCallback)(NSNotification *nf);

@interface NSObject (GHKVO)

- (GHKVOEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack;
- (GHKVOEventToken *)gh_addKeypathOnMain:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack;

- (void)gh_removeObserved: (GHKVOEventToken *)token;
- (void)gh_removeKeyPath: (NSString *)keyPath;


- (GHNotiEventToken *)gh_addNotification: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack;
- (GHNotiEventToken *)gh_addNotificationOnMain: (NSNotificationName)name object:(_Nullable id)object callBack:(GHNotiCallback)callBack;

- (void)gh_removeNotiName: (NSNotificationName)name;
- (void)gh_removeNotiToken: (GHNotiEventToken *)token;

@end

NS_ASSUME_NONNULL_END
