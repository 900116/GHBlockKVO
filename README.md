## GHBlockKVO
基于Block的KVO框架，支持一对多，对象消失后自动remove

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

    //自动移除
    [person gh_addKeypathOnMain:@"name" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
        NSLog(@"%@",object);
    }];

    //person dealloc的时候，token3被移除
}

```
