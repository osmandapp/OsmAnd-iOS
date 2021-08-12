//
//  OAWebViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 27.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWebViewController.h"
#import "Localization.h"

@interface OAWebViewController () <WKNavigationDelegate>

@end

@implementation OAWebViewController
{
    NSString *_title;
}

-(id)initWithUrl:(NSString*)url {
    self = [super init];
    if (self) {
        self.urlString = url;
    }
    return self;
}

-(id)initWithUrlAndTitle:(NSString*)url title:(NSString *) title
{
    self = [super init];
    if (self) {
        self.urlString = url;
        _title = title;
    }
    return self;
}

-(void)applyLocalization
{
    _titleLabel.text = _title ? _title : OALocalizedString(@"help_quiz");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self applySafeAreaMargins];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *websiteUrl = [NSURL URLWithString:self.urlString];
    if ([websiteUrl.scheme isEqualToString:@"file"]) {
        NSString* content = [NSString stringWithContentsOfFile:websiteUrl.path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        [_webView loadHTMLString:content baseURL:[NSURL URLWithString:@"https://osmand.net/"]];
        _webView.navigationDelegate = self;
    }
    else
    {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:websiteUrl];
        [_webView loadRequest:urlRequest];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",(unsigned long) 250];
    [webView evaluateJavaScript:jsString completionHandler:nil];
}

@end
