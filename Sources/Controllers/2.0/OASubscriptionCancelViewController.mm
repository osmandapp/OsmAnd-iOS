//
//  OASubscriptionCancelViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASubscriptionCancelViewController.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAChoosePlanHelper.h"
#import "OAChoosePlanViewController.h"
#import "OARootViewController.h"

#include "Localization.h"

#define kMarginH 32.0
#define kMarginDescH 54.0
#define kMarginV 20.0
#define kMarginDescV 12.0

@interface OASubscriptionCancelViewController ()
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UILabel *subscriptionDescriptionView;
@property (weak, nonatomic) IBOutlet UIButton *subscribeButton;

@end

@implementation OASubscriptionCancelViewController

- (instancetype) init
{
    self = [[OASubscriptionCancelViewController alloc] initWithNibName:@"OASubscriptionCancelViewController" bundle:nil];
    if (self)
        self.view.frame = [UIScreen mainScreen].applicationFrame;
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [[OASubscriptionCancelViewController alloc] initWithNibName:@"OASubscriptionCancelViewController" bundle:nil];
    if (self)
        self.view.frame = [UIScreen mainScreen].applicationFrame;

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL firstTimeShown = settings.liveUpdatesPurchaseCancelledFirstDlgShown;
    BOOL secondTimeShown = settings.liveUpdatesPurchaseCancelledSecondDlgShown;
    if (!firstTimeShown)
        settings.liveUpdatesPurchaseCancelledFirstDlgShown = YES;
    else if (!secondTimeShown)
        settings.liveUpdatesPurchaseCancelledSecondDlgShown = YES;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.titleView.textColor = UIColorFromRGB(color_dialog_title_color_light);
    self.descriptionView.textColor = UIColorFromRGB(color_dialog_text_description_color);
    self.subscriptionDescriptionView.textColor = UIColorFromRGB(color_card_description_text_color_light);
    
    self.subscribeButton.layer.cornerRadius = 5.0;
    [self.subscribeButton setTitle:OALocalizedString(@"osm_live_plan_pricing") forState:UIControlStateNormal];
}

- (void) applyLocalization
{
    NSArray<OAFeature *> *osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                                              [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                                              [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                                              [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                                              [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                                              [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps],
                                              [[OAFeature alloc] initWithFeature:EOAFeatureUnlockAllFeatures]];
    
    self.titleView.text = OALocalizedString(@"osmand_live_subscription_canceled");
    NSMutableString *descr = [NSMutableString stringWithString:OALocalizedString(@"osmand_live_cancel_descr")];
    for (OAFeature *feature in osmLiveFeatures)
    {
        [descr appendString:@"\n— "];
        [descr appendString:[feature toHumanString]];
    }
    self.descriptionView.text = descr;
    self.subscriptionDescriptionView.text =  OALocalizedString(@"osm_live_payment_desc");
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat sideMargin = [OAUtilities getLeftMargin];
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;
    if (@available(iOS 11.0, *))
    {
        w -= sideMargin * 2.0;
        h -=  [OAUtilities getBottomMargin];
        self.scrollView.contentInset = UIEdgeInsetsMake([OAUtilities getTopMargin] + 0.0, sideMargin, 0, sideMargin);
        
    }
    
    CGFloat iw = self.imageView.bounds.size.width;
    CGFloat ih = self.imageView.bounds.size.height;
    self.imageView.frame = CGRectMake(w / 2.0 - iw / 2.0, 50.0, iw, ih);

    CGFloat tw = w - kMarginH * 2.0;
    CGFloat th = [OAUtilities calculateTextBounds:self.titleView.text width:tw font:self.titleView.font].height;
    self.titleView.frame = CGRectMake(kMarginH, CGRectGetMaxY(self.imageView.frame) + kMarginV, tw, th);
    
    CGFloat dw = w - kMarginH * 2.0;
    CGFloat dh = [OAUtilities calculateTextBounds:self.descriptionView.text width:dw font:self.descriptionView.font].height;
    self.descriptionView.frame = CGRectMake(kMarginH, CGRectGetMaxY(self.titleView.frame) + kMarginV * 2.0, dw, dh);

    CGRect cbf = self.closeButton.frame;
    cbf.origin.x = 8.0 + sideMargin;
    cbf.origin.y = [OAUtilities getStatusBarHeight];
    self.closeButton.frame = cbf;

    CGRect bf = self.subscribeButton.frame;
    bf.origin.x = kMarginV + sideMargin;
    bf.origin.y = h - kMarginV - bf.size.height;
    bf.size.width = w - kMarginV * 2.0;
    self.subscribeButton.frame = bf;
    
    CGFloat dbw = w - kMarginDescH * 2.0;
    CGFloat dbh = [OAUtilities calculateTextBounds:self.subscriptionDescriptionView.text width:dbw font:self.subscriptionDescriptionView.font].height;
    self.subscriptionDescriptionView.frame = CGRectMake(kMarginDescH + sideMargin, CGRectGetMinY(self.subscribeButton.frame) - kMarginDescV - dbh, dbw, dbh);

    self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, CGRectGetMinY(self.subscriptionDescriptionView.frame) - kMarginV);
    self.scrollView.contentSize = CGSizeMake(w, CGRectGetMaxY(self.descriptionView.frame));
}

- (IBAction) closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) subscribeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [OAChoosePlanHelper showChoosePlanScreenWithProduct:nil navController:[OARootViewController instance].navigationController];
}

+ (BOOL) shouldShowDialog
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSTimeInterval cancelledTime = settings.liveUpdatesPurchaseCancelledTime;
    BOOL firstTimeShown = settings.liveUpdatesPurchaseCancelledFirstDlgShown;
    BOOL secondTimeShown = settings.liveUpdatesPurchaseCancelledSecondDlgShown;
    return cancelledTime > 0 && (!firstTimeShown || ([[[NSDate alloc] init] timeIntervalSince1970] - cancelledTime > kSubscriptionHoldingTimeMsec && !secondTimeShown));
}

+ (void) showInstance:(UINavigationController *)navigationController
{
    OASubscriptionCancelViewController *cancelSubscr = [[OASubscriptionCancelViewController alloc] init];
    cancelSubscr.view.backgroundColor = UIColorFromARGB(color_dialog_transparent_bg_argb_light);
    cancelSubscr.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [navigationController presentViewController:cancelSubscr animated:YES completion:nil];
}

@end
