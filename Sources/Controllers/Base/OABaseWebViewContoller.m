//
//  OABaseWebViewContoller.m
//  OsmAnd Maps
//
//  Created by Skalii on 06.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseWebViewController.h"
#import "OATableDataModel.h"
#import "OAAppSettings.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OABaseWebViewController ()

@property (nonatomic) OATableDataModel *tableData;

@end

@implementation OABaseWebViewController
{
    BOOL _cachedIsLightTheme;
}

@synthesize tableData;

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseWebViewController" bundle:nil];
    if (self)
    {
        self.tableData = [[OATableDataModel alloc] init];
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
    self.webView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];

    self.webView.hidden = YES;
    [self.webView.scrollView setContentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentNever];
    [self loadWebView];
    _cachedIsLightTheme = [ThemeManager shared].isLightTheme;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (_cachedIsLightTheme != [ThemeManager shared].isLightTheme)
    {
        [self updateAppearance];
        [self loadWebView];
        _cachedIsLightTheme = [ThemeManager shared].isLightTheme;
    }
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

- (OADownloadMode *)getImagesDownloadMode
{
    return OADownloadMode.ANY_NETWORK;
}

- (BOOL)isDownloadImagesOnlyNow
{
    return NO;
}

- (void)setDownloadImagesOnlyNow:(BOOL)onlyNow
{
}

#pragma mark - Web load

- (void)loadHeaderImage:(void(^)(NSString *content))loadWebView
{
    if (loadWebView)
        loadWebView([self getContent]);
}

- (void)loadWebView
{
    [UIView transitionWithView:self.webView
                      duration:.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [[WKContentRuleListStore defaultStore] compileContentRuleListForIdentifier:@"ContentBlockingRules"
                                                                            encodedContentRuleList:kImagesBlockRules
                                                                                 completionHandler:^(WKContentRuleList *contentRuleList, NSError *error) {
                            if (!error)
                            {
                                OADownloadMode *imagesDownloadMode = [self getImagesDownloadMode];
                                WKWebViewConfiguration *configuration = self.webView.configuration;

                                if (![self isDownloadImagesOnlyNow] && ([imagesDownloadMode isDontDownload] || ([imagesDownloadMode isDownloadOnlyViaWifi] && [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN])))
                                    [[configuration userContentController] addContentRuleList:contentRuleList];
                                else
                                    [[configuration userContentController] removeContentRuleList:contentRuleList];

                                [self loadHeaderImage:^(NSString *content) {
                                    [self setDownloadImagesOnlyNow:NO];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.webView loadHTMLString:content baseURL:[self getUrl]];
                                    });
                                }];
                            }
                        }];
    } completion:nil];
}

- (void)webViewDidCommitted:(void(^)(void))onViewCommitted
{
    if (onViewCommitted)
        onViewCommitted();
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    [self webViewDidCommitted:^{
        [UIView transitionWithView:self.webView
                          duration:.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void)
                        {
                            self.webView.hidden = NO;
                        }
                        completion:nil];
    }];
}

@end
