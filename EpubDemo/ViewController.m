//
//  ViewController.m
//  EpubDemo
//
//  Created by XuPeng on 16/11/1.
//  Copyright © 2016年 XP. All rights reserved.
//

#import "ViewController.h"
#import "EPUBViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
    EPUBViewController *_ePubVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _ePubVC = [[EPUBViewController alloc] initWithEPUBName:@"细说明朝" currentPageRefIndex:0 currentChapterRefIndex:0];
    [self.view addSubview:_ePubVC.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
