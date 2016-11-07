//
//  EPUBViewController.h
//  EpubDemo
//
//  Created by XuPeng on 16/11/3.
//  Copyright © 2016年 XP. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPUBViewController : UIViewController<UIWebViewDelegate>

@property (nonatomic, copy) UIWebView *webView;

- (instancetype)initWithEPUBName:(NSString *)name currentPageRefIndex:(NSInteger)currentPageRefIndex currentChapterRefIndex:(NSInteger)currentChapterRefIndex;

@end
