//
//  EPUBViewController.m
//  EpubDemo
//
//  Created by XuPeng on 16/11/3.
//  Copyright © 2016年 XP. All rights reserved.
//

#import "EPUBViewController.h"
#import "EPUBParser.h"

#define kContainer @"/META-INF/container.xml"

@interface EPUBViewController ()

@end

@implementation EPUBViewController {
    EPUBParser     *_ePubParser;
    NSInteger      _currentTextSize;
    NSString       *_currentFontName;
    NSString       *_ePubName;
    NSInteger      _currentPageRefIndex;
    NSInteger      _countPage;
    NSString       *_OPFPath;
    NSString       *_NCXPath;
    NSMutableArray *_ePubChapterArr;
    NSString       *_unzipPath;
    NSInteger      _currentChapter;
    
    UISwipeGestureRecognizer *_leftSwipeGestureRecognizer;
    UISwipeGestureRecognizer *_rightSwipeGestureRecognizer;
}
- (instancetype)initWithEPUBName:(NSString *)name currentPageRefIndex:(NSInteger)currentPageRefIndex currentChapterRefIndex:(NSInteger)currentChapterRefIndex {
    self = [super init];
    if (self) {
        _ePubName            = @"细说明朝";
        _currentPageRefIndex = currentPageRefIndex;
        _currentTextSize     = 20;
        _currentFontName     = @"Helvetica";
        _currentChapter      = currentChapterRefIndex;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getEPUBConfiguration];
    
    _webView                               = [UIWebView new];
    _webView.backgroundColor               = [UIColor colorWithRed:1.000 green:0.907 blue:0.926 alpha:1.000];
    _webView.opaque                        = NO;
    _webView.scrollView.scrollEnabled      = NO;
    _webView.scrollView.bounces            = NO;
    _webView.delegate                      = self;
    _webView.frame                         = CGRectMake(20, 20, [UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height - 40);
    NSString *pageURL                      = [self getURLPath];
    NSString *htmlContent                  = [_ePubParser HTMLContentFromFile:pageURL AddJsContent:[self jsContentWithViewRect:_webView.frame]];
    NSURL* baseURL                         = [NSURL fileURLWithPath:pageURL];
    [_webView loadHTMLString:htmlContent baseURL:baseURL];
    [self.view addSubview:_webView];

    _leftSwipeGestureRecognizer            = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    _rightSwipeGestureRecognizer           = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];

    _leftSwipeGestureRecognizer.direction  = UISwipeGestureRecognizerDirectionLeft;
    _rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

    [self.view addGestureRecognizer:_leftSwipeGestureRecognizer];
    [self.view addGestureRecognizer:_rightSwipeGestureRecognizer];
    
}

- (void)handleSwipes:(UISwipeGestureRecognizer *)swipeGestureRecognizer {
    if (swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        _currentPageRefIndex++;
    } else {
        _currentPageRefIndex--;
    }
    if (_currentPageRefIndex >= _countPage) {
        _currentChapter++;
        if (_currentChapter >= _ePubChapterArr.count) {
            _currentChapter = _ePubChapterArr.count - 1;
            _currentPageRefIndex = _countPage - 1;
        } else {
            _currentPageRefIndex  = 0;
            NSString *pageURL     = [self getURLPath];
            NSString *htmlContent = [_ePubParser HTMLContentFromFile:pageURL AddJsContent:[self jsContentWithViewRect:_webView.frame]];
            NSURL* baseURL        = [NSURL fileURLWithPath:pageURL];
            [_webView loadHTMLString:htmlContent baseURL:baseURL];
        }
    } else if (_currentPageRefIndex < 0) {
        _currentChapter--;
        if (_currentChapter < 0) {
            _currentChapter = 0;
            _currentPageRefIndex = 0;
        } else {
            _currentPageRefIndex  = 0;
            NSString *pageURL     = [self getURLPath];
            NSString *htmlContent = [_ePubParser HTMLContentFromFile:pageURL AddJsContent:[self jsContentWithViewRect:_webView.frame]];
            NSURL* baseURL        = [NSURL fileURLWithPath:pageURL];
            [_webView loadHTMLString:htmlContent baseURL:baseURL];
        }
    } else {
        [self gotoOffYInPageWithOffYIndex:_currentPageRefIndex WithOffCountInPage:_countPage];
    }
}

- (NSString *)getURLPath {
    NSDictionary *dic = _ePubChapterArr[_currentChapter];
    NSRange lastSlash = [_OPFPath rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *pageURL = [_OPFPath substringToIndex:lastSlash.location + 1];
    pageURL           = [NSString stringWithFormat:@"%@%@",pageURL,dic[@"src"]];
    return pageURL;
}

- (void)getEPUBConfiguration {
    _ePubName               = @"细说明朝";
    _ePubParser             = [[EPUBParser alloc] init];
    // 文件地址
    NSArray *searchPaths    = NSSearchPathForDirectoriesInDomains(
                                                                 NSLibraryDirectory,
                                                                 NSUserDomainMask,
                                                                 YES);
    _unzipPath              = [[NSString alloc] initWithFormat:@"%@/%@",[searchPaths objectAtIndex:0],_ePubName];
    NSString *fileFullPath  = [[NSBundle mainBundle] pathForResource:_ePubName ofType:@"epub" inDirectory:nil];
    NSString *containerPath = [NSString stringWithFormat:@"%@%@",_unzipPath,kContainer];
    _OPFPath                = [_ePubParser opfFilePathWithManifestFile:containerPath WithUnzipFolder:_unzipPath];
    if (!_OPFPath) {
        [_ePubParser openFilePath:fileFullPath WithUnzipFolder:_unzipPath];
        _OPFPath = [_ePubParser opfFilePathWithManifestFile:containerPath WithUnzipFolder:_unzipPath];
    }
    _NCXPath        = [_ePubParser ncxFilePathWithOpfFile:_OPFPath WithUnzipFolder:_unzipPath];
    _ePubChapterArr = [_ePubParser epubCatalogWithNcxFile:_NCXPath];
    
}

- (NSString*)jsContentWithViewRect:(CGRect)rectView {
    
    NSString *js0         = @"";
    NSString *js1         = @"<style>img {  max-width:100% ; }</style>\n";
    NSMutableArray *arrJs = [NSMutableArray array];
    [arrJs addObject:@"<script>"];
    [arrJs addObject:@"var mySheet = document.styleSheets[0];"];
    [arrJs addObject:@"function addCSSRule(selector, newRule){"];
    [arrJs addObject:@"if (mySheet.addRule){"];
    [arrJs addObject:@"mySheet.addRule(selector, newRule);"];
    [arrJs addObject:@"} else {"];
    [arrJs addObject:@"ruleIndex = mySheet.cssRules.length;"];
    [arrJs addObject:@"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"];
    [arrJs addObject:@"}"];
    [arrJs addObject:@"}"];
    
    // 首行缩进
    [arrJs addObject:@"addCSSRule('p', 'text-align: justify;');"];
    [arrJs addObject:@"addCSSRule('p', 'text-indent: 2em;');"];
    [arrJs addObject:@"addCSSRule('p', 'line-height:170%;');"];
    [arrJs addObject:@"addCSSRule('p', ' margin-bottom:-0.5em;');"];
    
    [arrJs addObject:@"addCSSRule('highlight', 'background-color: yellow;');"];
    NSString *css1     = [NSString stringWithFormat:@"addCSSRule('body', ' font-size:%@px;');",@(_currentTextSize)];
    [arrJs addObject:css1];
    NSString *fontName = _currentFontName;
    NSString *css2     = [NSString stringWithFormat:@"addCSSRule('body', ' font-family:\"%@\";');",fontName];
    [arrJs addObject:css2];
    [arrJs addObject:@"addCSSRule('body', ' margin:0 0 0 0;');"];
    NSString *css3     = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %@px; -webkit-column-gap: 0px; -webkit-column-width: %@px;');",@(rectView.size.height),@(rectView.size.width)];
    [arrJs addObject:css3];
    [arrJs addObject:@"</script>"];
    NSString *jsJoin   = [arrJs componentsJoinedByString:@"\n"];
    NSString *jsRet    = [NSString stringWithFormat:@"%@\n%@\n%@",js0,js1,jsJoin];
    return jsRet;
}

- (void)gotoOffYInPageWithOffYIndex:(NSInteger)offyIndex WithOffCountInPage:(NSInteger)offCountInPage {
    //页码内跳转
    offyIndex >= offCountInPage ? (offyIndex = offCountInPage - 1) : offyIndex;
    float pageOffset         = offyIndex * _webView.bounds.size.width;
    NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
    NSString* goTo           = [NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
    [_webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
    [_webView stringByEvaluatingJavaScriptFromString:goTo];
    NSString *themeBodyColor = @"#c7edcc";
    NSString *bodycolor      = [NSString stringWithFormat:@"addCSSRule('body', 'background-color: %@;')",themeBodyColor];
    [_webView stringByEvaluatingJavaScriptFromString:bodycolor];
    NSString *themeTextColor = @"#000000";
    NSString *textcolor1     = [NSString stringWithFormat:@"addCSSRule('h1', 'color: %@;')",themeTextColor];
    [_webView stringByEvaluatingJavaScriptFromString:textcolor1];
    NSString *textcolor2     = [NSString stringWithFormat:@"addCSSRule('p', 'color: %@;')",themeTextColor];
    [_webView stringByEvaluatingJavaScriptFromString:textcolor2];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        //禁止内容里面的超链接
        return NO;
    }
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    _countPage = theWebView.scrollView.contentSize.width / theWebView.bounds.size.width;
    [self gotoOffYInPageWithOffYIndex:_currentPageRefIndex WithOffCountInPage:_countPage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
