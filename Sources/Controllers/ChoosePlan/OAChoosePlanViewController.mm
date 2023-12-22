//
//  OAChoosePlanViewController.mm
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanViewController.h"
#import "OAChoosePlanHelper.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "OAFeatureCardView.h"
#import "OASubscriptionCardView.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAnalyticsHelper.h"
#import "OADonationSettingsViewController.h"
#import "OARootViewController.h"
#import "OAFeatureCardRow.h"
#import "OALinks.h"
#import <SafariServices/SafariServices.h>

#define kMargin 16.
#define kSeparatorHeight .5
#define kNavigationBarHeight 56.

@interface OAChoosePlanViewController () <UIScrollViewDelegate, OAFeatureCardViewDelegate, OAFeatureCardRowDelegate, OAChoosePlanDelegate, SFSafariViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewNavigationBar;
@property (weak, nonatomic) IBOutlet UILabel *labelNavigationTitle;
@property (weak, nonatomic) IBOutlet UIButton *buttonNavigationBack;
@property (weak, nonatomic) IBOutlet UIButton *buttonNavigationRestore;
@property (weak, nonatomic) IBOutlet UIView *viewNavigationSeparator;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *scrollViewContainerView;

@property (weak, nonatomic) IBOutlet UIButton *buttonLater;
@property (weak, nonatomic) IBOutlet UIButton *buttonRestore;

@end

@implementation OAChoosePlanViewController
{
    OAIAPHelper *_iapHelper;

    OAProduct *_product;
    OAFeature *_selectedFeature;
    OAChoosePlanViewControllerType _type;

    BOOL _isHeaderBlurred;
    BOOL _buttonPressCanceled;

    UILabel *_subscriptionManagement;
    OAFeatureCardRow *_buttonTermsOfUse;
    OAFeatureCardRow *_buttonPrivacyPolicy;
    UIView *_viewIncludesSeparator;
    UILabel *_labelIncludes;
    UILabel *_labelNotIncluded;
    UIView *_lastIncludedView;
    UIView *_backgroundAboveScrollViewContainer;
    NSArray<OAFeatureCardRow *> *_includedRows;
    NSArray<OAFeatureCardRow *> *_notIncludedRows;
}

- (instancetype) initWithFeature:(OAFeature *)feature;
{
    self = [super init];
    if (self)
    {
        _selectedFeature = feature;
        _type = EOAChoosePlan;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithProduct:(OAProduct *)product type:(OAChoosePlanViewControllerType)type
{
    self = [super init];
    if (self)
    {
        _product = product;
        _selectedFeature = _product.feature;
        _type = type;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:!nibNameOrNil ? @"OAChoosePlanViewController" : nibNameOrNil bundle:nil];
}

- (void) commonInit
{
    _iapHelper = [OAIAPHelper sharedInstance];
    if (!_product)
        _product = [_selectedFeature isAvailableInMapsPlus] ? _iapHelper.mapsAnnually : _iapHelper.proMonthly;
}

- (void) applyLocalization
{
    if (_type == EOAChoosePlan)
        [self.buttonLater setTitle:OALocalizedString(@"first_time_continue") forState:UIControlStateNormal];
    [self.buttonRestore setTitle:OALocalizedString(@"restore_purchase") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.scrollView.delegate = self;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    self.labelNavigationTitle.text = _type == EOAChoosePlan ? [_selectedFeature getListTitle] : _product.localizedTitle;
    self.labelNavigationTitle.hidden = YES;
    self.viewNavigationSeparator.hidden = YES;

    [self setupButton:self.buttonRestore];

    if (_type == EOAChoosePlan)
        [self setupButton:self.buttonLater];
    else
        [self.buttonLater removeFromSuperview];

    if (_type == EOAChoosePlan)
    {
        OAFeatureCardView *featureCardView = [[OAFeatureCardView alloc] initWithFeature:_selectedFeature];
        featureCardView.delegate = self;
        [self.scrollViewContainerView addSubview:featureCardView];
    }
    else if (_type == EOAChooseSubscription)
    {
        OASubscriptionCardView *subscriptionCardView = [[OASubscriptionCardView alloc] initWithSubscription:_product];
        subscriptionCardView.delegate = self;
        [self.scrollViewContainerView addSubview:subscriptionCardView];

        _subscriptionManagement = [[UILabel alloc] init];
        _subscriptionManagement.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _subscriptionManagement.adjustsFontForContentSizeCategory = YES;
        _subscriptionManagement.textColor = UIColor.textColorPrimary;
        _subscriptionManagement.numberOfLines = 0;

        NSMutableAttributedString *attributedSubscriptionManagement =
                [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_subscription_management_aid")];
        NSMutableParagraphStyle *subscriptionManagementParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        subscriptionManagementParagraphStyle.minimumLineHeight = 21.;
        [attributedSubscriptionManagement addAttribute:NSParagraphStyleAttributeName
                                                 value:subscriptionManagementParagraphStyle
                                                 range:NSMakeRange(0, attributedSubscriptionManagement.length)];
        [attributedSubscriptionManagement addAttribute:NSFontAttributeName
                                                 value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                                 range:NSMakeRange(0, attributedSubscriptionManagement.length)];
        _subscriptionManagement.attributedText = attributedSubscriptionManagement;

        [self.scrollView insertSubview:_subscriptionManagement aboveSubview:self.buttonRestore];

        _buttonTermsOfUse = [self addSimpleRow:OALocalizedString(@"terms_of_use")
                                   showDivider:YES
                                          icon:@"ic_custom_online"
                                  aboveSubview:self.buttonRestore];
        _buttonPrivacyPolicy = [self addSimpleRow:OALocalizedString(@"privacy_policy")
                                      showDivider:NO
                                             icon:@"ic_custom_online"
                                     aboveSubview:self.buttonRestore];

        _viewIncludesSeparator = [[UIView alloc] init];
        _viewIncludesSeparator.backgroundColor = UIColor.separatorColor;
        [self.scrollView insertSubview:_viewIncludesSeparator belowSubview:self.buttonRestore];

        _labelIncludes = [[UILabel alloc] init];
        _labelIncludes.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _labelIncludes.adjustsFontForContentSizeCategory = YES;
        _labelIncludes.textColor = UIColor.textColorPrimary;
        _labelIncludes.numberOfLines = 0;
        _labelIncludes.text = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"),
                OALocalizedString(@"shared_string_includes"), @""];
        [self.scrollView insertSubview:_labelIncludes belowSubview:_viewIncludesSeparator];

        NSMutableArray<OAFeatureCardRow *> *includedRows = [NSMutableArray array];
        UIView *prevView = _labelIncludes;
        BOOL isMaps = [OAIAPHelper isFullVersion:_product] || ([_product isKindOfClass:OASubscription.class] && [OAIAPHelper isMapsSubscription:(OASubscription *) _product]);
        for (OAFeature *feature in isMaps ? OAFeature.MAPS_PLUS_FEATURES : OAFeature.OSMAND_PRO_FEATURES)
        {
            if (feature != OAFeature.COMBINED_WIKI)
            {
                OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowInclude];
                [row updateIncludeInfo:feature];
                [self.scrollView addSubview:row];
                prevView = row;
                [includedRows addObject:row];
            }
        }
        _includedRows = includedRows;

        if (isMaps)
        {
            _labelNotIncluded = [[UILabel alloc] init];
            _labelNotIncluded.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            _labelNotIncluded.adjustsFontForContentSizeCategory = YES;
            _labelNotIncluded.textColor = UIColor.textColorPrimary;
            _labelNotIncluded.numberOfLines = 0;
            _labelNotIncluded.text = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"),
                                                                OALocalizedString(@"shared_string_not_included"), @""];
            [self.scrollView insertSubview:_labelNotIncluded belowSubview:prevView];

            NSMutableArray<OAFeatureCardRow *> *notIncludedRows = [NSMutableArray array];
            prevView = _labelNotIncluded;
            for (OAFeature *feature in OAFeature.OSMAND_PRO_FEATURES)
            {
                if (feature != OAFeature.COMBINED_WIKI && ![feature isAvailableInMapsPlus])
                {
                    OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowInclude];
                    [row updateIncludeInfo:feature];
                    [self.scrollView addSubview:row];
                    prevView = row;
                    [notIncludedRows addObject:row];
                }
            }
            _notIncludedRows = notIncludedRows;
        }
        _lastIncludedView = prevView;
    }

    _backgroundAboveScrollViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0., -self.scrollView.contentInset.top, DeviceScreenWidth, self.scrollView.contentInset.top)];
    _backgroundAboveScrollViewContainer.backgroundColor = UIColor.groupBgColor;
    [self.scrollView insertSubview:_backgroundAboveScrollViewContainer aboveSubview:self.scrollViewContainerView];

    NSInteger index1 = [self.scrollView.subviews indexOfObject:_buttonTermsOfUse];
    _buttonTermsOfUse.tag = index1;
    _buttonTermsOfUse.labelTitle.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    NSInteger index2 = [self.scrollView.subviews indexOfObject:_buttonPrivacyPolicy];
    _buttonPrivacyPolicy.tag = index2;
    _buttonPrivacyPolicy.labelTitle.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];

    [self.buttonNavigationBack setTintColor:UIColor.iconColorActive];
    [self.buttonNavigationBack setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    [self.buttonNavigationRestore setTintColor:UIColor.iconColorActive];
    UIImage *image = [UIImage templateImageNamed:_type == EOAChoosePlan ? @"ic_custom_reset" : @"ic_navbar_help"];
    [self.buttonNavigationRestore setImage:image
                                  forState:UIControlStateNormal];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];

    [[OARootViewController instance] requestProductsWithProgress:YES reload:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return _type == EOAChoosePlan ? UIStatusBarStyleDefault : [ThemeManager shared].isLightTheme ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGRect backgroundFrame = _backgroundAboveScrollViewContainer.frame;
        backgroundFrame.size.width = DeviceScreenWidth;
        _backgroundAboveScrollViewContainer.frame = backgroundFrame;
    } completion:nil];
}

- (void) viewWillLayoutSubviews
{
    if ([self.scrollView isDirectionRTL])
    {
        self.scrollView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.viewNavigationBar.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.labelNavigationTitle.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.buttonNavigationRestore.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    
    CGFloat navigationBarHeight;
    CGFloat extraNavigationBarHeight = 0.;
    if (_type == EOAChooseSubscription)
        extraNavigationBarHeight = [OAUtilities getTopMargin];

    navigationBarHeight = kNavigationBarHeight + extraNavigationBarHeight;

    self.viewNavigationBar.frame = CGRectMake(0., 0., self.view.frame.size.width, navigationBarHeight);
    [self.view bringSubviewToFront:self.viewNavigationBar];

    self.scrollView.contentInset = UIEdgeInsetsMake(
            navigationBarHeight - extraNavigationBarHeight,
            0.,
            [OAUtilities getBottomMargin] + 52.,
            0.
    );
    self.scrollView.frame = CGRectMake(0., 0., self.view.frame.size.width, self.view.frame.size.height);
    CGRect backgroundFrame = _backgroundAboveScrollViewContainer.frame;
    backgroundFrame.origin.y = -self.scrollView.contentInset.top;
    backgroundFrame.size.height = self.scrollView.contentInset.top;
    _backgroundAboveScrollViewContainer.frame = backgroundFrame;

    CGRect frame = self.buttonNavigationBack.frame;
    frame.origin.x = [OAUtilities getLeftMargin] + 10.;
    frame.origin.y = navigationBarHeight - navigationBarHeight / 2 - self.buttonNavigationBack.frame.size.height / 2;
    if (_type == EOAChooseSubscription)
        frame.origin.y += [OAUtilities getTopMargin] / 2;
    self.buttonNavigationBack.frame = frame;

    frame = self.buttonNavigationRestore.frame;
    frame.origin.x = self.viewNavigationBar.frame.size.width - self.buttonNavigationRestore.frame.size.width - 10. - [OAUtilities getLeftMargin];
    frame.origin.y = navigationBarHeight - navigationBarHeight / 2 - self.buttonNavigationRestore.frame.size.height / 2;
    if (_type == EOAChooseSubscription)
        frame.origin.y += [OAUtilities getTopMargin] / 2;
    self.buttonNavigationRestore.frame = frame;

    CGFloat iconOffset = 10. + 28. + 16.;
    frame = self.labelNavigationTitle.frame;
    frame.origin.x = iconOffset;
    frame.origin.y = navigationBarHeight - navigationBarHeight / 2 - self.labelNavigationTitle.frame.size.height / 2;
    if (_type == EOAChooseSubscription)
        frame.origin.y += [OAUtilities getTopMargin] / 2;
    frame.size.width = self.view.frame.size.width - iconOffset * 2;
    self.labelNavigationTitle.frame = frame;

    self.viewNavigationSeparator.frame = CGRectMake(
            0,
            navigationBarHeight - kSeparatorHeight,
            self.view.frame.size.width,
            kSeparatorHeight
    );

    [self updateScrollViewContainerSize];
}

- (void)updateScrollViewContainerSize
{
    if ([self.scrollView isDirectionRTL])
    {
        _labelIncludes.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        _labelIncludes.textAlignment = NSTextAlignmentRight;
        _labelNotIncluded.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        _labelNotIncluded.textAlignment = NSTextAlignmentRight;
        _subscriptionManagement.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        _subscriptionManagement.textAlignment = NSTextAlignmentRight;
    }
    
    CGFloat y = 0;
    for (UIView *view in self.scrollViewContainerView.subviews)
    {
        if ([view isKindOfClass:[OABaseFeatureCardView class]])
        {
            OABaseFeatureCardView *card = (OABaseFeatureCardView *) view;
            y += [card updateFrame:y width:self.view.frame.size.width];
        }
    }
    self.scrollViewContainerView.frame = CGRectMake(
            0.,
            0.,
            self.view.frame.size.width,
            CGRectGetMaxY(self.scrollViewContainerView.subviews.lastObject.frame)
    );

    if (_type == EOAChooseSubscription)
    {
        CGSize subscriptionManagementSize = [OAUtilities calculateTextBounds:_subscriptionManagement.text
                                                                       width:self.view.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2
                                                                        font:_subscriptionManagement.font];
        _subscriptionManagement.frame = CGRectMake(
                20. + [OAUtilities getLeftMargin],
                self.scrollViewContainerView.frame.size.height + 20.,
                self.view.frame.size.width - 20. * 2 - [OAUtilities getLeftMargin] * 2,
                subscriptionManagementSize.height
        );

        [_buttonTermsOfUse updateFrame:_subscriptionManagement.frame.origin.y + _subscriptionManagement.frame.size.height
                                 width:self.view.frame.size.width];
        [_buttonPrivacyPolicy updateFrame:_buttonTermsOfUse.frame.origin.y + _buttonTermsOfUse.frame.size.height
                                    width:self.view.frame.size.width];
    }

    self.buttonRestore.frame = CGRectMake(
            kMargin + [OAUtilities getLeftMargin],
            _type == EOAChooseSubscription
                    ? _buttonPrivacyPolicy.frame.origin.y + _buttonPrivacyPolicy.frame.size.height + 5.
                    : self.scrollViewContainerView.frame.size.height + 20.,
            self.view.frame.size.width - kMargin * 2 - [OAUtilities getLeftMargin] * 2,
            self.buttonRestore.frame.size.height
    );

    if (_type == EOAChoosePlan)
    {
        self.buttonLater.frame = CGRectMake(
                kMargin + [OAUtilities getLeftMargin],
                CGRectGetMaxY(self.buttonRestore.frame) + kMargin,
                self.view.frame.size.width - kMargin * 2 - [OAUtilities getLeftMargin] * 2,
                self.buttonLater.frame.size.height
        );
    }
    else if (_type == EOAChooseSubscription)
    {
        _viewIncludesSeparator.frame = CGRectMake(
                0.,
                self.buttonRestore.frame.origin.y + self.buttonRestore.frame.size.height + 20.,
                self.view.frame.size.width,
                kSeparatorHeight
        );

        CGSize includesSize = [OAUtilities calculateTextBounds:_labelIncludes.text
                                                         width:self.view.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2
                                                          font:_labelIncludes.font];
        CGFloat includesVerticalOffset = includesSize.height > kMinRowHeight ? 9. : (kMinRowHeight - includesSize.height) / 2;
        _labelIncludes.frame = CGRectMake(
                20. + [OAUtilities getLeftMargin],
                _viewIncludesSeparator.frame.origin.y + kSeparatorHeight,
                self.view.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2,
                includesSize.height + includesVerticalOffset * 2
        );

        y = _labelIncludes.frame.origin.y + _labelIncludes.frame.size.height;
        for (OAFeatureCardRow *cardRow in _includedRows)
        {
            y += [cardRow updateFrame:y width:self.view.frame.size.width] + 36.;
        }

        BOOL isMaps = [OAIAPHelper isFullVersion:_product] || ([_product isKindOfClass:OASubscription.class] && [OAIAPHelper isMapsSubscription:(OASubscription *) _product]);
        if (isMaps)
        {
            CGSize notIncludedSize = [OAUtilities calculateTextBounds:_labelNotIncluded.text
                                                                width:self.view.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2
                                                                 font:_labelNotIncluded.font];
            CGFloat notIncludedVerticalOffset = notIncludedSize.height > kMinRowHeight ? 9. : (kMinRowHeight - notIncludedSize.height) / 2;
            _labelNotIncluded.frame = CGRectMake(
                    20. + [OAUtilities getLeftMargin],
                    _includedRows.lastObject.frame.origin.y + _includedRows.lastObject.frame.size.height + 32.,
                    self.view.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2,
                    notIncludedSize.height + notIncludedVerticalOffset * 2
            );

            y = _labelNotIncluded.frame.origin.y + _labelNotIncluded.frame.size.height;
            for (OAFeatureCardRow *cardRow in _notIncludedRows)
            {
                y += [cardRow updateFrame:y width:self.view.frame.size.width] + 36.;
            }
        }
    }

    self.scrollView.contentSize = CGSizeMake(
            self.view.frame.size.width,
            CGRectGetMaxY(_type == EOAChoosePlan ? self.buttonLater.frame : _lastIncludedView.frame) + kMargin
    );
}

- (void)setupButton:(UIButton *)button
{
    if ([self.scrollView isDirectionRTL])
    {
        self.buttonLater.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.buttonRestore.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    
    [button setTitleColor:UIColor.buttonTextColorSecondary forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (OAFeatureCardRow *)addSimpleRow:(NSString *)title
                       showDivider:(BOOL)showDivider
                              icon:(NSString *)icon
                      aboveSubview:(UIView *)aboveSubview
{
    OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowSimple];
    [row updateSimpleRowInfo:title
                 showDivider:showDivider
           dividerLeftMargin:20.
                        icon:icon];
    row.delegate = self;
    [self.scrollView insertSubview:row aboveSubview:aboveSubview];
    row.backgroundColor = self.scrollView.backgroundColor;
    return row;
}

- (void)openSafariWithURL:(NSString *)url
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (IBAction) helpButtonClicked:(id)sender
{
    if (_type == EOAChoosePlan)
        [[OARootViewController instance] requestProductsWithProgress:YES reload:YES restorePurchases:YES];
    else if (_type == EOAChooseSubscription)
        [self openSafariWithURL:kDocsPurchasesIOS];
}

- (IBAction) onButtonRestorePressed:(id)sender
{
    [[OARootViewController instance] requestProductsWithProgress:YES reload:YES restorePurchases:YES];
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewController];
        if (self.delegate)
            [self.delegate onProductNotification];
    });
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [OAUtilities showToast:[NSString stringWithFormat:OALocalizedString(@"prch_failed"), _product.localizedTitle]
                       details:nil
                      duration:4
                        inView:self.view];
    });
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_type == EOAChoosePlan)
        {
            OAFeatureCardView *featureCardView = self.scrollViewContainerView.subviews.lastObject;
            [featureCardView updateInfo:_selectedFeature replaceFeatureRows:YES];
        }
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    });
}

- (void) productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewController];
        if (self.delegate)
            [self.delegate onProductNotification];
    });
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.contentOffset.y;
    if (_type == EOAChooseSubscription)
        y += [OAUtilities getTopMargin];

    CGRect backgroundFrame = _backgroundAboveScrollViewContainer.frame;
    backgroundFrame.origin.y = y < 0. ? y : -y;
    backgroundFrame.size.height = y < 0. ? ABS(y) : 0.;
    _backgroundAboveScrollViewContainer.frame = backgroundFrame;

    if (!_isHeaderBlurred && y > 0.)
    {
        [self.viewNavigationBar addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:0. padding:0.];
        self.labelNavigationTitle.hidden = NO;
        self.viewNavigationSeparator.hidden = NO;
        _isHeaderBlurred = YES;
    }
    else if (_isHeaderBlurred && y <= 0.)
    {
        [self.viewNavigationBar removeBlurEffect];
        self.viewNavigationBar.backgroundColor = UIColor.groupBgColor;
        self.labelNavigationTitle.hidden = YES;
        self.viewNavigationSeparator.hidden = YES;
        _isHeaderBlurred = NO;
    }
}

#pragma mark - OAFeatureCardRowDelegate

- (void)onFeatureSelected:(NSInteger)tag state:(UIGestureRecognizerState)state
{
    if (self.scrollView.subviews.count > tag)
    {
        if (state == UIGestureRecognizerStateChanged)
        {
            _buttonPressCanceled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                OAFeatureCardRow *row = self.scrollView.subviews[tag];
                row.backgroundColor = self.scrollView.backgroundColor;
            }                completion:nil];
        }
        else if (state == UIGestureRecognizerStateEnded)
        {
            if (_buttonPressCanceled)
            {
                _buttonPressCanceled = NO;
                return;
            }

            [UIView animateWithDuration:0.2 animations:^{
                OAFeatureCardRow *row = self.scrollView.subviews[tag];
                row.backgroundColor = UIColor.buttonBgColorTertiary;
            }                completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    OAFeatureCardRow *row = self.scrollView.subviews[tag];
                    row.backgroundColor = self.scrollView.backgroundColor;

                    if (tag == _buttonTermsOfUse.tag)
                        [self openSafariWithURL:kOsmAndTermsOfUse];
                    else if (tag == _buttonPrivacyPolicy.tag)
                        [self openSafariWithURL:kOsmAndPrivacyPolicy];
                }];
            }];
        }
        else if (state == UIGestureRecognizerStateBegan)
        {
            [UIView animateWithDuration:0.2 animations:^{
                OAFeatureCardRow *row = self.scrollView.subviews[tag];
                row.backgroundColor = UIColor.buttonBgColorTertiary;
            }                completion:nil];
        }
    }
}

#pragma mark - OAFeatureCardViewDelegate

- (void)onFeatureSelected:(OAFeature *)feature
{
    _selectedFeature = feature;
    self.labelNavigationTitle.text = [_selectedFeature getListTitle];
    [self updateScrollViewContainerSize];
}

- (void)onPlanTypeSelected:(OAProduct *)subscription
{
    if (_type == EOAChoosePlan)
    {
        OAChoosePlanViewController *chooseSubscriptionViewController =
                [[OAChoosePlanViewController alloc] initWithProduct:subscription
                                                               type:EOAChooseSubscription];
        chooseSubscriptionViewController.delegate = self;

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chooseSubscriptionViewController];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        navController.navigationBarHidden = YES;
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if (_type == EOAChooseSubscription)
    {
        [OAAnalyticsHelper logEvent:@"in_app_purchase_redirect_from_choose_plan"];
        [[OARootViewController instance] buyProduct:subscription showProgress:YES];
    }
}

- (void)onLearnMoreButtonSelected
{
    [self.scrollView setContentOffset:CGPointMake(0.,_labelIncludes.frame.origin.y - self.viewNavigationBar.frame.size.height)
                             animated:YES];
}

#pragma mark - OAChoosePlanDelegate

- (void)onProductNotification
{
    [self dismissViewController];
}

@end
