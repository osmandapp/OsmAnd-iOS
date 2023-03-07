//
//  OABaseWebViewContoller.m
//  OsmAnd Maps
//
//  Created by Skalii on 06.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseWebViewController.h"
#import "OAAppSettings.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

@implementation OABaseWebViewController

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseWebViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.navigationDelegate = self;
    self.webView.scrollView.delegate = self;

    [self loadWebView];
}

#pragma mark - Web data

- (NSURL *)getUrl
{ 
    return [NSURL URLWithString:@""];
}

- (NSString *)getContent
{
    return @"";
}

- (EOADownloadMode)getImagesDownloadMode
{
    return EOADownloadModeAny;
}

- (BOOL)isDownloadImagesOnlyNow
{
    return NO;
}

- (void)resetDownloadImagesOnlyNow
{
}

#pragma mark - WebView

- (void)loadWebView
{
    [UIView transitionWithView:self.webView
                      duration:.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                    [[WKContentRuleListStore defaultStore] compileContentRuleListForIdentifier:@"ContentBlockingRules"
                                                                        encodedContentRuleList:kImagesBlockRules
                                                                             completionHandler:^(WKContentRuleList *contentRuleList, NSError *error) {
                        if (!error)
                        {
                            EOADownloadMode imagesDownloadMode = [self getImagesDownloadMode];
                            WKWebViewConfiguration *configuration = self.webView.configuration;

                            if (![self isDownloadImagesOnlyNow] && ((imagesDownloadMode == EOADownloadModeNone) || (imagesDownloadMode == EOADownloadModeWiFi && [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN])))
                                [[configuration userContentController] addContentRuleList:contentRuleList];
                            else
                                [[configuration userContentController] removeContentRuleList:contentRuleList];

                            [self resetDownloadImagesOnlyNow];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.webView loadHTMLString:[self getContent] baseURL:[self getUrl]];
                            });
                        }
                    }];
                    } completion:nil];
}

- (void)webViewDidLoad
{
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self webViewDidLoad];
}

@end
