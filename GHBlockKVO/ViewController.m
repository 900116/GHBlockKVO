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
    
    //only token2 print
}


@end
