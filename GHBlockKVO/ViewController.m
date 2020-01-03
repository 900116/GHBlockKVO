//
//  ViewController.m
//  GHBlockKVO
//
//  Created by GuangHui Zhao on 2020/1/3.
//  Copyright © 2020 GuangHui Zhao. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+GHKVO.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UILabel *label = [UILabel new];
    GHKVOEventToken *token = [label gh_addKeypath:@"text" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
        NSLog(@"token1:%@",change);
    }];
    //when label dealloc the kvo autoremove
    [label addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:NULL];
    
    label.text = @"hello";
    //only token1 print
   
    // onMain
    [label gh_addKeypathOnMain:@"text" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
        NSLog(@"token2:%@",change);
    }];
    label.text = @"hi";
    //token1 token2 print

    [label gh_removeObserved:token];
    label.text = @"byebye";
    
    [label gh_addKeypath:@"hidden" options:NSKeyValueObservingOptionNew callBack:^(id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change, void * _Nonnull context) {
         NSLog(@"token3:%@",change);
    }];
    
    [label gh_removeKeyPath:@"text"];
    label.text = @"dddd";
    //no notify
    label.hidden = YES;
    
    GHNotiEventToken *notiToken = [label gh_addNotification:@"hello" object:nil callBack:^(NSNotification * _Nonnull nf) {
        NSLog(@"noti_token1:%@",nf);
    }];
    
    [label gh_addNotificationOnMain:@"hello" object:nil callBack:^(NSNotification * _Nonnull nf) {
        NSLog(@"noti_token2:%@",nf);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hello" object:nil];
    
    [label gh_removeNotiToken:notiToken];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hello" object:nil];
    
    [label gh_removeNotiName:@"hello" object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hello" object:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
}

@end
