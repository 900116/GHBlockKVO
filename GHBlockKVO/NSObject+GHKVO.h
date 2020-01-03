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
typedef void(^GHKVOCallback)(id object,NSDictionary<NSKeyValueChangeKey,id> *change,void * context);

@interface NSObject (GHKVO)

- (GHKVOEventToken *)gh_addKeypath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack;

- (GHKVOEventToken *)gh_addKeypathOnMain:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callBack:(GHKVOCallback)callBack;

- (void)gh_removeObserved: (GHKVOEventToken *)token;

- (void)gh_removeKeyPath: (NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
