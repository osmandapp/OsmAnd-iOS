//
//  OAWebViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 27.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWebViewController.h"
#import "Localization.h"

@implementation OAWebViewController
{
    NSString *_title;
}

#pragma mark - Initialization

- (instancetype)initWithUrl:(NSString*)url
{
    self = [super init];
    if (self)
    {
        self.urlString = url;
    }
    return self;
}

- (instancetype)initWithUrlAndTitle:(NSString*)url title:(NSString *)title
{
    self = [super init];
    if (self)
    {
        self.urlString = url;
        _title = title;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _title ? _title : OALocalizedString(@"help_quiz");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Web data

- (NSURL *)getUrl
{
    return [NSURL URLWithString:self.urlString];
}

- (NSString *)getContent
{
    return [NSString stringWithContentsOfFile:[self getUrl].path
                                     encoding:NSUTF8StringEncoding
                                        error:NULL];
}

#pragma mark - Web load

- (void)loadWebView
{
    if ([[self getUrl].scheme isEqualToString:@"file"])
    {
        [self.webView loadHTMLString:[self getContent] baseURL:[NSURL URLWithString:@"https://osmand.net/"]];
    }
    else
    {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[self getUrl]];
        [self.webView loadRequest:urlRequest];
    }
}

- (void)webViewDidCommitted:(void (^)(void))onViewCommitted
{
    NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",(unsigned long) 250];
    [self.webView evaluateJavaScript:jsString completionHandler:^(id _Nullable object, NSError * _Nullable error) {
        if (onViewCommitted)
            onViewCommitted();
    }];
}

@end
