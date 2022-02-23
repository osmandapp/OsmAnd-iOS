//
//  OAMapillaryImageViewController.m
//  OsmAnd
//
//  Created by Paul on 21/05/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapillaryImageViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAAppSettings.h"
#import "OALog.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OATargetPointView.h"
#import "OAMapillaryImage.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import <WebKit/WebKit.h>

#include <OsmAndCore.h>
#include "Localization.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@interface OAMapillaryImageViewController () <WKScriptMessageHandler, WKNavigationDelegate>

@end

@implementation OAMapillaryImageViewController
{
    OsmAndAppInstance _app;
    
    OAMapillaryImage *_image;
    
    WKWebView *_webView;
    
    OAMapRendererView *_mapView;
    
    CGFloat _cachedYViewPort;
    
    BOOL _shouldHideLayer;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"mapillary");
    self.noConnectionLabel.text = OALocalizedString(@"no_inet_connection");
    self.noConnectionDescr.text = OALocalizedString(@"mapil_no_inet_descr");
    [self.retryButton setTitle:OALocalizedString(@"shared_string_retry") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _app = [OsmAndApp instance];
    _mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    _cachedYViewPort = _mapView.viewportYScale;
    [self applyLocalization];
    [self applySafeAreaMargins];
    [self adjustNavBarWidth];
    [self initWebView];
    [self layoutNoInternetView];
    [self adjustTitlePosition];
    [self addShadows];
}

- (void)dealloc
{
    if (_webView.isLoading)
        [_webView stopLoading];
    _webView.navigationDelegate = nil;
}

- (void) adjustNavBarWidth
{
    CGRect frame = _navBarView.frame;
    frame.size.width = [self isLandscape] ? (DeviceScreenWidth / 2 + OAUtilities.getLeftMargin) : DeviceScreenWidth;
    _navBarView.frame = frame;
}

- (void) addShadows
{
    _webView.layer.shadowOffset = CGSizeMake(0, 3);
    _webView.layer.shadowOpacity = 0.2;
    _webView.layer.shadowRadius = 3.0;
    
    _noInternetView.layer.shadowOffset = CGSizeMake(0, 3);
    _noInternetView.layer.shadowOpacity = 0.2;
    _noInternetView.layer.shadowRadius = 3.0;
    
}

- (void) adjustTitlePosition
{
    CGRect titleFrame = _titleView.frame;
    if ([self isLandscape])
        titleFrame.size.width = DeviceScreenWidth / 2 - 45.0 * 2 + [OAUtilities getLeftMargin];
    else
        titleFrame.size.width = DeviceScreenWidth - 45.0 * 2;
    
    _titleView.frame = titleFrame;
}

- (CGRect)getWebViewFrame:(BOOL)isLandscape
{
    CGFloat navBarHeight = _navBarView.frame.size.height;
    CGFloat height = isLandscape ? DeviceScreenHeight - navBarHeight : DeviceScreenHeight / 2;
    CGFloat width = isLandscape ? DeviceScreenWidth / 2 + [OAUtilities getLeftMargin] : DeviceScreenWidth;
    return CGRectMake(0., navBarHeight, width, height);
}

- (void) initWebView
{
    CGRect frame = [self getWebViewFrame:[self isLandscape]];
    
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"iosMessageHandler"];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = contentController;
    
    _webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
    _webView.navigationDelegate = self;
    
    [self.view addSubview:_webView];
}

- (void) applySafeAreaMargins
{
    CGRect frame = _navBarView.frame;
    frame.size.height = defaultNavBarHeight + [OAUtilities getStatusBarHeight];
    
    CGRect webViewFrame = _webView.frame;
    webViewFrame.origin.y = frame.size.height;
    
    _navBarView.frame = frame;
    _webView.frame = webViewFrame;
    _noInternetView.frame = webViewFrame;
}

- (void) updateViewOnRotation:(BOOL)toLandscape
{
    CGRect navBarFrame = _navBarView.frame;
    CGRect webViewFrame = _webView.frame;
    if (toLandscape)
    {
        CGFloat leftMargin = [OAUtilities getLeftMargin];
        navBarFrame.size.width = DeviceScreenWidth / 2 + leftMargin;
        webViewFrame.size.width = DeviceScreenWidth / 2 + leftMargin;
        webViewFrame.size.height = DeviceScreenHeight - navBarFrame.size.height;
    }
    else
    {
        navBarFrame.size.width = DeviceScreenWidth;
        webViewFrame.size.width = DeviceScreenWidth;
        webViewFrame.size.height = DeviceScreenHeight / 2;
    }
    _navBarView.frame = navBarFrame;
    _webView.frame = webViewFrame;
}

- (void) layoutNoInternetView
{
    _noInternetView.frame = _webView.frame;
    
    CGFloat viewWidth = _noInternetView.frame.size.width;
    CGFloat leftMargin = [OAUtilities getLeftMargin];
    CGFloat textMaxWidth = viewWidth - (16 * 2) - leftMargin;
    
    CGRect imageFrame = _noConnectionImageView.frame;
    CGFloat centerX = (viewWidth / 2) + leftMargin;
    imageFrame.origin.x = centerX - (imageFrame.size.width / 2);
    _noConnectionImageView.frame = imageFrame;
    
    CGRect titleFrame = _noConnectionLabel.frame;
    CGRect descrFrame = _noConnectionDescr.frame;
    
    CGSize titleSize = [OAUtilities calculateTextBounds:_noConnectionLabel.text width:textMaxWidth font:[UIFont boldSystemFontOfSize:17.0]];
    CGSize descrSize = [OAUtilities calculateTextBounds:_noConnectionDescr.text width:textMaxWidth - 32.0 font:[UIFont systemFontOfSize:15.0]];
    
    titleFrame.size.width = titleSize.width;
    titleFrame.origin.x = centerX - (titleFrame.size.width / 2);
    _noConnectionLabel.frame = titleFrame;
    
    descrFrame.size.width = descrSize.width;
    descrFrame.size.height = descrSize.height;
    descrFrame.origin.x = centerX - (descrFrame.size.width / 2);
    _noConnectionDescr.frame = descrFrame;
    
    CGRect buttonFrame = _retryButton.frame;
    buttonFrame.origin.x = centerX - (buttonFrame.size.width / 2);
    _retryButton.frame = buttonFrame;
    
    _retryButton.layer.cornerRadius = 9.0;
}

- (BOOL) isLandscape
{
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    return orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight;
}

- (void)adjustMapViewPort
{
    if ([self isLandscape])
    {
        _mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
        _mapView.viewportYScale = VIEWPORT_NON_SHIFTED_SCALE;
    }
    else
    {
        _mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
        _mapView.viewportYScale = VIEWPORT_SHIFTED_SCALE;
    }
}

- (void) restoreMapViewPort
{
    if (_mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        _mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (_mapView.viewportYScale != _cachedYViewPort)
        _mapView.viewportYScale = _cachedYViewPort;
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (!self.view.hidden)
    {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            BOOL toLandscape = [self isLandscape];
            [self applySafeAreaMargins];
            [self updateViewOnRotation:toLandscape];
            [self layoutNoInternetView];
            [self adjustTitlePosition];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self adjustMapViewPort];
        }];
    }
}

- (void) hideMapillaryView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.view.hidden)
        {
            _image = nil;
            if (_webView.isLoading)
                [_webView stopLoading];
            [_webView loadHTMLString:@"" baseURL:nil];
            [self.view setHidden:YES];
            [self restoreMapViewPort];
            if (_shouldHideLayer)
            {
                _shouldHideLayer = NO;
                [_app.data setMapillary:NO];
            }
            if (self.parentViewController)
                [self.parentViewController setNeedsStatusBarAppearanceUpdate];
            
            [_app.mapillaryImageChangedObservable notifyEventWithKey:nil];
        }
    });
}

- (IBAction)closePressed:(id)sender {
    [self hideMapillaryView];
}

- (IBAction)retryPressed:(id)sender {
    [_webView setHidden:NO];
    [_noInternetView setHidden:YES];
    [self showUpdatedImage];
}

- (void) showImage:(OAMapillaryImage *)image
{
    _image = image;
    BOOL isMapillaryVisible = _app.data.mapillary;
    _shouldHideLayer = _shouldHideLayer || !isMapillaryVisible;
    if (!isMapillaryVisible)
        [_app.data setMapillary:YES];
    
    [self showUpdatedImage];
    _cachedYViewPort = _mapView.viewportYScale;
    [self adjustMapViewPort];
}

- (void) showUpdatedImage
{
    if (_webView.isLoading)
        [_webView stopLoading];
    
    if (_image)
    {
        NSString *urlStr = [MAPILLARY_VIEWER_URL_TEMPLATE stringByAppendingString:_image.imageId];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:urlRequest];
    }
    if (self.view.isHidden)
        [self.view setHidden:NO];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"iosMessageHandler"])
    {
        NSData *jsonData = [message.body dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if (!error)
        {
            OAMapillaryImage *img = [[OAMapillaryImage alloc] initWithDictionary:jsonDict];
            [_app.mapillaryImageChangedObservable notifyEventWithKey:img];
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (error.code == NSURLErrorNotConnectedToInternet)
    {
        [_webView setHidden:YES];
        [_noInternetView setHidden:NO];
    }
}

@end
