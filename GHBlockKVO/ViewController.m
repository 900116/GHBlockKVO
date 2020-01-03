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
        NSLog(@"%@",object);
    }];
    //when label dealloc the kvo autoremove
    
   
    // onMain
//    GHKVOEventToken *token = [label gh_addKeypathOnMain:@"text" options:NSKeyValueObservingOptionNew callBack:^(id object, NSDictionary<NSKeyValueChangeKey,id> *change, void *context) {
//        NSLog(@"%@",object);
//    }];
    label.text = @"hello";
    label.text = @"hi";
    [label gh_removeObserved:token];
    label.text = @"byebye";
}


@end
