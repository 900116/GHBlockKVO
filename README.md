## GHBlockKVO
基于Block的KVO框架，支持一对多，对象消失后自动remove  
新增基于block的调位置，对象消失后自动remove

### Demo
``` objc
@interface Person: NSObject

@property (nonatomic, copy) NSString *name; 

@end

//添加监听

- (void)example {
    Person *person = [Person new];

    //与set方法在同一个线程
    GHKVOEventToken *token = [person gh_addKeypath:@"name" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
        NSLog(@"%@",object);
    }];

    //回调在主线程
    GHKVOEventToken *token2 = [person gh_addKeypathOnMain:@"name" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
        NSLog(@"%@",object);
    }];

    person.name = @"Jack";

    //移除监听
    [person gh_removeObserved:token];
    [person gh_removeObserved:token2];

    //移除所有的text监听
    [person gh_removeKeyPath:@"name"];

    //自动移除
    [person gh_addKeypathOnMain:@"name" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
        NSLog(@"%@",object);
    }];

    //增加通知监听
    GHNotiEventToken *notiToken = [person gh_addNotification:@"hello" object:nil callBack:^(NSNotification * _Nonnull nf) {
        NSLog(@"noti_token1:%@",nf);
    }];

    [person gh_addNotificationOnMain:@"hello" object:nil callBack:^(NSNotification * _Nonnull nf) {
        NSLog(@"noti_token2:%@",nf);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hello" object:nil];
    
    [person gh_removeNotiToken:notiToken];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hello" object:nil];

    //person dealloc的时候，token3,notitoken2被移除


}

```
