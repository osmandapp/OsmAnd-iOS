//
//  OATargetPointView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATargetPointView.h"
#import "OALocationServices.h"
#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAObservable.h"
#import "OADestinationCell.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAGPXDatabase.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OATransportStopViewController.h"
#import "OAMoreOptionsBottomSheetViewController.h"
#import "OATransportStopRoute.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapLayers.h"
#import "OANativeUtilities.h"
#import "OATransportRouteController.h"
#import "OAFavoriteViewController.h"
#import "OAFavoritesHelper.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAOsmAndFormatter.h"
#import "OAMapDownloadController.h"
#import "OAShareMenuActivity.h"
#import "OAPOI.h"
#import "OAWikiMenuViewController.h"
#import "OAGPXWptViewController.h"
#import "OAButton.h"
#import "OAPluginsHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

static const CGFloat kMargin = 16.0;
static const CGFloat kButtonsViewHeight = 44.0;
static const CGFloat kDefaultMapRulerMarginBottom = 0;

static const CGFloat kButtonsTopMargin = 1.0;
static const CGFloat kButtonsBottomMargin = 10.0;
static const CGFloat kButtonsSideMargin = 6.0;
static const CGFloat kButtonsIconSize = 30.0;
static const CGFloat kButtonsIconTopMargin = 7.0;
static const CGFloat kButtonsLabelTopMargin = 38.0;
static const CGFloat kButtonsLabelSideMargin = 4.0;
static const CGFloat kButtonsLabelHeight = 30.0;
static const CGFloat kTopViewCornerRadius = 10.0;

@interface OATargetPointView() <UIScrollViewDelegate, OAScrollViewDelegate, OAShareMenuDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topOverscrollView;
@property (weak, nonatomic) IBOutlet UIView *bottomOverscrollView;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIView *transportView;
@property (weak, nonatomic) IBOutlet UILabel *nearbyLabel;

@property (weak, nonatomic) IBOutlet OAButton *buttonFavorite;
@property (weak, nonatomic) IBOutlet OAButton *buttonShare;
@property (weak, nonatomic) IBOutlet OAButton *buttonDirection;
@property (weak, nonatomic) IBOutlet OAButton *buttonMore;

@property (weak, nonatomic) IBOutlet UILabel *buttonFavoriteLabel;
@property (weak, nonatomic) IBOutlet UILabel *buttonShareLabel;
@property (weak, nonatomic) IBOutlet UILabel *buttonDirectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *buttonMoreLabel;

@property (weak, nonatomic) IBOutlet UIImageView *buttonFavoriteIcon;
@property (weak, nonatomic) IBOutlet UIImageView *buttonShareIcon;
@property (weak, nonatomic) IBOutlet UIImageView *buttonDirectionIcon;
@property (weak, nonatomic) IBOutlet UIImageView *buttonMoreIcon;

@property (weak, nonatomic) IBOutlet UIButton *buttonShadow;

@property (weak, nonatomic) IBOutlet UIView *controlButtonsView;
@property (weak, nonatomic) IBOutlet UIButton *controlButtonLeft;
@property (weak, nonatomic) IBOutlet UIButton *controlButtonRight;
@property (weak, nonatomic) IBOutlet UIButton *controlButtonDownload;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressBar;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UILabel *downloadProgressLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadCancelButton;

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *buttonsColoredView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;
@property (weak, nonatomic) IBOutlet UIView *backView4;

@property (weak, nonatomic) IBOutlet UIView *backViewRoute;
@property (weak, nonatomic) IBOutlet UIButton *buttonShowInfo;
@property (weak, nonatomic) IBOutlet UIButton *buttonRoute;

@property NSString* addressStr;
@property OAMapRendererView* mapView;
@property UINavigationController* navController;
@property UIView* parentView;

@end

static const NSInteger _buttonsCount = 4;

@implementation OATargetPointView
{
    OAAutoObserverProxy *_locationUpdateObserver;
    OAAutoObserverProxy *_headingUpdateObserver;

    CALayer *_horizontalRouteLine;

    CGFloat _headerY;
    CGFloat _headerHeight;
    CGFloat _fullHeight;
    CGFloat _fullScreenHeight;
    CGFloat _headerOffset;
    CGFloat _fullOffset;
    CGFloat _fullScreenOffset;

    BOOL _hideButtons;
    BOOL _hiding;
    BOOL _toolbarAnimating;
    BOOL _bottomBarAnimating;
    CGPoint _topViewStartSlidingPos;
    
    OATargetPointType _previousTargetType;
    UIImage *_previousTargetIcon;
    
    CGFloat _toolbarHeight;
    
    BOOL _bottomBarVisible;
    CGFloat _bottomBarHeight;
    
    NSArray<OATransportStopRoute *> *_visibleTransportRoutes;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATargetPointView class]])
            self = (OATargetPointView *)v;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATargetPointView class]])
            self = (OATargetPointView *)v;
    }
    
    if (self)
    {
        self.frame = frame;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void) awakeFromNib
{
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.bouncesZoom = NO;
    self.scrollsToTop = NO;
    self.multipleTouchEnabled = NO;
    self.bounces = YES;
    self.alwaysBounceVertical = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    self.delegate = self;
    self.oaDelegate = self;

    [self setupControlButton:self.controlButtonLeft];
    [self setupControlButton:self.controlButtonRight];
    [self setupControlButton:self.controlButtonDownload];

    self.buttonDirection.imageView.clipsToBounds = NO;
    self.buttonDirection.imageView.contentMode = UIViewContentModeCenter;
    
    [self doUpdateUI];

    _buttonFavoriteLabel.text = OALocalizedString(@"ctx_mnu_add_fav");
    _buttonFavorite.accessibilityLabel = OALocalizedString(@"ctx_mnu_add_fav");
    _buttonShareLabel.text = OALocalizedString(@"shared_string_share");
    _buttonShare.accessibilityLabel = OALocalizedString(@"shared_string_share");
    _buttonDirectionLabel.text = OALocalizedString(@"map_marker");
    _buttonDirection.accessibilityLabel = OALocalizedString(@"quick_action_add_marker");
    [_buttonShowInfo setTitle:[OALocalizedString(@"info_button") upperCase] forState:UIControlStateNormal];
    [_buttonRoute setTitle:[OALocalizedString(@"shared_string_navigation") upperCase] forState:UIControlStateNormal];

    _backView4.hidden = YES;
    _buttonMore.hidden = YES;

    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    self.sliderView.hidden = [self isLandscape];
    self.sliderView.layer.cornerRadius = 3.;
    self.buttonShadow.hidden = YES;

    _horizontalRouteLine = [CALayer layer];
    _horizontalRouteLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
    [_backViewRoute.layer addSublayer:_horizontalRouteLine];

    _nearbyLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    _descriptionLabel.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightMedium];
    _buttonShadow.titleLabel.font = [UIFont scaledSystemFontOfSize:18.];
    _buttonRoute.titleLabel.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightSemibold];
    _buttonShowInfo.titleLabel.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightSemibold];
    
    [OAFavoritesHelper getFavoritesCollection]->collectionChangeObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                                {
                                                                    [self onFavoritesCollectionChanged];
                                                                });

    [OAFavoritesHelper getFavoritesCollection]->favoriteLocationChangeObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
                                                                      [self]
                                                                      (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                       const std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation)
                                                                      {
                                                                          [self onFavoriteLocationChanged:favoriteLocation];
                                                                      });
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        _horizontalRouteLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
        [self setupControlButton:self.controlButtonLeft];
        [self setupControlButton:self.controlButtonRight];
        [self setupControlButton:self.controlButtonDownload];
    }
}

- (void) startLocationUpdate
{
    if (_locationUpdateObserver)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(doLocationUpdate)
                                                         andObserve:app.locationServices.updateLocationObserver];
    _headingUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(doLocationUpdate)
                                                        andObserve:app.locationServices.updateHeadingObserver];
}

- (void) stopLocationUpdate
{
    if (_locationUpdateObserver) 
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
    if (_headingUpdateObserver)
    {
        [_headingUpdateObserver detach];
        _headingUpdateObserver = nil;
    }
}

- (void) doLocationUpdate
{
    if ([self.customController hasDismissButton])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{

        // Obtain fresh location and heading
        OsmAndAppInstance app = [OsmAndApp instance];
        CLLocation* newLocation = app.locationServices.lastKnownLocation;
        if (newLocation)
        {
            CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
            CLLocationDirection newDirection =
            (newLocation.speed >= 1 && newLocation.course >= 0.0f)
            ? newLocation.course
            : newHeading;
            
            [self updateDirectionButton:newLocation.coordinate newDirection:newDirection];
        }
    });
}

- (void) setupControlButton:(UIButton *)btn
{
    //btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 8.0, 0, 8.0);
    btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    //btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    btn.layer.cornerRadius = 4.0;
    btn.layer.masksToBounds = YES;
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
    btn.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
}

- (void) updateDirectionButton
{
    if ([self.customController hasDismissButton])
    {
        _buttonDirectionIcon.transform = CGAffineTransformIdentity;
    }
    else
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        CLLocation* newLocation = app.locationServices.lastKnownLocation;
        if (newLocation)
        {
            CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
            CLLocationDirection newDirection =
            (newLocation.speed >= 1 && newLocation.course >= 0.0f)
            ? newLocation.course
            : newHeading;
            
            [self updateDirectionButton:newLocation.coordinate newDirection:newDirection];
        }
    }
}

- (void) updateDirectionButton:(CLLocationCoordinate2D)coordinate newDirection:(CLLocationDirection)newDirection
{
    const auto distance = OsmAnd::Utilities::distance(coordinate.longitude,
                                                      coordinate.latitude,
                                                      _targetPoint.location.longitude, _targetPoint.location.latitude);
    
    NSString *distanceStr = [OAOsmAndFormatter getFormattedDistance:distance];
    
    CGFloat itemDirection = [[OsmAndApp instance].locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:_targetPoint.location.latitude longitude:_targetPoint.location.longitude]];
    CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    
    _buttonDirectionIcon.transform = CGAffineTransformMakeRotation(direction);
    _buttonDirectionLabel.text = distanceStr;
    _buttonDirection.accessibilityValue = distanceStr;
}

- (void) updateToolbarGradientWithAlpha:(CGFloat)alpha
{
    BOOL useGradient = (_activeTargetType != OATargetGPX) && ![self isLandscape];
    [self.customController applyGradient:useGradient alpha:alpha];
}

- (void) updateToolbarFrame:(BOOL)landscape
{
    if (_toolbarAnimating)
        return;
    
    [self updateToolbarGradientWithAlpha:[self getTopToolbarAlpha]];
    
    if (landscape)
    {
        CGRect f = self.customController.navBar.frame;
        self.customController.navBar.frame = CGRectMake(0.0, 0.0, (OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth) + [OAUtilities getLeftMargin], f.size.height);
    }
    else
    {
        CGRect f = self.customController.navBar.frame;
        self.customController.navBar.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, f.size.height);
    }
}

- (void) updateBottomToolbarFrame:(BOOL)landscape
{
    if (_bottomBarAnimating)
        return;
    
    if (landscape)
    {
        CGRect f = self.customController.bottomToolBarView.frame;
        self.customController.bottomToolBarView.frame = CGRectMake(0., self.frame.size.height - f.size.height, (OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth) + [OAUtilities getLeftMargin], f.size.height);
    }
    else
    {
        CGRect f = self.customController.bottomToolBarView.frame;
        self.customController.bottomToolBarView.frame = CGRectMake(0.0, self.frame.size.height - f.size.height, self.frame.size.width, f.size.height);
    }
}

- (void) showTopToolbar:(BOOL)animated
{
    if (!self.customController || !self.customController.hasTopToolbar || !self.customController.navBar.hidden || (self.customController.topToolbarType == ETopToolbarTypeFloating && [self isLandscape]))
        return;

    [self updateToolbarGradientWithAlpha:[self getTopToolbarAlpha]];

    CGRect topToolbarFrame;

    if ([self isLandscape])
    {
        CGRect f = self.customController.navBar.frame;
        self.customController.navBar.frame = CGRectMake(-(OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth), 0.0, (OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth) + [OAUtilities getLeftMargin], f.size.height);
        topToolbarFrame = CGRectMake(0.0, 0.0, (OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth) + [OAUtilities getLeftMargin], f.size.height);
    }
    else
    {
        CGRect f = self.customController.navBar.frame;
        self.customController.navBar.frame = CGRectMake(0.0, -f.size.height, DeviceScreenWidth, f.size.height);
        topToolbarFrame = CGRectMake(0.0, 0.0, DeviceScreenWidth, f.size.height);
    }
    self.customController.navBar.hidden = NO;
    [self.parentView addSubview:self.customController.navBar];
    
    BOOL showTopControls = [self.customController showTopControls];
    _toolbarHeight = showTopControls ? _customController.getNavBarHeight : OAUtilities.getStatusBarHeight;
    
    [self.menuViewDelegate targetUpdateControlsLayout:showTopControls customStatusBarStyle:[OAAppSettings sharedManager].nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDarkContent];
    
    if (self.customController.topToolbarType == ETopToolbarTypeFloating || self.customController.topToolbarType == ETopToolbarTypeMiddleFixed || self.customController.topToolbarType == ETopToolbarTypeFloatingFixedButton)
    {
        self.customController.navBar.alpha = [self getTopToolbarAlpha];
        self.customController.navBar.frame = topToolbarFrame;
        if ((self.customController.topToolbarType == ETopToolbarTypeFloating || self.customController.topToolbarType == ETopToolbarTypeFloatingFixedButton) && self.customController.buttonBack)
        {
            self.customController.buttonBack.alpha = self.customController.topToolbarType == ETopToolbarTypeFloatingFixedButton ? 1.0 : [self getMiddleToolbarAlpha];
            self.customController.buttonBack.hidden = NO;
            [self.parentView insertSubview:self.customController.buttonBack belowSubview:self.customController.navBar];
        }
        if (!showTopControls)
            [self.menuViewDelegate targetResetCustomStatusBarStyle];
    }
    else if (animated)
    {
        _toolbarAnimating = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            
            self.customController.navBar.frame = topToolbarFrame;
        } completion:^(BOOL finished) {
            _toolbarAnimating = NO;
        }];
    }
    else
    {
        self.customController.navBar.frame = topToolbarFrame;
    }
}

- (void) hideTopToolbar:(BOOL)animated
{
    if (!self.customController || !self.customController.hasTopToolbar)
        return;

    BOOL showingTopToolbar = (!self.customController.navBar.hidden);
    CGRect newTopToolbarFrame;
    if (showingTopToolbar)
    {
        newTopToolbarFrame = self.customController.navBar.frame;
        if ([self isLandscape])
            newTopToolbarFrame.origin.x = -newTopToolbarFrame.size.width;
        else
            newTopToolbarFrame.origin.y = -newTopToolbarFrame.size.height;
     
        _toolbarHeight = OAUtilities.getStatusBarHeight;

        [self.menuViewDelegate targetUpdateControlsLayout:NO customStatusBarStyle:UIStatusBarStyleDefault];

        if (animated)
        {
            _toolbarAnimating = YES;
            [UIView animateWithDuration:.3 animations:^{
                
                self.customController.navBar.frame = newTopToolbarFrame;
            } completion:^(BOOL finished) {
                _toolbarAnimating = NO;
                self.customController.navBar.hidden = YES;
            }];
        }
        else
        {
            self.customController.navBar.frame = newTopToolbarFrame;
            self.customController.navBar.hidden = YES;
        }
    }
}

- (void) showBottomToolbar:(BOOL)animated
{
    if (!self.customController || !self.customController.hasBottomToolbar)
        return;
    
    self.customController.bottomToolBarView.hidden = NO;

    CGRect bottomToolbarFrame;

    if ([self isLandscape])
    {
        CGRect f = self.customController.bottomToolBarView.frame;
        bottomToolbarFrame = CGRectMake(0., self.frame.size.height - f.size.height, (OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth) + [OAUtilities getLeftMargin], f.size.height);
    }
    else
    {
        CGRect f = self.customController.bottomToolBarView.frame;
        bottomToolbarFrame = CGRectMake(0.0, self.frame.size.height - f.size.height, self.frame.size.width, f.size.height);
    }
    
    [self.parentView addSubview:self.customController.bottomToolBarView];
    
    _bottomBarVisible = YES;
    _bottomBarHeight = bottomToolbarFrame.size.height;
    
    if (animated)
    {
        _bottomBarAnimating = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            
            self.customController.bottomToolBarView.frame = bottomToolbarFrame;
        } completion:^(BOOL finished) {
            _bottomBarAnimating = NO;
        }];
    }
    else
    {
        self.customController.bottomToolBarView.frame = bottomToolbarFrame;
    }
}

- (void) hideBottomToolbar:(BOOL)animated
{
    if (!self.customController || !self.customController.hasBottomToolbar)
        return;

    BOOL showingBottomToolbar = (!self.customController.bottomToolBarView.hidden);
    CGRect newBottomToolbarFrame;
    if (showingBottomToolbar)
    {
        newBottomToolbarFrame = self.customController.bottomToolBarView.frame;
        if ([self isLandscape])
            newBottomToolbarFrame.origin.x = -newBottomToolbarFrame.size.width;
        else
            newBottomToolbarFrame.origin.y = -newBottomToolbarFrame.size.height;
     
        _bottomBarVisible = NO;
        _bottomBarHeight = 0.;

        if (animated)
        {
            _bottomBarAnimating = YES;
            [UIView animateWithDuration:.3 animations:^{
                
                self.customController.bottomToolBarView.frame = newBottomToolbarFrame;
            } completion:^(BOOL finished) {
                _bottomBarAnimating = NO;
                self.customController.bottomToolBarView.hidden = YES;
            }];
        }
        else
        {
            self.customController.bottomToolBarView.frame = newBottomToolbarFrame;
            self.customController.bottomToolBarView.hidden = YES;
        }
    }
}

- (BOOL) isToolbarVisible
{
    return self.superview && [self getTopToolbarAlpha] == 1.;
}

- (CGFloat) toolbarHeight
{
    return _toolbarHeight;
}

- (void) showFullMenu
{
    if (![self hasInfo])
        return;
    
    [self requestFullMode];
    
    if ([self.customController hasTopToolbar] && ([self.customController shouldShowToolbar] || self.targetPoint.toolbarNeeded))
    {
        [self showTopToolbar:YES];
    }
}

- (void) prepare
{
    [self doInit:NO];
    [self doUpdateUI];
    [self doLayoutSubviews];
}

- (void) prepareNoInit
{
    [self doUpdateUI];
    [self doLayoutSubviews];
}

- (void) prepareForRotation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([self isLandscapeSupported] && [OAUtilities isLandscape:toInterfaceOrientation])
    {
        [self showTopToolbar:NO];
        [self showBottomToolbar:NO];
    }
}

- (void) clearCustomControllerIfNeeded
{
    _toolbarHeight = OAUtilities.getStatusBarHeight;
    
    _bottomBarVisible = NO;
    _bottomBarHeight = 0.;

    if (self.customController)
    {
        [self.customController removeFromParentViewController];
        if (self.customController.navBar)
            [self.customController.navBar removeFromSuperview];
        if (self.customController.bottomToolBarView)
            [self.customController.bottomToolBarView removeFromSuperview];
        if (self.customController.buttonBack)
            [self.customController.buttonBack removeFromSuperview];
        if (self.customController.additionalAccessoryView)
            [self.customController.additionalAccessoryView removeFromSuperview];
        [self.customController removeMapFrameLayer:self];
        [self.customController.contentView removeFromSuperview];
        self.customController.delegate = nil;
        _customController = nil;
        [self.navController setNeedsStatusBarAppearanceUpdate];
    }
}

- (void) updateUIOnInit
{
}

- (void) doInit:(BOOL)showFull
{
    _showFull = showFull;
    _showFullScreen = NO;
    [self clearCustomControllerIfNeeded];
    [self updateUIOnInit];
}

- (void) doInit:(BOOL)showFull showFullScreen:(BOOL)showFullScreen
{
    _showFull = showFull;
    _showFullScreen = showFullScreen;
    [self clearCustomControllerIfNeeded];
    [self updateUIOnInit];
}

- (BOOL) closeDenied
{
    return (_hideButtons && _showFull) || [self.customController denyClose];
}

- (void) doUpdateUI
{
    _hideButtons = [self.customController hideButtons];
  
    self.buttonsView.hidden = _hideButtons;
    
    if (self.customController.contentView)
        [self insertSubview:self.customController.contentView atIndex:0];
    
    _buttonShareIcon.image = [UIImage templateImageNamed:@"ic_custom_export"];
    _buttonMoreIcon.image = [UIImage templateImageNamed:@"ic_custom_overflow_menu"];
    _buttonMoreLabel.text = OALocalizedString(@"shared_string_actions");
    _buttonMore.accessibilityLabel = OALocalizedString(@"shared_string_actions");
    
    if (self.customController.hasDismissButton)
    {
        _buttonDirectionIcon.image = [UIImage templateImageNamed:@"ic_custom_marker_remove"];
        _buttonDirectionIcon.tintColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
        _buttonDirectionLabel.text = OALocalizedString(@"shared_string_dismiss");
        _buttonDirection.accessibilityLabel = OALocalizedString(@"shared_string_dismiss");
        _buttonDirectionLabel.textColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
        _buttonDirectionIcon.transform = CGAffineTransformIdentity;
    }
    else
    {
        _buttonDirectionIcon.image = [UIImage templateImageNamed:@"ic_custom_arrow_direction"];
        _buttonDirectionIcon.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        _buttonDirectionLabel.text = OALocalizedString(@"map_marker");
        _buttonDirection.accessibilityLabel = OALocalizedString(@"quick_action_add_marker");
        _buttonDirectionLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
    }
    
    if (self.activeTargetType == OATargetGPX)
    {
        if (_targetPoint.type == OATargetWpt)
        {
            _buttonFavoriteLabel.text = OALocalizedString(@"edit_waypoint_short");
            _buttonFavorite.accessibilityLabel = OALocalizedString(@"edit_waypoint_short");
            [_buttonFavorite setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
        }
        else
        {
            _buttonFavoriteLabel.text = OALocalizedString(@"add_waypoint_short");
            _buttonFavorite.accessibilityLabel = OALocalizedString(@"add_waypoint_short");
            _buttonFavoriteIcon.image = [UIImage templateImageNamed:@"add_waypoint_to_track"];
        }
    }
    else
    {
        if (_targetPoint.type == OATargetFavorite)
        {
            _buttonFavoriteLabel.text = OALocalizedString(@"ctx_mnu_edit_fav");
            _buttonFavorite.accessibilityLabel = OALocalizedString(@"ctx_mnu_edit_fav");
            _buttonFavoriteIcon.image = [UIImage templateImageNamed:@"ic_custom_edit"];
        }
        else
        {
            _buttonFavoriteLabel.text = OALocalizedString(@"ctx_mnu_add_fav");
            _buttonFavorite.accessibilityLabel = OALocalizedString(@"ctx_mnu_add_fav");
            _buttonFavoriteIcon.image = [UIImage templateImageNamed:@"ic_custom_favorites"];
        }
    }
    
    _buttonFavoriteIcon.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    
    _imageView.hidden = NO;
    
    if (self.customController)
    {
        _backViewRoute.hidden = ![self.customController hasInfoView];
        _buttonShowInfo.hidden = ![self.customController hasInfoButton];
        _buttonRoute.hidden = ![self.customController hasRouteButton];
        [self.customController removeMapFrameLayer:self];
    }
    else
    {
        _backViewRoute.hidden = _hideButtons;
        _buttonShowInfo.hidden = NO;
        _buttonRoute.hidden = NO;
    }
    
    [self updateDirectionButton];
    [self updateTransportView];
    [self updateDescriptionLabel];
}

- (BOOL) hasInfo
{
    return self.customController && [self.customController contentHeight] > 0.0;
}

- (void) applyTargetObjectChanges
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_targetPoint.type == OATargetWpt)
        {
            OAGpxWptItem *item = _targetPoint.targetObj;
            _targetPoint.title = item.point.name;
            [_addressLabel setText:_targetPoint.title];
            [self updateAddressLabel];
            [self updateTransportView];
            [self updateDescriptionLabel];
            
            _imageView.image = item.getCompositeIcon;
        }
        else
        {
            [self applyTargetPoint];
            [self prepareNoInit];
        }

    });
}

- (CGFloat) getHeaderViewY
{
    return DeviceScreenHeight - _headerHeight + self.contentOffset.y;
}

- (CGFloat) getHeaderViewHeight
{
    return _headerHeight;
}

- (CGFloat) getVisibleHeight
{
    return _headerHeight + self.contentOffset.y;
}

- (CGFloat) getVisibleHeightWithOffset:(CGPoint)offset
{
    return _headerHeight + offset.y;
}

- (BOOL) isLandscapeSupported
{
    return OAUtilities.isIPad;
}

- (BOOL) isLandscape
{
    if (OAUtilities.isIPad && _targetPoint.type == OATargetRouteDetailsGraph)
        return NO;
    
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

- (CGFloat) getViewWidthForPad
{
    return OAUtilities.isLandscape ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    _hiding = NO;
    
    [self onMenuStateChanged];
    [self applyMapInteraction:[self getVisibleHeight] - OAUtilities.getBottomMargin animated:YES];

    [self applyTargetPoint];

    if (self.customController && [self.customController hasTopToolbar])
    {
        if ([self.customController shouldShowToolbar] || self.targetPoint.toolbarNeeded)
            [self showTopToolbar:YES];
    }
    if (self.customController && [self.customController hasBottomToolbar])
    {
        [self showBottomToolbar:YES];
    }
    if (self.customController && self.customController.additionalAccessoryView)
    {
        [self.parentView addSubview:self.customController.additionalAccessoryView];
    }
    
    if (self.customController)
    {
        if (_showFullScreen)
            [self.customController goFullScreen];
        else if (_showFull)
            [self.customController goFull];
    }
    
    if (_targetPoint.type == OATargetImpassableRoadSelection)
    {
        self.topView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    }
    else
    {
        self.topView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        //if (![self.gestureRecognizers containsObject:_panGesture])
        //    [self addGestureRecognizer:_panGesture];
    }
    
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -DeviceScreenWidth;
            frame.origin.y = OAUtilities.getStatusBarHeight;
            self.frame = frame;

            frame.origin.x = 0.0;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.origin.y = DeviceScreenHeight - _headerHeight + 10.0;
            self.frame = frame;

            frame.origin.y = 0;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            
            self.frame = frame;
            
        } completion:^(BOOL finished) {
            if (onComplete)
                onComplete();
            
            if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
                [self.menuViewDelegate targetViewEnableMapInteraction];
        }];
    }
    else
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.y = OAUtilities.getStatusBarHeight;
        else
            frame.origin.y = 0;
        
        self.frame = frame;
        
        if (onComplete)
            onComplete();

        if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
            [self.menuViewDelegate targetViewEnableMapInteraction];
    }

    [self startLocationUpdate];
    [self.menuViewDelegate targetViewOnAppear:[self getVisibleHeight] animated:YES];
    
    if (self.customController)
        [self.customController onMenuShown];
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    _hiding = YES;
    
    [[OARootViewController instance].mapPanel.hudViewController updateControlsLayout:YES];
    
    _visibleTransportRoutes = nil;

    if (self.superview)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.x = -frame.size.width;
        else
            frame.origin.y = DeviceScreenHeight - _headerY + self.contentOffset.y + 30.0;

        if (animated && duration > 0.0)
        {
            BOOL showingTopToolbar = (self.customController && [self.customController hasTopToolbar] && !self.customController.navBar.hidden);
            CGRect newTopToolbarFrame;
            if (showingTopToolbar)
            {
                newTopToolbarFrame = self.customController.navBar.frame;
                if ([self isLandscape])
                    newTopToolbarFrame.origin.x = -newTopToolbarFrame.size.width;
                else
                    newTopToolbarFrame.origin.y = -newTopToolbarFrame.size.height;
            }
            
            [UIView animateWithDuration:duration animations:^{
                
                self.frame = frame;

                if (showingTopToolbar)
                    self.customController.navBar.frame = newTopToolbarFrame;
                
            } completion:^(BOOL finished) {
                
                [self removeFromSuperview];
                
                if (self.menuViewDelegate && self.customController && self.customController.needsMapRuler)
                    [self.menuViewDelegate targetResetRulerPosition];
            
                [self clearCustomControllerIfNeeded];
                [self restoreTargetType];

                if (onComplete)
                    onComplete();
                
                if (finished)
                    _hiding = NO;
            }];
        }
        else
        {
            self.frame = frame;
            
            [self removeFromSuperview];
            
            if (self.menuViewDelegate && self.customController && self.customController.needsMapRuler)
                [self.menuViewDelegate targetResetRulerPosition];
            
            [self clearCustomControllerIfNeeded];
            [self restoreTargetType];

            if (onComplete)
                onComplete();

            _hiding = NO;
        }
    }
    else
    {
        _hiding = NO;
    }
    if (self.customController)
        [self.customController onMenuDismissed];
    
    [self stopLocationUpdate];
}

- (BOOL) preHide
{
    if (self.customController)
        return [self.customController preHide];
    else
        return YES;
}

- (BOOL) forceHideIfSupported
{
    if (self.customController)
    {
        if ([self.customController supportsForceClose])
        {
            [self.menuViewDelegate targetHideMenuByMapGesture];
            return YES;
        }
    }
    else
    {
        [self.menuViewDelegate targetHideMenuByMapGesture];
        return YES;
    }
    return NO;
}

- (BOOL) needsManualContextMode
{
    return self.customController && [self.customController shouldEnterContextModeManually];
}

- (void) hideByMapGesture
{
    if (self.customController)
    {
        if (![self.customController supportMapInteraction])
            [self.menuViewDelegate targetHideMenuByMapGesture];
    }
    else
    {
        [self.menuViewDelegate targetHideMenuByMapGesture];
    }
}

- (UIView *) bottomMostView
{
    return self;
}

- (void) updateZoomViewFrameAnimated:(BOOL)animated
{
    if (!_hiding && self.customController && [self.customController supportMapInteraction])
    {
        [self applyMapInteraction:[self getVisibleHeight] - OAUtilities.getBottomMargin animated:animated];
    }
}

- (void) layoutSubviews
{
    if (![self isSliding] && !_hiding)
    {
        [self doLayoutSubviews:NO];

        if ([_customController showDetailsButton])
        {
            NSIndexPath *collapseDetailsCellIndex = [NSIndexPath indexPathForRow:0 inSection:0];
            [((OATargetInfoViewController *)_customController).tableView reloadRowsAtIndexPaths:@[collapseDetailsCellIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void) doLayoutSubviews
{
    [self doLayoutSubviews:YES];
}

- (CGPoint) doLayoutSubviews:(BOOL)adjustOffset
{
    [self doUpdateUI];
    BOOL landscape = [self isLandscape];
    if (landscape)
    {
        _showFull = NO;
        _showFullScreen = NO;
    }
    BOOL hasVisibleToolbar = self.customController && [self.customController hasTopToolbar] && !self.customController.navBar.hidden;
    BOOL hasVisibleBottomBar = self.customController && [self.customController hasBottomToolbar] && !self.customController.bottomToolBarView.hidden;
    if (hasVisibleToolbar)
    {
        [self updateToolbarFrame:landscape];
    }
    if (hasVisibleBottomBar)
    {
        [self updateBottomToolbarFrame:landscape];
    }
    self.sliderView.hidden = landscape || (_customController && !_customController.supportFullMenu && !_customController.supportFullScreen);
    CGFloat toolBarHeight = hasVisibleToolbar ? self.customController.navBar.bounds.size.height : 0.0;
    CGFloat heightWithMargin = kOATargetPointButtonsViewHeight + ((!landscape && !_showFull && !_showFullScreen) ? [OAUtilities getBottomMargin] : 0);
    CGFloat buttonsHeight = !_hideButtons ? heightWithMargin : 0;
    CGFloat itemsX = 16.0 + [OAUtilities getLeftMargin];
    CGFloat topLabelY = _targetPoint.type == OATargetRouteDetails ? 16.0 : 20.0;
    CGFloat controlButtonsHeight = [self calculateControlButtonsHeight];
    
    CGRect sliderFrame = _sliderView.frame;
    sliderFrame.origin.x = _containerView.frame.size.width / 2 - _sliderView.frame.size.width / 2;
    _sliderView.frame = sliderFrame;

    CGFloat textX = (_imageView.image ? 50.0 : itemsX) + (_targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking ? 10.0 : 0.0);
    CGFloat width = (landscape ? (OAUtilities.isIPad ? [self getViewWidthForPad] : kInfoViewLanscapeWidth) + [OAUtilities getLeftMargin] : DeviceScreenWidth);
    
    CGFloat labelPreferredWidth = width - textX - 40.0 - [OAUtilities getLeftMargin];
    
    _addressLabel.preferredMaxLayoutWidth = labelPreferredWidth;
    CGFloat addressHeight = [OAUtilities calculateTextBounds:_addressLabel.text width:labelPreferredWidth font:_addressLabel.font].height;
    _addressLabel.frame = CGRectMake(itemsX, topLabelY, labelPreferredWidth, addressHeight);
    if ([_addressLabel isDirectionRTL])
        _addressLabel.textAlignment = NSTextAlignmentRight;
    
    CGFloat coordinateHeight;
    if (_coordinateLabel.attributedText)
        coordinateHeight = [OAUtilities calculateTextBounds:_coordinateLabel.attributedText width:labelPreferredWidth].height;
    else
        coordinateHeight = [OAUtilities calculateTextBounds:_coordinateLabel.text width:labelPreferredWidth font:_coordinateLabel.font].height;
        
    _coordinateLabel.preferredMaxLayoutWidth = labelPreferredWidth;
    _coordinateLabel.frame = CGRectMake(itemsX, _addressLabel.frame.origin.y + _addressLabel.frame.size.height + (_addressLabel.frame.size.height == 0 ? 0.0 : 10.0), labelPreferredWidth, coordinateHeight);
    if ([_coordinateLabel isDirectionRTL])
        _coordinateLabel.textAlignment = NSTextAlignmentRight;
    
    CGFloat topViewHeight = 0.0;
    CGFloat topY = (_targetPoint.type == OATargetRouteDetailsGraph || _targetPoint.type == OATargetChangePosition || _targetPoint.type == OATargetTransportRouteDetails || _targetPoint.type == OATargetDownloadMapSource || _targetPoint.type == OATargetNewMovableWpt) ? 0.0 : _coordinateLabel.frame.origin.y + _coordinateLabel.frame.size.height;
    BOOL hasDescription = !_descriptionLabel.hidden;
    BOOL hasTransport = !_transportView.hidden;
    if (hasTransport)
    {
        [_nearbyLabel sizeToFit];

        CGFloat border = itemsX;
        CGFloat margin = 0.0;
        CGFloat x = margin;
        CGFloat y = 0.0;
        CGFloat d = 4.0;
        CGFloat w = kTransportStopPlateWidth;
        CGFloat h = kTransportStopPlateHeight;
        CGFloat dh = (h - _nearbyLabel.frame.size.height) / 2.0;
        BOOL hasLocalRoutes = NO;
        
        for (UIView *v in _transportView.subviews)
        {
            if ([v isKindOfClass:[UILabel class]])
            {
                if (!v.hidden)
                {
                    CGRect r = v.frame;
                    r.origin.y = hasLocalRoutes ? y + h + d * 2 + dh : dh;
                    v.frame = r;
                    margin = r.size.width + d;
                    x = margin;
                    y = r.origin.y - dh;
                }
            }
            else
            {
                hasLocalRoutes = YES;
                if (x + w + d > width - border)
                {
                    x = margin;
                    y += v.frame.size.height + d;
                }
                v.frame = CGRectMake(x, y, v.frame.size.width, h);
                x += v.frame.size.width + d;
            }
        }
        _transportView.frame = CGRectMake(border, topY + 10.0, width - border * 2, y + h + 8.0);
        
        if (topViewHeight > 0)
            topViewHeight += _transportView.frame.size.height;
        else
            topViewHeight = _transportView.frame.origin.y + _transportView.frame.size.height;

        topY += _transportView.frame.size.height;
    }
    if (hasDescription)
    {
        CGFloat descriptionHeight = [OAUtilities calculateTextBounds:_descriptionLabel.text
                                                               width:labelPreferredWidth
                                                                font:_addressLabel.font].height;
        CGRect df = CGRectMake(itemsX, topY + 8.0, labelPreferredWidth, descriptionHeight);
        df.size.height += 14;
        _descriptionLabel.frame = df;
        if ([_descriptionLabel isDirectionRTL])
            _descriptionLabel.textAlignment = NSTextAlignmentRight;
        topViewHeight = _descriptionLabel.frame.origin.y + _descriptionLabel.frame.size.height;
        topY += _descriptionLabel.frame.size.height;
    }
    
    if (!hasDescription && !hasTransport)
    {
        topViewHeight = topY + ((_targetPoint.type == OATargetChangePosition || _targetPoint.type == OATargetTransportRouteDetails) || _targetPoint.type == OATargetDownloadMapSource || _targetPoint.type == OATargetNewMovableWpt ? 0.0 : 10.0) - (controlButtonsHeight > 0 ? 8 : 0) + (_hideButtons && !_showFull && !_showFullScreen && !_customController.hasBottomToolbar && _customController.needsAdditionalBottomMargin && controlButtonsHeight == 0. ? OAUtilities.getBottomMargin : 0);
    }
    else
    {
        topViewHeight += 10.0 - (controlButtonsHeight > 0 ? 4 : 0);
    }

    CGFloat infoViewHeight = (!self.customController || [self.customController hasInfoView]) && !_hideButtons ? _backViewRoute.bounds.size.height : 0;
    
    _topView.frame = CGRectMake(0.0, 0.0, width, topViewHeight);
    _controlButtonsView.hidden = controlButtonsHeight == 0;
    if (!_controlButtonsView.hidden)
    {
        _controlButtonsView.frame = CGRectMake(0.0, topViewHeight, width, controlButtonsHeight);
        _controlButtonLeft.hidden = self.customController.leftControlButton == nil;
        _controlButtonRight.hidden = self.customController.rightControlButton == nil;
        _controlButtonDownload.hidden = self.customController.downloadControlButton == nil || !self.downloadProgressBar.hidden;
        _controlButtonLeft.enabled = self.customController.leftControlButton && !self.customController.leftControlButton.disabled;
        _controlButtonRight.enabled = self.customController.rightControlButton && !self.customController.rightControlButton.disabled;
        _controlButtonDownload.enabled = self.customController.downloadControlButton && !self.customController.downloadControlButton.disabled;
        CGFloat x = itemsX;
        CGFloat w = (width - 32.0 - 8.0 - [OAUtilities getLeftMargin]) / 2.0;
        CGFloat downloadY = 4.0;
        CGRect leftControlButtonFrame = CGRectMake(x, 4.0, w, 32.0);
        x += w + 8.0;
        CGRect rightControlButtonFrame = CGRectMake(x, 4.0, w, 32.0);
        if (!_controlButtonLeft.hidden)
        {
            _controlButtonLeft.frame = [_controlButtonLeft isDirectionRTL] ? rightControlButtonFrame : leftControlButtonFrame;
            downloadY = CGRectGetMaxY(_controlButtonLeft.frame) + 6.0;
        }
        if (!_controlButtonRight.hidden)
        {
            _controlButtonRight.frame = [_controlButtonRight isDirectionRTL] ? leftControlButtonFrame : rightControlButtonFrame;
        }
        if (!_controlButtonDownload.hidden)
        {
            if (![_controlButtonDownload isDirectionRTL])
                _controlButtonDownload.frame = CGRectMake(itemsX, downloadY, w, 32.0);
            else
                _controlButtonDownload.frame = CGRectMake(width - itemsX - w, downloadY, w, 32.0);
        }
        if (!_downloadProgressBar.hidden && !_downloadProgressLabel.hidden && !_downloadCancelButton.hidden)
        {
            CGFloat viewWidth = width - 32.0 - OAUtilities.getLeftMargin;
            _downloadProgressLabel.frame = CGRectMake(itemsX, downloadY, viewWidth, 17.0);
            _downloadCancelButton.frame = CGRectMake(viewWidth - 15.0, CGRectGetMaxY(_downloadProgressLabel.frame) - 10.0, 30.0, 30.0);
            _downloadProgressBar.frame = CGRectMake(itemsX, CGRectGetMaxY(_downloadProgressLabel.frame) + 5.0, viewWidth - _downloadCancelButton.frame.size.width - 16.0, 5.0);
        }
    }
    CGFloat containerViewHeight = topViewHeight + controlButtonsHeight + buttonsHeight + infoViewHeight;
    _containerView.frame = CGRectMake(0.0, landscape ? (toolBarHeight > 0 ? toolBarHeight : [OAUtilities getStatusBarHeight]) : DeviceScreenHeight - containerViewHeight - self.customController.detailsButtonHeight, width, containerViewHeight);
    CGFloat bottomToolBarHeight = self.customController.hasBottomToolbar ? self.customController.bottomToolBarView.frame.size.height : 0.0;
    
    if (self.customController && [self.customController hasContent])
    {
        CGRect f = self.customController.contentView.frame;
        f.size.height = MAX(DeviceScreenHeight - toolBarHeight - (containerViewHeight - topViewHeight), [self.customController contentHeight:width] + self.customController.keyboardSize.height) + [OAUtilities getBottomMargin];
        
        self.customController.contentView.frame = f;
    }
    
    CGRect frame = self.frame;
    frame.size.width = width;
    
    CGFloat contentViewHeight = self.customController.contentView.frame.size.height + self.customController.getToolBarHeight;

    _headerY = _containerView.frame.origin.y;
    _headerHeight = containerViewHeight;
    _headerOffset = 0;
    
    _fullHeight = DeviceScreenHeight * kOATargetPointViewFullHeightKoef;
    _fullOffset = [self getFullOffset];
    
    _fullScreenHeight = _headerHeight + contentViewHeight;
    if (self.customController.showTopViewInFullscreen)
        _fullScreenOffset = _headerY + kTopViewCornerRadius - toolBarHeight;
    else
        _fullScreenOffset = _headerY + topViewHeight - toolBarHeight;
    
    CGFloat contentHeight = _headerY + _fullScreenHeight;
    
    if (landscape)
    {
        _topOverscrollView.frame = CGRectMake(0.0, _headerY - 1000.0, width, 1000.0);
        _topOverscrollView.hidden = NO;
    }
    else
    {
        _topOverscrollView.hidden = YES;
    }
    _bottomOverscrollView.frame = CGRectMake(0, contentHeight, width, 1000.0);

    self.frame = CGRectMake(0, 0, width, DeviceScreenHeight);
    self.contentInset = UIEdgeInsetsMake(0, 0, self.customController ? self.customController.keyboardSize.height : 0, 0);
    self.contentSize = CGSizeMake(frame.size.width, contentHeight);
    
    [self updateZoomViewFrameAnimated:YES];
    
    CGPoint newOffset;
    if (_showFullScreen)
        newOffset = {0, _fullScreenOffset};
    else if (_showFull)
        newOffset = {0, _fullOffset};
    else
        newOffset = {0, static_cast<CGFloat>(_customController.hasBottomToolbar && !landscape ? _customController.getToolBarHeight + topViewHeight / 2 : _headerOffset) + [self getAdditionalContentOffset]};
    
    if (adjustOffset)
        self.contentOffset = newOffset;

    if (_imageView.image)
    {
        if (_imageView.bounds.size.width < _imageView.image.size.width ||
            _imageView.bounds.size.height < _imageView.image.size.height)
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
        else
            _imageView.contentMode = UIViewContentModeTop;
    }
    
    if (self.customController.contentView)
    {
        self.customController.contentView.frame = CGRectMake(0.0, _headerY + _headerHeight, width, !landscape && [self.customController disableScroll] ? _fullOffset - bottomToolBarHeight : contentViewHeight - bottomToolBarHeight);
        if ([self.customController isMapFrameNeeded])
            [self.customController addMapFrameLayer:[self getMapFrame:width] view:self];
    }
    
    _buttonShadow.frame = CGRectMake(0.0, 0.0, width - 50.0, 73.0);
    
    CGFloat leftSafe = [OAUtilities getLeftMargin];
        
    _buttonsView.frame = CGRectMake(0.0, _topView.frame.origin.y + topViewHeight + controlButtonsHeight, width, infoViewHeight + heightWithMargin);
    _buttonsColoredView.frame = CGRectMake(0.0, kOATargetPointButtonsViewHeight, width, _buttonsView.frame.size.height - kOATargetPointButtonsViewHeight);

    CGFloat backViewWidth = (_buttonsView.frame.size.width - leftSafe - kMargin * 2 - kButtonsSideMargin * (_buttonsCount - 1)) / _buttonsCount;
    CGFloat x = leftSafe + kMargin;
    if ([_backViewRoute isDirectionRTL])
    {
        _backView4.frame = CGRectMake(x, kButtonsTopMargin, backViewWidth, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
        x += backViewWidth + kButtonsSideMargin;
        _backView3.frame = CGRectMake(x, kButtonsTopMargin, backViewWidth, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
        x += backViewWidth + kButtonsSideMargin;
        _backView2.frame = CGRectMake(x, kButtonsTopMargin, backViewWidth, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
        x += backViewWidth + kButtonsSideMargin;
        _backView1.frame = CGRectMake(x, kButtonsTopMargin, _buttonsView.frame.size.width - x - kMargin, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
    }
    else
    {
        _backView1.frame = CGRectMake(x, kButtonsTopMargin, backViewWidth, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
        x += backViewWidth + kButtonsSideMargin;
        _backView2.frame = CGRectMake(x, kButtonsTopMargin, backViewWidth, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
        x += backViewWidth + kButtonsSideMargin;
        _backView3.frame = CGRectMake(x, kButtonsTopMargin, backViewWidth, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
        x += backViewWidth + kButtonsSideMargin;
        _backView4.frame = CGRectMake(x, kButtonsTopMargin, _buttonsView.frame.size.width - x - kMargin, kOATargetPointButtonsViewHeight - kButtonsBottomMargin);
    }
    if (_backView4.hidden)
        _backView4.hidden = NO;
    
    _backView1.layer.cornerRadius = 6.0;
    _backView2.layer.cornerRadius = 6.0;
    _backView3.layer.cornerRadius = 6.0;
    _backView4.layer.cornerRadius = 6.0;
    
    _buttonFavorite.frame = _backView1.bounds;
    _buttonShare.frame = _backView2.bounds;
    _buttonDirection.frame = _backView3.bounds;
    _buttonMore.frame = _backView4.bounds;
    
    _buttonFavoriteIcon.frame = CGRectMake((_backView1.frame.size.width - kButtonsIconSize) / 2, kButtonsIconTopMargin, kButtonsIconSize, kButtonsIconSize);
    _buttonFavoriteLabel.frame = CGRectMake(kButtonsLabelSideMargin, kButtonsLabelTopMargin, _backView1.frame.size.width - 2 * kButtonsLabelSideMargin, kButtonsLabelHeight);
    _buttonShareIcon.frame = CGRectMake((_backView1.frame.size.width - kButtonsIconSize) / 2, kButtonsIconTopMargin, kButtonsIconSize, kButtonsIconSize);
    _buttonShareLabel.frame = CGRectMake(kButtonsLabelSideMargin, kButtonsLabelTopMargin, _backView2.frame.size.width - 2 * kButtonsLabelSideMargin, kButtonsLabelHeight);
    _buttonDirectionIcon.frame = CGRectMake((_backView3.frame.size.width - kButtonsIconSize) / 2, kButtonsIconTopMargin, kButtonsIconSize, kButtonsIconSize);
    _buttonDirectionLabel.frame = CGRectMake(kButtonsLabelSideMargin, kButtonsLabelTopMargin, _backView3.frame.size.width - 2 * kButtonsLabelSideMargin, kButtonsLabelHeight);
    _buttonMoreIcon.frame = CGRectMake((_backView4.frame.size.width - kButtonsIconSize) / 2, kButtonsIconTopMargin, kButtonsIconSize, kButtonsIconSize);
    _buttonMoreLabel.frame = CGRectMake(kButtonsLabelSideMargin, kButtonsLabelTopMargin, _backView4.frame.size.width - 2 * kButtonsLabelSideMargin, kButtonsLabelHeight);
    
    _buttonFavoriteIcon.layer.zPosition = _backView1.layer.zPosition + 1;
    _buttonFavoriteLabel.layer.zPosition = _backView1.layer.zPosition + 1;
    _buttonShareIcon.layer.zPosition = _backView2.layer.zPosition + 1;
    _buttonShareLabel.layer.zPosition = _backView2.layer.zPosition + 1;
    _buttonDirectionIcon.layer.zPosition = _backView3.layer.zPosition + 1;
    _buttonDirectionLabel.layer.zPosition = _backView3.layer.zPosition + 1;
    _buttonMoreIcon.layer.zPosition = _backView4.layer.zPosition + 1;
    _buttonMoreLabel.layer.zPosition = _backView4.layer.zPosition + 1;
    if (_buttonMore.hidden)
        _buttonMore.hidden = NO;
    
    _backViewRoute.frame = CGRectMake(0., _backView1.frame.origin.y + _backView1.frame.size.height + kButtonsBottomMargin, _buttonsView.frame.size.width, kOATargetPointInfoViewHeight);
    
    [_buttonRoute sizeToFit];
    [_buttonShowInfo sizeToFit];
    CGRect biFrame = _buttonShowInfo.frame;
    CGRect brFrame = _buttonRoute.frame;
    biFrame.size.height = _backViewRoute.frame.size.height - kButtonsBottomMargin;
    brFrame.size.height = _backViewRoute.frame.size.height - kButtonsBottomMargin;
    _buttonShowInfo.frame = biFrame;
    _buttonRoute.frame = brFrame;

    if ([_backViewRoute isDirectionRTL])
    {
        _buttonRoute.frame = CGRectMake(leftSafe + kMargin, 5, _buttonRoute.frame.size.width + 4, _buttonRoute.frame.size.height);
        [_buttonRoute setImage:[UIImage imageNamed:@"left_menu_icon_navigation.png"].imageWithHorizontallyFlippedOrientation forState:UIControlStateNormal];
        _buttonRoute.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        _buttonRoute.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        _buttonShowInfo.frame = CGRectMake(_backViewRoute.frame.size.width - _buttonShowInfo.frame.size.width - kMargin, 5, _buttonShowInfo.frame.size.width, _buttonShowInfo.frame.size.height);
    }
    else
    {
        _buttonShowInfo.frame = CGRectMake(leftSafe + kMargin, 5, _buttonShowInfo.frame.size.width, _buttonShowInfo.frame.size.height);
        [_buttonRoute setImage:[UIImage imageNamed:@"left_menu_icon_navigation.png"] forState:UIControlStateNormal];
        _buttonRoute.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _buttonRoute.imageEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        _buttonRoute.frame = CGRectMake(_backViewRoute.frame.size.width - _buttonRoute.frame.size.width - kMargin, 5, _buttonRoute.frame.size.width + 4, _buttonRoute.frame.size.height);
    }
    [_buttonFavorite setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
    [_buttonShare setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
    [_buttonDirection setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
    [_buttonMore setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
    
    if (_targetPoint.type == OATargetImpassableRoadSelection)
    {
        _horizontalRouteLine.hidden = YES;
    }
    else
    {
        _horizontalRouteLine.hidden = NO;
        _horizontalRouteLine.frame = CGRectMake(0.0, 0.0, _backViewRoute.frame.size.width, 0.5);
    }
    
    if (self.customController && [self.customController hasBottomToolbar])
        [self.customController setupToolBarButtonsWithWidth:width];
    
    self.topView.layer.mask = nil;
    self.containerView.layer.mask = nil;
    if (!landscape)
    {
        [OAUtilities setMaskTo:self.topView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        [OAUtilities setMaskTo:self.containerView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    
    return newOffset;
}

- (CGFloat) getFullOffset
{
    if (_targetPoint.type == OATargetImpassableRoadSelection)
        return DeviceScreenHeight / 3;
    else if ([self.customController mapHeightKoef] > 0)
        return DeviceScreenHeight * [self.customController mapHeightKoef];
    else
        return _headerY - (DeviceScreenHeight - _fullHeight);
}

- (CGRect) getMapFrame:(CGFloat)width
{
    CGRect mapFrame;
    if ([self isLandscape])
    {
        mapFrame = CGRectMake(width, 0, DeviceScreenWidth - width, DeviceScreenHeight);
    }
    else
    {
        CGFloat frameHeight = _headerY - _fullOffset - self.customController.navBar.bounds.size.height;
        mapFrame = CGRectMake(0, _headerY - frameHeight, width, frameHeight);
    }
    return mapFrame;
}

- (CGFloat) getAdditionalContentOffset
{
    return self.customController.additionalContentOffset;
}

- (CGFloat) calculateTopY
{
    CGFloat topY = _coordinateLabel.frame.origin.y + _coordinateLabel.frame.size.height;
    
    BOOL hasDescription = !_descriptionLabel.hidden;
    BOOL hasTransport = !_transportView.hidden;
    
    if (hasTransport)
        topY += _transportView.frame.size.height;
    
    if (hasDescription)
        topY += _descriptionLabel.frame.size.height;
    
    return topY;
}

- (CGFloat) calculateControlButtonsHeight
{
    CGFloat controlButtonsHeight = 0.0;
    if (self.customController)
    {
        if ([self.customController hasControlButtons])
            controlButtonsHeight += kButtonsViewHeight;
        BOOL hasDownloadControls = self.customController.downloadControlButton != nil || !self.downloadProgressBar.hidden;
        BOOL needsSecondRow = controlButtonsHeight == 0 || self.customController.leftControlButton;
        if (hasDownloadControls && needsSecondRow)
            controlButtonsHeight += kButtonsViewHeight;
        
        if (controlButtonsHeight > 0 && !_showFull && !_showFullScreen && !self.customController.hasBottomToolbar && self.customController.needsAdditionalBottomMargin && !hasDownloadControls && ![self.customController isKindOfClass:OAMapDownloadController.class] && ![self.customController isKindOfClass:OAWikiMenuViewController.class] && ![self.customController isKindOfClass:OAGPXWptViewController.class])
            controlButtonsHeight += OAUtilities.getBottomMargin;
    }
    
    return controlButtonsHeight;
}

- (CGFloat) calculateTopViewHeight
{
    CGFloat topViewHeight = 0.0;
    
    CGFloat controlButtonsHeight = [self calculateControlButtonsHeight];
    
    BOOL hasDescription = !_descriptionLabel.hidden;
    BOOL hasTransport = !_transportView.hidden;
    
    if (hasTransport)
        topViewHeight = _transportView.frame.origin.y + _transportView.frame.size.height;
    
    if (hasDescription)
        topViewHeight = _descriptionLabel.frame.origin.y + _descriptionLabel.frame.size.height;
    
    if (!hasDescription && !hasTransport)
    {
        topViewHeight = [self calculateTopY] + 10.0 - (controlButtonsHeight > 0 ? 8 : 0) + (_hideButtons && !_showFull && !_showFullScreen && !_customController.hasBottomToolbar ? OAUtilities.getBottomMargin : 0);
    }
    else
    {
        topViewHeight += + 10.0 - (controlButtonsHeight > 0 ? 4 : 0);
    }
    
    return topViewHeight;
}

- (CGPoint) calculateNewOffset
{
    CGPoint newOffset = CGPointZero;
    if (_showFullScreen)
        newOffset = {0, _fullScreenOffset};
    else if (_showFull)
        newOffset = {0, _fullOffset};
    else
        newOffset = {0, static_cast<CGFloat>(_customController.hasBottomToolbar && !self.isLandscape ? _customController.getToolBarHeight + [self calculateTopViewHeight] / 2 : _headerOffset) + [self getAdditionalContentOffset]};
    
    return newOffset;
}

-(void) setTargetPoint:(OATargetPoint *)targetPoint
{
    _targetPoint = targetPoint;
    _previousTargetType = targetPoint.type;
    _previousTargetIcon = targetPoint.icon;
}

-(void) updateTargetPointType:(OATargetPointType)targetType
{
    _targetPoint.type = targetType;
    [self applyTargetPoint];
}

-(void) restoreTargetType
{
    _targetPoint.toolbarNeeded = NO;

    if (_previousTargetType != _targetPoint.type && _targetPoint.type != OATargetFavorite && _targetPoint.type != OATargetWpt)
    {
        _targetPoint.type = _previousTargetType;
        _targetPoint.icon = _previousTargetIcon;
        [self applyTargetPoint];
    }
}

- (void) applyTargetPoint
{
    if (_targetPoint.type == OATargetParking)
    {
        [_addressLabel setText:OALocalizedString(@"map_widget_parking")];
        [self updateAddressLabel];
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
        if (plugin)
            [OADestinationCell setParkingTimerStr:[NSDate dateWithTimeIntervalSince1970:plugin.getParkingTime / 1000] creationDate:[NSDate dateWithTimeIntervalSince1970:plugin.getStartParkingTime / 1000] label:self.coordinateLabel shortText:NO];
    }
    else
    {
        NSString *t;
        if (_targetPoint.titleSecond)
        {
            t = [NSString stringWithFormat:@"%@ - %@", _targetPoint.title, _targetPoint.titleSecond];
            CGFloat h = [OAUtilities calculateTextBounds:t width:_addressLabel.bounds.size.width font:_addressLabel.font].height;
            if (h > 41.0)
            {
                t = _targetPoint.title;
            }
            else if (h > 21.0)
            {
                t = [NSString stringWithFormat:@"%@\n%@", _targetPoint.title, _targetPoint.titleSecond];
                h = [OAUtilities calculateTextBounds:t width:_addressLabel.bounds.size.width font:_addressLabel.font].height;
                if (h > 41.0)
                    t = _targetPoint.title;
            }
        }
        else
        {
            t = _targetPoint.title;
        }
        
        [_addressLabel setText:t];
        [self updateAddressLabel];
        [self updateTransportView];
        [self updateDescriptionLabel];
    }
    
    if (self.activeTargetType == OATargetGPX)
        _buttonFavorite.enabled = (_targetPoint.type != OATargetWpt) || (_targetPoint.type == OATargetWpt);
    //else
    //    _buttonFavorite.enabled = (_targetPoint.type != OATargetFavorite);
    
    if (self.customController)
    {
        if (self.customController.leftControlButton)
            [_controlButtonLeft setTitle:self.customController.leftControlButton.title forState:UIControlStateNormal];
        if (self.customController.rightControlButton)
            [_controlButtonRight setTitle:self.customController.rightControlButton.title forState:UIControlStateNormal];
        if (self.customController.downloadControlButton)
            [_controlButtonDownload setTitle:self.customController.downloadControlButton.title forState:UIControlStateNormal];
        
        if ([self.customController isKindOfClass:OAFavoriteViewController.class])
        {
            OAFavoriteViewController *favoriteController = (OAFavoriteViewController *)self.customController;
            _imageView.image = [favoriteController getIcon];
        }
        else if (_targetPoint.type == OATargetParking)
        {
            OAFavoriteItem *item = [OAFavoritesHelper getSpecialPoint:[OASpecialPointType PARKING]];
            if (item)
                _imageView.image = [item getCompositeIcon];
        }
        else
        {
            UIImage *icon = [self.customController getIcon];
            if (!icon)
            {
                if ([_targetPoint.targetObj isKindOfClass:OAPOI.class])
                {
                    icon = [((OAPOI *)_targetPoint.targetObj) icon];
                    if (!icon)
                        icon = _targetPoint.icon;
                }
                else
                {
                    icon = _targetPoint.icon;
                }
            }
            _imageView.image = icon;
            _imageView.hidden = NO;
        }
    }
    else
    {
        _imageView.image = _targetPoint.icon;
        _imageView.hidden = NO;
    }
    
    [_customController setTargetImage:_imageView.image];
}

- (void) updateAddressLabel
{
    if (self.customController)
    {
        NSAttributedString *attributedTypeStr = [self.customController getAttributedTypeStr];
        if (attributedTypeStr)
        {
            [_coordinateLabel setAttributedText:attributedTypeStr];
            if (_targetPoint.type != OATargetRouteDetails)
                [_coordinateLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
            return;
        }
        else
        {
            NSString *typeStr = [self.customController getTypeStr];
            if (!typeStr || typeStr.length == 0)
                typeStr = [self.customController getCommonTypeStr];
            NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] init];
            if (_targetPoint.titleAddress.length > 0 && ![_targetPoint.title hasPrefix:_targetPoint.titleAddress])
            {
                if (typeStr.length > 0)
                {
                    NSMutableAttributedString *typeAttrStr = [[NSMutableAttributedString alloc] initWithString:[typeStr stringByAppendingString:@": "]];
                    [typeAttrStr addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, typeAttrStr.length)];
                    NSMutableAttributedString *addressAttrStr = [[NSMutableAttributedString alloc] initWithString:_targetPoint.titleAddress];
                    [addressAttrStr addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] range:NSMakeRange(0, addressAttrStr.length)];
                    [attributedStr appendAttributedString:typeAttrStr];
                    [attributedStr appendAttributedString:addressAttrStr];
                    typeStr = [NSString stringWithFormat:@"%@: %@", typeStr, _targetPoint.titleAddress];
                }
                else
                {
                    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:_targetPoint.titleAddress]];
                    [attributedStr addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, attributedStr.length)];
                }
            }
            else if (typeStr)
            {
                [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:typeStr]];
                [attributedStr addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, attributedStr.length)];
            }
            self.addressStr = [attributedStr string];
            [_coordinateLabel setAttributedText:attributedStr];
            [_coordinateLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
            return;
        }
    }
    else
    {
        self.addressStr = _targetPoint.titleAddress;
    }
        
    [_coordinateLabel setText:self.addressStr];
    [_coordinateLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
}

- (void) updateDescriptionLabel
{
    if (self.customController)
    {
        NSAttributedString *attributedTypeStr = [self.customController getAdditionalInfoStr];
        [_descriptionLabel setAttributedText:attributedTypeStr];
        _descriptionLabel.hidden = !attributedTypeStr || attributedTypeStr.length == 0;
    }
    else
    {
        [_descriptionLabel setAttributedText:nil];
        _descriptionLabel.hidden = YES;
    }
}

- (void) updateTransportView
{
    if (self.customController)
    {
        for (UIView *v in _transportView.subviews)
            if ([v isKindOfClass:[UIButton class]])
                [v removeFromSuperview];

        NSArray<OATransportStopRoute *> *localTransportStopRoutes = [self filterTransportRoutes:[self.customController getLocalTransportStopRoutes]];
        NSArray<OATransportStopRoute *> *nearbyTransportStopRoutes = [self filterNearbyTransportRoutes:[self.customController getNearbyTransportStopRoutes] filterFromRoutes:localTransportStopRoutes];
        _visibleTransportRoutes = [localTransportStopRoutes arrayByAddingObjectsFromArray:nearbyTransportStopRoutes];
        NSInteger stopPlatesCount = 0;
        if (localTransportStopRoutes.count > 0)
        {
            NSInteger i = 0;
            for (OATransportStopRoute *route in localTransportStopRoutes)
            {
                UIImage *stopPlateImage = [OATransportStopViewController createStopPlate:route.route->ref.toNSString() color:[route getColor:NO]];
                UIButton *stopPlateButton = [UIButton buttonWithType:UIButtonTypeSystem];
                stopPlateButton.frame = CGRectMake(0., 0., stopPlateImage.size.width, stopPlateImage.size.height);
                [stopPlateButton setBackgroundImage:stopPlateImage forState:UIControlStateNormal];
                stopPlateButton.tag = stopPlatesCount++;
                [stopPlateButton addTarget:self action:@selector(onTransportPlatePressed:) forControlEvents:UIControlEventTouchUpInside];
                [_transportView insertSubview:stopPlateButton atIndex:i++];
            }
        }
        if (nearbyTransportStopRoutes.count > 0)
        {
            NSString *nearInDistance = [NSString stringWithFormat:@"%@ %@:", OALocalizedString(@"transport_nearby_routes"), [OAOsmAndFormatter getFormattedDistance:kShowStopsRadiusMeters]];
            _nearbyLabel.text = nearInDistance;
            _nearbyLabel.hidden = NO;

            for (OATransportStopRoute *route in nearbyTransportStopRoutes)
            {
                UIImage *stopPlateImage = [OATransportStopViewController createStopPlate:route.route->ref.toNSString() color:[route getColor:NO]];
                UIButton *stopPlateButton = [UIButton buttonWithType:UIButtonTypeSystem];
                stopPlateButton.frame = CGRectMake(0., 0., stopPlateImage.size.width, stopPlateImage.size.height);
                [stopPlateButton setBackgroundImage:stopPlateImage forState:UIControlStateNormal];
                stopPlateButton.tag = stopPlatesCount++;
                [stopPlateButton addTarget:self action:@selector(onTransportPlatePressed:) forControlEvents:UIControlEventTouchUpInside];
                [_transportView addSubview:stopPlateButton];
            }
        }
        else
        {
            _nearbyLabel.hidden = YES;
        }

        _transportView.hidden = localTransportStopRoutes.count == 0 && nearbyTransportStopRoutes.count == 0;
    }
    else
    {
        _transportView.hidden = YES;
    }
}

- (BOOL) containsRef:(NSArray<OATransportStopRoute *> *)routes transportRoute:(OATransportStopRoute *)transportRoute
{
    for (OATransportStopRoute *route in routes)
        if (route.route->type == transportRoute.route->type && route.route->ref == transportRoute.route->ref)
            return YES;

    return NO;
}

- (NSMutableArray<OATransportStopRoute *> *)filterNearbyTransportRoutes:(NSArray<OATransportStopRoute *> *)routes filterFromRoutes:(NSArray<OATransportStopRoute *> *)filterFromRoutes
{
    NSMutableArray<OATransportStopRoute *> *nearbyFilteredTransportStopRoutes = [self filterTransportRoutes:routes];
    if (filterFromRoutes == nil || filterFromRoutes.count == 0)
        return nearbyFilteredTransportStopRoutes;
    
    NSMutableArray<OATransportStopRoute *> *filteredRoutes = [NSMutableArray array];
    for (OATransportStopRoute *route in nearbyFilteredTransportStopRoutes)
    {
        if (![self containsRef:filterFromRoutes transportRoute:route])
        {
            [filteredRoutes addObject:route];
        }
    }
    return filteredRoutes;
}

- (NSMutableArray<OATransportStopRoute *> *) filterTransportRoutes:(NSArray<OATransportStopRoute *> *)routes
{
    NSMutableArray<OATransportStopRoute *> *filteredRoutes = [NSMutableArray array];
    for (OATransportStopRoute *r in routes)
    {
        if (![self containsRef:filteredRoutes transportRoute:r])
            [filteredRoutes addObject:r];
    }
    return filteredRoutes;
}

- (void) onTransportPlatePressed:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *button = (UIButton *) sender;
        if (button.tag < _visibleTransportRoutes.count)
        {
            OATransportStopRoute *r = _visibleTransportRoutes[button.tag];
            
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            OAMapViewController *mapController = mapPanel.mapViewController;

            OATargetPoint *targetPoint = [OATransportRouteController getTargetPoint:r];
            CLLocationCoordinate2D latLon = targetPoint.location;
                
            Point31 point31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.latitude, latLon.longitude))];
            [mapPanel prepareMapForReuse:point31 zoom:12 newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
            [mapController.mapLayers.transportStopsLayer showStopsOnMap:r];
            
            [mapPanel showContextMenuWithPoints:@[targetPoint]];

            [OATransportRouteController showToolbar:r];
        }
    }
}

-(void) setMapViewInstance:(UIView*)mapView
{
    self.mapView = (OAMapRendererView *)mapView;
}

-(void) setNavigationController:(UINavigationController*)controller
{
    self.navController = controller;
}

-(void) setParentViewInstance:(UIView*)parentView
{
    self.parentView = parentView;
}

-(void) setCustomViewController:(OATargetMenuViewController *)customController needFullMenu:(BOOL)needFullMenu
{
    [self clearCustomControllerIfNeeded];

    _customController = customController;
    self.customController.delegate = self;
    self.customController.navController = self.navController;
    [self.customController setContentBackgroundColor:[UIColor colorNamed:ACColorNameGroupBg]];
    self.customController.location = self.targetPoint.location;
    
    self.customController.view.frame = self.frame;
    
    if (self.superview)
    {
        [self doUpdateUI];
        [self doLayoutSubviews];
        if (needFullMenu)
        {
            [self showFullMenu];
        }
    }
}

- (void) onFavoritesCollectionChanged
{
    if (_targetPoint.type == OATargetFavorite)
    {
        BOOL favoriteOnTarget = NO;
        for (OAFavoriteItem *point in [OAFavoritesHelper getFavoriteItems])
        {
            if ([OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LongitudeX(point.favorite->getPosition31().x) destination:_targetPoint.location.longitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LatitudeY(point.favorite->getPosition31().y) destination:_targetPoint.location.latitude])
            {
                favoriteOnTarget = YES;
                break;
            }
        }
        
        if (!favoriteOnTarget)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.menuViewDelegate targetHide];
            });
    }
}

- (void) onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    if (_targetPoint.type == OATargetFavorite)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            OAFavoriteItem *item = [OAFavoritesHelper getVisibleFavByLat:favoriteLocation->getLatLon().latitude lon:favoriteLocation->getLatLon().longitude];
            _targetPoint.title = [item getDisplayName];
            
            [_addressLabel setText:_targetPoint.title];
            [self updateAddressLabel];
            _imageView.image = [item getCompositeIcon];
        });
    }
}

- (void) addFavorite
{
    NSString *locText;
    if (self.isAddressFound)
        locText = self.targetPoint.title;
    else
        locText = self.addressStr;
    
    [self.menuViewDelegate targetPointAddFavorite];
}

- (void) quickHide
{
    [UIView animateWithDuration:.3 animations:^{
       
        self.alpha = 0.0;
        if (self.customController && [self.customController hasTopToolbar])
            self.customController.navBar.alpha = 0.0;
    }];
}

- (void) quickShow
{
    [UIView animateWithDuration:.3 animations:^{
        
        self.alpha = 1.0;
        if (self.customController && [self.customController hasTopToolbar])
            self.customController.navBar.alpha = 1.0;
    }];
}

#pragma mark - Actions

- (IBAction)downloadButtonPressed:(id)sender
{
    if (self.customController)
        [self.customController downloadControlButtonPressed];
}

- (IBAction) controlButtonLeftClicked:(id)sender
{
    if (self.customController)
        [self.customController leftControlButtonPressed];
}

- (IBAction) controlButtonRightClicked:(id)sender
{
    if (self.customController)
        [self.customController rightControlButtonPressed];
}

- (IBAction) buttonFavoriteClicked:(id)sender
{
    if (self.targetPoint.type == OATargetFavorite)
    {
        self.customController.topToolbarType = ETopToolbarTypeFixed;
        [self showFullMenu];
        [self.customController activateEditing];
        
        OAFavoriteItem *item = self.targetPoint.targetObj;
        [self.menuViewDelegate targetPointEditFavorite:item];
        return;
    }

    if (self.activeTargetType == OATargetGPX)
    {
        [self.menuViewDelegate targetPointAddWaypoint];
    }
    else
    {
        [self addFavorite];
    }
}

- (IBAction) buttonShareClicked:(id)sender
{
    NSMutableArray *items = [NSMutableArray array];

    NSMutableString *sharingText = [[NSMutableString alloc] init];
    if (_previousTargetType == OATargetFavorite)
    {
        OAFavoriteViewController *source = (OAFavoriteViewController *) self.customController;

        NSString *itemName = [source getItemName];
        if (itemName.length > 0)
            [sharingText appendString:itemName];
        NSString *itemGroup = [source getItemGroup];
        if (itemGroup.length > 0)
        {
            if (sharingText.length > 0)
                [sharingText appendString:@"\n"];
            [sharingText appendString:itemGroup];
        }
        NSString *itemDesc = [source getItemDesc];
        if (itemDesc.length > 0)
        {
            if (sharingText.length > 0)
                [sharingText appendString:@"\n"];
            [sharingText appendString:itemDesc];
        }
    }
    else
    {
        if (_targetPoint.title.length > 0)
            [sharingText appendString:_targetPoint.title];
        if (_targetPoint.titleAddress.length > 0)
        {
            if (sharingText.length > 0)
                [sharingText appendString:@"\n"];
            [sharingText appendString:_targetPoint.titleAddress];
        }
        double lat = _targetPoint.location.latitude;
        double lon = _targetPoint.location.longitude;
        int zoom = _mapView.zoomLevel;
        NSString *geoUrl = [OAUtilities buildGeoUrl:lat longitude:lon zoom:zoom];
        if (geoUrl.length > 0)
        {
            NSString *cordinates = [NSString stringWithFormat:@"Location: %@",geoUrl];
                [sharingText appendString:@"\n"];
                [sharingText appendString:cordinates];
        }
        NSString *httpUrl = [NSString stringWithFormat:kShareLink, lat, lon, zoom, lat, lon];
        if (httpUrl.length > 0)
        {
            [sharingText appendString:@"\n"];
            [sharingText appendString:httpUrl];
        }
    }
    if (sharingText && sharingText.length > 0)
        [items addObject:sharingText];

    OAShareMenuActivity *shareClipboard = [[OAShareMenuActivity alloc] initWithType:OAShareMenuActivityClipboard];
    shareClipboard.delegate = self;

    OAShareMenuActivity *shareAddress = [[OAShareMenuActivity alloc] initWithType:OAShareMenuActivityCopyAddress];
    shareAddress.delegate = self;

    OAShareMenuActivity *sharePOIName = [[OAShareMenuActivity alloc] initWithType:OAShareMenuActivityCopyPOIName];
    sharePOIName.delegate = self;

    OAShareMenuActivity *shareCoordinates = [[OAShareMenuActivity alloc] initWithType:OAShareMenuActivityCopyCoordinates];
    shareCoordinates.delegate = self;

    OAShareMenuActivity *shareGeo = [[OAShareMenuActivity alloc] initWithType:OAShareMenuActivityGeo];
    shareGeo.delegate = self;
    
    UIButton *button = (UIButton *)sender;
    
    [self.navController showActivity:items applicationActivities:@[shareClipboard, shareAddress, sharePOIName, shareCoordinates, shareGeo] excludedActivityTypes:nil sourceView:button sourceRect:CGRect() barButtonItem:nil permittedArrowDirections:UIPopoverArrowDirectionAny completionWithItemsHandler:nil];

    [self.menuViewDelegate targetPointShare];
}

- (IBAction) buttonDirectionClicked:(id)sender
{
    [self.menuViewDelegate targetPointDirection];
}

- (IBAction) buttonMoreClicked:(id)sender
{
    OAMoreOprionsBottomSheetViewController *controller = [[OAMoreOprionsBottomSheetViewController alloc] initWithTargetPoint:_targetPoint targetType:(NSString *)[self.customController getCommonTypeStr]];
    controller.menuViewDelegate = _menuViewDelegate;
    [controller show];
}

- (IBAction) buttonShowInfoClicked:(id)sender
{
    if (_showFull || _showFullScreen)
        [self requestHeaderOnlyMode];
    else
        [self requestFullMode];
}

- (IBAction) buttonRouteClicked:(id)sender
{
    [self.menuViewDelegate navigate:self.targetPoint];
}

- (IBAction) buttonShadowClicked:(id)sender
{
    if (_showFullScreen)
        return;

    [self.menuViewDelegate targetGoToPoint];
}

- (IBAction)buttonCancelDownloadPressed:(id)sender
{
    [self.customController onDownloadCancelled];
}

- (void) onMenuStateChanged
{
    if (_showFull || _showFullScreen)
        [_buttonShowInfo setTitle:[OALocalizedString(@"shared_string_collapse") upperCase] forState:UIControlStateNormal];
    else
        [_buttonShowInfo setTitle:[OALocalizedString(@"shared_string_details") upperCase] forState:UIControlStateNormal];
}

- (void) applyMapInteraction:(CGFloat)height animated:(BOOL)animated
{
    if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
        [self.menuViewDelegate targetViewEnableMapInteraction];
    else
        [self.menuViewDelegate targetViewDisableMapInteraction];
    [[OARootViewController instance].mapPanel.hudViewController updateControlsLayout:YES];
}

- (UIStatusBarStyle) getStatusBarStyle:(BOOL)contextMenuMode defaultStyle:(UIStatusBarStyle)defaultStyle
{
    if (contextMenuMode && ![self needsManualContextMode])
    {
        if ([self isToolbarVisible] || [self isInFullScreenMode] || [self isLandscape])
            return UIStatusBarStyleLightContent;
        else
            return UIStatusBarStyleDefault;
    }
    else if (self.superview)
    {
        if (self.customController && [self.customController showTopControls])
        {
            return defaultStyle;
        }
        else if ([self isToolbarVisible])
        {
            CGFloat alpha;
            if (self.customController)
            {
                switch (self.customController.topToolbarType)
                {
                    case ETopToolbarTypeFloating:
                        alpha = [self getTopToolbarAlpha];
                        break;
                    case ETopToolbarTypeMiddleFixed:
                        alpha = [self getMiddleToolbarAlpha];
                        break;
                    case ETopToolbarTypeFixed:
                        alpha = 1.0;
                        break;
                        
                    default:
                        break;
                }
            }
            else
            {
                alpha = [self getTopToolbarAlpha];
            }

            return alpha > 0.5 ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
        }
        else if ([self isInFullScreenMode] || [self isLandscape])
        {
            return UIStatusBarStyleDefault;
        }
    }
    return defaultStyle;
}

- (CGFloat) getMiddleToolbarAlpha
{
    CGFloat alpha = self.alpha;
    if (alpha > 0)
    {
        CGFloat a = _fullOffset;
        CGFloat c = self.contentOffset.y - [OAUtilities getStatusBarHeight];
        alpha = c / a;
        if (alpha < 0)
            alpha = 0.0;
        if (alpha > 1)
            alpha = 1.0;
    }
    else
    {
        alpha = 0.0;
    }
    return alpha;
}

- (CGFloat) getTopToolbarAlpha
{
    CGFloat alpha = self.alpha;
    if (alpha > 0 && ![self isLandscape])
    {
        CGFloat a = _headerY - [OAUtilities getStatusBarHeight];
        CGFloat b = _headerY - self.customController.navBar.frame.size.height;
        CGFloat c = self.contentOffset.y + self.customController.navBar.frame.size.height;
        alpha = (c - b) / (a - b);
        if (alpha < 0)
            alpha = 0.0;
        if (alpha > 1)
            alpha = 1.0;
    }
    return alpha;
}

- (UITextField *) getActiveTextField
{
    return [self getActiveTextField:self.subviews];
}

- (UITextField *) getActiveTextField:(NSArray<__kindof UIView *> *)views
{
    for (UIView *v in views)
    {
        if ([v isKindOfClass:[UITextField class]])
        {
            UITextField *tf = (UITextField *)v;
            if ([tf isFirstResponder])
                return tf;
        }
        if ([v isKindOfClass:[UITableView class]])
        {
            UITableView *tableView = (UITableView *)v;
            for (NSInteger section = 0; section < tableView.numberOfSections; section++)
            {
                for (NSInteger row = 0; row < [tableView numberOfRowsInSection:section]; row++)
                {
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                    UITextField *tf = [self getActiveTextField:cell.subviews];
                    if (tf)
                        return tf;
                }
            }
        }
    }
    return nil;
}

#pragma mark
#pragma mark - OATargetMenuViewControllerDelegate

- (void) keyboardWasShown:(CGFloat)keyboardHeight
{
    [self doLayoutSubviews:NO];
    
    CGRect aRect = self.frame;
    aRect.size.height -= keyboardHeight;
    UITextField *activeField = [self getActiveTextField];
    if (activeField)
    {
        CGPoint convertedPoint = [activeField convertPoint:activeField.frame.origin toView:self];
        CGRect convertedFrame = CGRectMake(convertedPoint.x, convertedPoint.y, activeField.frame.size.width, activeField.frame.size.height);
        
        if (!CGRectContainsPoint(aRect, convertedPoint))
        {
            [self scrollRectToVisible:convertedFrame animated:YES];
        }
    }
}

- (void) keyboardWasHidden:(CGFloat)keyboardHeight
{
    [self setNeedsLayout];
}

- (void) contentHeightChanged:(CGFloat)newHeight
{
    [UIView animateWithDuration:.3 animations:^{
        [self contentHeightChanged];
    }];
}

- (void) contentHeightChanged
{
    [self doLayoutSubviews:NO];
    [self.menuViewDelegate targetViewHeightChanged:[self getVisibleHeight] animated:YES];
}

- (void) contentChanged
{
    if (![_controlButtonDownload.titleLabel.text isEqualToString:self.customController.downloadControlButton.title])
        [_controlButtonDownload setTitle:self.customController.downloadControlButton.title forState:UIControlStateNormal];

    [self doLayoutSubviews:YES];
}

- (void) addresLabelUpdated
{
    [self updateAddressLabel];
}

- (CGPoint) applyMode:(BOOL)applyOffset
{
    CGPoint newOffset = self.contentOffset;
    if (applyOffset)
    {
        [UIView animateWithDuration:.3 animations:^{
            [self doLayoutSubviews];
        } completion:^(BOOL finished) {
            if (!_showFullScreen)
                [self.menuViewDelegate targetViewHeightChanged:[self getVisibleHeight] animated:YES];
        }];
    }
    else
    {
        newOffset = _customController.needsLayoutOnModeChange ? [self doLayoutSubviews:NO] : [self calculateNewOffset];
        if (!_showFullScreen)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.menuViewDelegate targetViewHeightChanged:[self getVisibleHeightWithOffset:newOffset] animated:YES];
            });
        }
    }
    if (self.customController)
    {
        BOOL showTopControls = [self.customController showTopControls];
        [self.menuViewDelegate targetUpdateControlsLayout:showTopControls customStatusBarStyle:[OAAppSettings sharedManager].nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDarkContent];
        if (!showTopControls)
            [self.menuViewDelegate targetResetCustomStatusBarStyle];
    }
    return newOffset;
}

- (void) showProgressBar
{
    if (_downloadProgressBar.hidden)
        _downloadProgressBar.hidden = NO;
    if (_downloadProgressLabel.hidden)
        _downloadProgressLabel.hidden = NO;
    if (_downloadCancelButton.hidden)
        _downloadCancelButton.hidden = NO;
    
    [_downloadProgressBar setProgress:0.];
    _downloadProgressLabel.text = OALocalizedString(@"download_pending");
    _downloadProgressLabel.font = [UIFont monospacedFontAt:15 withTextStyle:UIFontTextStyleBody];
    
    [self doLayoutSubviews:YES];
}

- (void) setDownloadProgress:(float)progress text:(NSString *)text
{
    _downloadProgressLabel.text = text;
    [_downloadProgressBar setProgress:progress];
}

- (void) hideProgressBar
{
    if (!_downloadProgressBar.hidden)
        _downloadProgressBar.hidden = YES;
    if (!_downloadProgressLabel.hidden)
        _downloadProgressLabel.hidden = YES;
    if (!_downloadCancelButton.hidden)
        _downloadCancelButton.hidden = YES;
    
    [self doLayoutSubviews:YES];
}

- (void) openRouteSettings
{
    [self.menuViewDelegate targetOpenRouteSettings];
}

- (void) requestHeaderOnlyMode
{
    [self requestHeaderOnlyMode:YES];
}

- (CGPoint) requestHeaderOnlyMode:(BOOL)applyOffset
{
    CGPoint newOffset = self.contentOffset;
    if (![self isLandscape])
    {
        _showFull = NO;
        _showFullScreen = NO;

        CGFloat h = _headerHeight;
        
        if (self.customController && [self.customController hasTopToolbar] && (![self.customController shouldShowToolbar] && !self.targetPoint.toolbarNeeded))
            [self hideTopToolbar:YES];
        
        if (self.customController)
            [self.customController goHeaderOnly];

        [self onMenuStateChanged];
        [self applyMapInteraction:h animated:YES];
        
        newOffset = [self applyMode:applyOffset];
    }
    return newOffset;
}

- (void) requestFullMode
{
    [self requestFullMode:YES];
}

- (CGPoint) requestFullMode:(BOOL)applyOffset
{
    CGPoint newOffset = self.contentOffset;
    if (![self isLandscape])
    {
        _showFull = YES;
        _showFullScreen = NO;

        if (self.customController)
            [self.customController goFull];

        [self onMenuStateChanged];
        [self applyMapInteraction:_fullHeight animated:YES];

        newOffset = [self applyMode:applyOffset];
    }
    return newOffset;
}

- (void) requestFullScreenMode
{
    [self requestFullScreenMode:YES];
}

- (CGPoint) requestFullScreenMode:(BOOL)applyOffset
{
    CGPoint newOffset = self.contentOffset;
    if (![self isLandscape])
    {
        _showFull = YES;
        _showFullScreen = YES;
        
        if (self.customController)
            [self.customController goFullScreen];

        [self onMenuStateChanged];

        newOffset = [self applyMode:applyOffset];
    }
    return newOffset;
}

- (NSString *) getTargetTitle
{
    return _targetPoint.title;
}

- (BOOL) isInFullMode
{
    return _showFull;
}

- (BOOL) isInFullScreenMode
{
    return _showFullScreen;
}

- (void) btnOkPressed
{
    _previousTargetType = _targetPoint.type;
    _previousTargetIcon = _targetPoint.icon;
    [self.menuViewDelegate targetHideMenu:.3 backButtonClicked:NO onComplete:nil];
}

- (void) btnCancelPressed
{
    [self.menuViewDelegate targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
}

- (void) btnDeletePressed
{
    [self.menuViewDelegate targetHideContextPinMarker];
    [self.menuViewDelegate targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
}

- (void) addWaypoint
{
    [self.menuViewDelegate targetPointAddWaypoint];
}

#pragma mark - UIScrollViewDelegate

- (void) setTargetContentOffset:(CGPoint)newOffset withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (copysign(1.0, newOffset.y - targetContentOffset->y) != copysign(1.0, velocity.y))
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setContentOffset:newOffset animated:YES];
        });
    }
    else
    {
        *targetContentOffset = newOffset;
    }
}

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //BOOL slidingUp = velocity.y > 0;
    BOOL slidingDown = velocity.y < -0.3;
    
    BOOL supportFull = !self.customController || [self.customController supportFullMenu];
    BOOL supportFullScreen = !self.customController || [self.customController supportFullScreen];
    
    BOOL goFull = NO;
    BOOL goFullScreen = NO;
    BOOL needCloseMenu = NO;
    BOOL shownFullScreen = _showFullScreen;
    
    CGFloat offsetY = targetContentOffset->y;
    
    CGFloat headerDist = ABS(offsetY - _headerOffset);
    CGFloat halfDist = ABS(offsetY - _fullOffset);
    CGFloat fullDist = ABS(offsetY - _fullScreenOffset);
    if ((headerDist < halfDist && headerDist < fullDist) || self.isLandscape)
    {
        goFull = NO;
        goFullScreen = NO;
    }
    else if (halfDist < headerDist && halfDist < fullDist && supportFull)
    {
        goFull = YES;
        goFullScreen = NO;
    }
    else if (supportFullScreen)
    {
        goFull = YES;
        goFullScreen = YES;
    }
    
    if (slidingDown && _showFull && _showFullScreen && offsetY < _fullScreenOffset)
    {
        //slidingDown = NO;
        //goFull = YES;
        //goFullScreen = YES;
    }

    if (slidingDown && !goFull && !goFullScreen)
        needCloseMenu = ![self isLandscape] && !_showFull && [self preHide] && !(self.customController && [self.customController supportMapInteraction] && ![self.customController supportsForceClose]);
    
    if (needCloseMenu)
    {
        [self.menuViewDelegate targetHideContextPinMarker];
        OATargetMenuViewController __block *customController = self.customController;
        [self.menuViewDelegate targetHideMenu:.25 backButtonClicked:NO onComplete:^{
            if (customController)
                [customController onMenuSwipedOff];
        }];
    }
    else
    {
        CGPoint newOffset;
        if (goFullScreen)
        {
            newOffset = [self requestFullScreenMode:NO];
            if ((!shownFullScreen && targetContentOffset->y < newOffset.y) || (targetContentOffset->y < _fullScreenOffset))
                [self setTargetContentOffset:newOffset withVelocity:velocity targetContentOffset:targetContentOffset];
        }
        else if (goFull)
        {
            newOffset = [self requestFullMode:NO];
            [self setTargetContentOffset:newOffset withVelocity:velocity targetContentOffset:targetContentOffset];
        }
        else
        {
            newOffset = [self requestHeaderOnlyMode:NO];
            if (targetContentOffset->y + [self getAdditionalContentOffset] > 0 && !_customController.hasBottomToolbar)
                [self setTargetContentOffset:newOffset withVelocity:velocity targetContentOffset:targetContentOffset];
            else if (_customController.hasBottomToolbar && ![self isLandscape])
                [self setTargetContentOffset:newOffset withVelocity:CGPointZero targetContentOffset:targetContentOffset];
        }
    }
}

#pragma mark - OAScrollViewDelegate

- (void) onContentOffsetChanged:(CGPoint)contentOffset
{
    if (self.customController)
    {
        CGFloat topToolbarAlpha = [self getTopToolbarAlpha];
        CGFloat middleToolbarAlpha = [self getMiddleToolbarAlpha];
        [self.customController setTopToolbarAlpha:topToolbarAlpha];
        [self.customController setMiddleToolbarAlpha:middleToolbarAlpha + topToolbarAlpha];
    }

    if (self.menuViewDelegate)
    {
        BOOL landscape = [self isLandscape];
        [self.menuViewDelegate targetStatusBarChanged];
        if (self.customController && self.customController.needsMapRuler)
        {
            CGFloat rulerHeight = 25.0;
            [self.menuViewDelegate targetResetRulerPosition];
        }
        if (self.customController && self.customController.additionalAccessoryView)
        {
            CGRect viewFrame = self.customController.additionalAccessoryView.frame;
            viewFrame.origin = CGPointMake(landscape ? self.frame.size.width + 16. : 16., DeviceScreenHeight - ((landscape ? 25.0 : [self getVisibleHeight]) + OAUtilities.getBottomMargin));
            self.customController.additionalAccessoryView.frame = viewFrame;
        }
    }
    [self updateZoomViewFrameAnimated:YES];
}

- (BOOL) isScrollAllowed
{
    BOOL scrollDisabled = self.customController && (self.customController.showingKeyboard || (self.customController.editing && [self.customController disablePanWhileEditing]) || self.customController.disableScroll);
    
    if (!scrollDisabled)
    {
        BOOL supportFull = !self.customController || [self.customController supportFullMenu];
        BOOL supportFullScreen = !self.customController || [self.customController supportFullScreen];

        scrollDisabled = !supportFull && !supportFullScreen;
    }
    
    return !scrollDisabled;
}

#pragma mark - OAShareMenuDelegate

- (void)onCopy:(OAShareMenuActivityType)type
{
    switch (type)
    {
        case OAShareMenuActivityClipboard:
        {
            double lat = _targetPoint.location.latitude;
            double lon = _targetPoint.location.longitude;
            int zoom = _mapView.zoomLevel;
            NSString *geoUrl = [OAUtilities buildGeoUrl:lat longitude:lon zoom:zoom];
            NSString *httpUrl = [NSString stringWithFormat:kShareLinkTemplate, lat, lon, zoom, lat, lon];
            NSMutableString *sms = [NSMutableString string];
            if (_targetPoint.title && _targetPoint.title.length > 0)
            {
                [sms appendString:_targetPoint.title];
                [sms appendString:@"\n"];
            }
            if (_targetPoint.titleAddress && _targetPoint.titleAddress.length > 0
                    && ![_targetPoint.titleAddress isEqualToString:_targetPoint.title]
                    && ![_targetPoint.titleAddress isEqualToString:OALocalizedString(@"no_address_found")])
            {
                [sms appendString:_targetPoint.titleAddress];
                [sms appendString:@"\n"];
            }

            [sms appendString:OALocalizedString(@"shared_string_location")];
            [sms appendString:@": "];

            if ([self isDirectionRTL])
                [sms appendString:@"\n"];

            [sms appendString:geoUrl];
            [sms appendString:@"\n"];
            [sms appendString:httpUrl];

            [self copyToClipboardWithToast:sms];
            break;
        }
        case OAShareMenuActivityCopyAddress:
        {
            if (_targetPoint.titleAddress && _targetPoint.titleAddress.length > 0)
                [self copyToClipboardWithToast:_targetPoint.titleAddress];
            else
                [OAUtilities showToast:OALocalizedString(@"no_address_found") details:nil duration:4 inView:self.parentView];
            break;
        }
        case OAShareMenuActivityCopyPOIName:
        {
            if (_targetPoint.title && _targetPoint.title.length > 0)
                [self copyToClipboardWithToast:_targetPoint.title];
            else
                [OAUtilities showToast:OALocalizedString(@"toast_empty_name_error") details:nil duration:4 inView:self.parentView];
            break;
        }
        case OAShareMenuActivityCopyCoordinates:
        {
            OAAppSettings *settings = [OAAppSettings sharedManager];
            NSInteger f = [settings.settingGeoFormat get];
            NSString *coordinates = [OAOsmAndFormatter getFormattedCoordinatesWithLat:_targetPoint.location.latitude
                                                                                  lon:_targetPoint.location.longitude
                                                                         outputFormat:f];
            [self copyToClipboardWithToast:coordinates];
            break;
        }
        case OAShareMenuActivityGeo:
        {
            NSString *geoUrl = [OAUtilities buildGeoUrl:_targetPoint.location.latitude
                                              longitude:_targetPoint.location.longitude
                                                   zoom:_mapView.zoomLevel];
            [self copyToClipboardWithToast:geoUrl];
            break;
        }
    }
}

- (void)copyToClipboardWithToast:(NSString *)text
{
    [[UIPasteboard generalPasteboard] setString:text];
    [OAUtilities showToast:OALocalizedString(@"copied_to_clipboard") details:text duration:4 inView:self.parentView];
}

@end
