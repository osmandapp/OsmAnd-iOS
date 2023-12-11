//
//  OAWebViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 27.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWebViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

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
        NSString *cssDay = @"  body { max-width: 100% !important; margin-top: 0%; margin-bottom: 30%; margin-left: 5%; margin-right: 5%; font-size: 1em; -webkit-text-size-adjust: none; } .main { background-color: #ffffff; font-family: sans-serif; padding-left: 7%; padding-right: 7%; } p { color: #212121; } h1 { color: #212121; font-family: -apple-system-headline1, sans-serif; } h2 { color: #454545; font-family: -apple-system, sans-serif;  } h3 { color: #727272; font-family: sans-serif; } h4, h5 { color: #454545; } p { color: #212121; } a, a.external.free, a.text { color: #237bff; text-decoration-color: #a3c8ff; word-wrap: break-word; } hr { color: #eaecf0; background-color: #eaecf0; } img { padding-bottom: 10%; }";
        
        NSString *cssNight = @"  body { max-width: 100% !important; margin-top: 0%; margin-bottom: 30%; margin-left: 5%; margin-right: 5%; font-size: 1em; -webkit-text-size-adjust: none; } .main { background-color: #17191a; font-family: sans-serif; padding-left: 7%; padding-right: 7%; } p { color: #cccccc; } h1 { color: #cccccc; font-family: -apple-system-headline1, sans-serif; } h2 { color: #999999; font-family: -apple-system, sans-serif;  } h3 { color: #727272; font-family: sans-serif; } h4, h5 { color: #999999; } p { color: #cccccc; } a, a.external.free, a.text { color: #d28521; text-decoration-color: #854f08; word-wrap: break-word; } hr { color: #2d3133; background-color: #2d3133; } img { padding-bottom: 10%; }";
        
        NSString *css = [ThemeManager shared].isLightTheme ? cssDay : cssNight;
        NSString *content = [NSString stringWithFormat:@"<html><head> <style> %@ </style></head> <body> %@ </body></html>", css, [self getContent]];
        [self.webView loadHTMLString:content baseURL:[NSURL URLWithString:@"https://osmand.net/"]];
    }
    else
    {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[self getUrl]];
        [self.webView loadRequest:urlRequest];
    }
}

- (void)webViewDidCommitted:(void (^)(void))onViewCommitted
{
    if ([[self getUrl].scheme isEqualToString:@"file"])
    {
        NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'", 250];
        [self.webView evaluateJavaScript:jsString completionHandler:^(id _Nullable object, NSError * _Nullable error) {
            if (onViewCommitted)
                onViewCommitted();
        }];
    }
    else
    {
        if (onViewCommitted)
            onViewCommitted();
    }
}

@end
