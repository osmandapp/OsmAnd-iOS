//
//  OATargetPointView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATargetPointView.h"
#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "PXAlertView.h"
#import "OAUtilities.h"
#import "OADestination.h"
#import "OADestinationCell.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAGPXDatabase.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAEditTargetViewController.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAScrollView.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>

@interface OATargetPointZoomView ()

@property (weak, nonatomic) IBOutlet UIButton *buttonZoomIn;
@property (weak, nonatomic) IBOutlet UIButton *buttonZoomOut;

@end

@implementation OATargetPointZoomView

#pragma mark - Actions

- (IBAction) buttonZoomInClicked:(id)sender
{
    if (self.delegate)
        [self.delegate zoomInPressed];
}

- (IBAction) buttonZoomOutClicked:(id)sender
{
    if (self.delegate)
        [self.delegate zoomOutPressed];
}

@end


@interface OATargetPointView() <OATargetPointZoomViewDelegate, UIScrollViewDelegate, OAScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topOverscrollView;
@property (weak, nonatomic) IBOutlet UIView *bottomOverscrollView;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *buttonLeft;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet OAButton *buttonFavorite;
@property (weak, nonatomic) IBOutlet OAButton *buttonShare;
@property (weak, nonatomic) IBOutlet OAButton *buttonDirection;
@property (weak, nonatomic) IBOutlet OAButton *buttonMore;

@property (weak, nonatomic) IBOutlet UIButton *buttonShadow;

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;
@property (weak, nonatomic) IBOutlet UIView *backView4;

@property (weak, nonatomic) IBOutlet UIView *backViewRoute;
@property (weak, nonatomic) IBOutlet UIButton *buttonShowInfo;
@property (weak, nonatomic) IBOutlet UIButton *buttonRoute;

@property (nonatomic) OATargetPointZoomView *zoomView;

@property NSString* addressStr;
@property OAMapRendererView* mapView;
@property UINavigationController* navController;
@property UIView* parentView;

@property (nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;

@end

@implementation OATargetPointView
{
    NSInteger _buttonsCount;
    OAIAPHelper *_iapHelper;
    
    CALayer *_horizontalLine;
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
    CGPoint _topViewStartSlidingPos;
    
    OATargetPointType _previousTargetType;
    UIImage *_previousTargetIcon;
    
    BOOL _toolbarVisible;
    CGFloat _toolbarHeight;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATargetPointView class]])
            self = (OATargetPointView *)v;
        else if ([v isKindOfClass:[OATargetPointZoomView class]])
            self.zoomView = (OATargetPointZoomView *)v;
    }
    
    if (self && self.zoomView)
        self.zoomView.delegate = self;
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATargetPointView class]])
            self = (OATargetPointView *)v;
        else if ([v isKindOfClass:[OATargetPointZoomView class]])
            self.zoomView = (OATargetPointZoomView *)v;
    }
    
    if (self && self.zoomView)
        self.zoomView.delegate = self;
    
    if (self)
    {
        self.frame = frame;
    }
    
    return self;
}

- (void) awakeFromNib
{
    _iapHelper = [OAIAPHelper sharedInstance];
    
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.bouncesZoom = NO;
    self.scrollsToTop = NO;
    self.multipleTouchEnabled = NO;
    self.bounces = YES;
    self.alwaysBounceVertical = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
 
    self.delegate = self;
    self.oaDelegate = self;

    self.buttonDirection.imageView.clipsToBounds = NO;
    self.buttonDirection.imageView.contentMode = UIViewContentModeCenter;
    
    [self doUpdateUI];

    [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_add_fav") forState:UIControlStateNormal];
    [_buttonShare setTitle:OALocalizedString(@"ctx_mnu_share") forState:UIControlStateNormal];
    [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];
    [_buttonShowInfo setTitle:[OALocalizedString(@"shared_string_info") upperCase] forState:UIControlStateNormal];
    [_buttonRoute setTitle:[OALocalizedString(@"gpx_route") upperCase] forState:UIControlStateNormal];

    _backView4.hidden = YES;
    _buttonMore.hidden = YES;

    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    [_containerView.layer setShadowColor:[UIColor blackColor].CGColor];
    [_containerView.layer setShadowOpacity:0.2];
    [_containerView.layer setShadowRadius:1.5];
    [_containerView.layer setShadowOffset:CGSizeMake(-1.5, 1.5)];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(0xe3e3e3) CGColor];
    
    [_buttonsView.layer addSublayer:_horizontalLine];

    _horizontalRouteLine = [CALayer layer];
    _horizontalRouteLine.backgroundColor = [UIColorFromRGB(0xe3e3e3) CGColor];
    [_backViewRoute.layer addSublayer:_horizontalRouteLine];

    [self updateColors];
    
    [OsmAndApp instance].favoritesCollection->collectionChangeObservable.attach((__bridge const void*)self,
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                                {
                                                                    [self onFavoritesCollectionChanged];
                                                                });

    [OsmAndApp instance].favoritesCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
                                                                      [self]
                                                                      (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                       const std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation)
                                                                      {
                                                                          [self onFavoriteLocationChanged:favoriteLocation];
                                                                      });
}

- (void) startLocationUpdate
{
    if (self.locationServicesUpdateObserver)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(doLocationUpdate)
                                                                     andObserve:app.locationServices.updateObserver];
}

- (void) stopLocationUpdate
{
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

- (void) doLocationUpdate
{
    if (_targetPoint.type == OATargetParking || _targetPoint.type == OATargetDestination || _targetPoint.type == OATargetImpassableRoad)
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
        
        if (_targetPoint.type == OATargetParking && _targetPoint.targetObj)
        {
            OADestination *d = _targetPoint.targetObj;
            if (d && d.carPickupDateEnabled)
            {
                [OADestinationCell setParkingTimerStr:_targetPoint.targetObj label:self.coordinateLabel shortText:NO];
            }
        }
    });
}

- (void) updateDirectionButton
{
    if (_targetPoint.type == OATargetParking || _targetPoint.type == OATargetDestination || _targetPoint.type == OATargetImpassableRoad)
    {
        self.buttonDirection.imageView.transform = CGAffineTransformIdentity;
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
    
    NSString *distanceStr = [[OsmAndApp instance] getFormattedDistance:distance];
    
    CGFloat itemDirection = [[OsmAndApp instance].locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:_targetPoint.location.latitude longitude:_targetPoint.location.longitude]];
    CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    
    self.buttonDirection.imageView.transform = CGAffineTransformMakeRotation(direction);
    self.buttonDirection.titleLabel.text = distanceStr;
    [self.buttonDirection setTitle:distanceStr forState:UIControlStateNormal];
}

- (void) updateToolbarGradientWithAlpha:(CGFloat)alpha
{
    BOOL useGradient = (_activeTargetType != OATargetGPX) && (_activeTargetType != OATargetGPXEdit) && ![self isLandscape];
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
        self.customController.navBar.frame = CGRectMake(0.0, 0.0, kInfoViewLanscapeWidth, f.size.height);
    }
    else
    {
        CGRect f = self.customController.navBar.frame;
        self.customController.navBar.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, f.size.height);
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
        self.customController.navBar.frame = CGRectMake(-kInfoViewLanscapeWidth, 0.0, kInfoViewLanscapeWidth, f.size.height);
        topToolbarFrame = CGRectMake(0.0, 0.0, kInfoViewLanscapeWidth, f.size.height);
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
    _toolbarVisible = YES;
    _toolbarHeight = showTopControls ? topToolbarFrame.size.height : 20.0;
    
    [self.menuViewDelegate targetSetTopControlsVisible:showTopControls];
    
    if (self.customController.topToolbarType == ETopToolbarTypeFloating || self.customController.topToolbarType == ETopToolbarTypeMiddleFixed)
    {
        self.customController.navBar.alpha = [self getTopToolbarAlpha];
        self.customController.navBar.frame = topToolbarFrame;
        if (self.customController.topToolbarType == ETopToolbarTypeFloating && self.customController.buttonBack)
        {
            self.customController.buttonBack.alpha = [self getMiddleToolbarAlpha];
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
     
        _toolbarVisible = NO;
        _toolbarHeight = 20.0;

        [self.menuViewDelegate targetSetTopControlsVisible:YES];

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

- (BOOL) isToolbarVisible
{
    return _toolbarVisible;
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
    if ([self isLandscapeSupported] && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        [self showTopToolbar:NO];
    }
}

- (void) clearCustomControllerIfNeeded
{
    _toolbarVisible = NO;
    _toolbarHeight = 20.0;

    if (self.customController)
    {
        [self.customController removeFromParentViewController];
        if (self.customController.navBar)
            [self.customController.navBar removeFromSuperview];
        if (self.customController.buttonBack)
            [self.customController.buttonBack removeFromSuperview];
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
    return (_hideButtons && _showFull)
        || _targetPoint.type == OATargetGPXRoute
        || _targetPoint.type == OATargetGPXEdit
        || _targetPoint.type == OATargetRouteStartSelection
        || _targetPoint.type == OATargetRouteFinishSelection
        || _targetPoint.type == OATargetImpassableRoadSelection;
}

- (void) doUpdateUI
{
    _hideButtons = (_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit || _targetPoint.type == OATargetGPXRoute || _activeTargetType == OATargetGPXEdit || _activeTargetType == OATargetGPXRoute || _targetPoint.type == OATargetRouteStartSelection || _targetPoint.type == OATargetRouteFinishSelection || _targetPoint.type == OATargetImpassableRoadSelection);
    
    self.buttonsView.hidden = _hideButtons;
    
    _buttonsCount = 3 + (_iapHelper.functionalAddons.count > 0 ? 1 : 0);
    
    if (self.customController.contentView)
        [self insertSubview:self.customController.contentView atIndex:0];
    
    if (_buttonsCount > 3)
    {
        NSInteger addonsCount = _iapHelper.functionalAddons.count;
        if (addonsCount > 1)
        {
            [self.buttonMore setImage:[UIImage imageNamed:@"three_dots.png"] forState:UIControlStateNormal];
            [self.buttonMore setTitle:OALocalizedString(@"more") forState:UIControlStateNormal];
        }
        else if (addonsCount == 1)
        {
            OAFunctionalAddon *addon = _iapHelper.singleAddon;
            
            if ((self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit) && [addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
            {
                [self.buttonMore setTitle:OALocalizedString(@"ctx_mnu_add_fav") forState:UIControlStateNormal];
                [self.buttonMore setImage:[UIImage imageNamed:@"menu_star_icon"] forState:UIControlStateNormal];
            }
            else
            {
                NSString *title = addon.titleShort;
                NSString *imageName = addon.imageName;
                [self.buttonMore setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
                [self.buttonMore setTitle:title forState:UIControlStateNormal];
            }
        }
    }
    else
    {
        _backView4.hidden = YES;
        _buttonMore.hidden = YES;
    }
        
    if (_targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking || _targetPoint.type == OATargetImpassableRoad)
    {
        [_buttonDirection setTitle:OALocalizedString(@"shared_string_dismiss") forState:UIControlStateNormal];
        [_buttonDirection setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_buttonDirection setImage:[UIImage imageNamed:@"ic_trip_removepoint"] forState:UIControlStateNormal];
        [_buttonDirection setTintColor:[UIColor redColor]];
        _buttonDirection.imageView.transform = CGAffineTransformIdentity;
    }
    else
    {
        [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];
        [_buttonDirection setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateNormal];
        [_buttonDirection setImage:[UIImage imageNamed:@"menu_direction_icon_2"] forState:UIControlStateNormal];
        [_buttonDirection setTintColor:UIColorFromRGB(0x666666)];
        _buttonDirection.imageView.transform = CGAffineTransformIdentity;
    }
    
    if (self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit)
    {
        [_buttonFavorite setTitle:OALocalizedString(@"add_waypoint_short") forState:UIControlStateNormal];
        [_buttonFavorite setImage:[UIImage imageNamed:@"add_waypoint_to_track"] forState:UIControlStateNormal];
    }
    else
    {
        if (_targetPoint.type == OATargetFavorite && ![self newItem])
            [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_edit_fav") forState:UIControlStateNormal];
        else
            [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_add_fav") forState:UIControlStateNormal];
        [_buttonFavorite setImage:[UIImage imageNamed:@"menu_star_icon"] forState:UIControlStateNormal];
    }
    
    if (_targetPoint.type != OATargetGPX && _targetPoint.type != OATargetGPXRoute)
        [self.zoomView removeFromSuperview];
    
    if (_targetPoint.type == OATargetGPXRoute)
    {
        [self updateLeftButton];
        _buttonLeft.hidden = NO;
        _imageView.hidden = YES;
    }
    else
    {
        _buttonLeft.hidden = YES;
        _imageView.hidden = NO;
    }
    
    if (self.customController)
    {
        _backViewRoute.hidden = ![self.customController hasInfoView];
        _buttonShowInfo.hidden = ![self.customController hasInfoButton];
        _buttonRoute.hidden = ![self.customController hasRouteButton];
    }
    else
    {
        _backViewRoute.hidden = _hideButtons;
        _buttonShowInfo.hidden = NO;
        _buttonRoute.hidden = NO;
    }
    
    [self updateDirectionButton];
    [self updateDescriptionLabel];
}

- (BOOL) newItem
{
    id targetObj = _targetPoint.targetObj;
    if (!targetObj)
        return NO;
    
    switch (_targetPoint.type)
    {
        case OATargetFavorite:
            if (self.customController && [self.customController isKindOfClass:[OAEditTargetViewController class]])
                return ((OAEditTargetViewController *)self.customController).newItem;
            else
                return NO;
            break;
        case OATargetGPX:
            return ((OAGPX *)targetObj).newGpx;
            break;
            
        default:
            return NO;
            break;
    }
}

- (void) updateLeftButton
{
    if (_targetPoint.type == OATargetGPXRoute)
    {
        [_buttonLeft setImage:[UIImage imageNamed:[[OAGPXRouter sharedInstance] getRouteVariantTypeIconName]] forState:UIControlStateNormal];
    }
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
            [self updateDescriptionLabel];
            
            UIColor* color = item.color;
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            _targetPoint.icon = [UIImage imageNamed:favCol.iconName];
            _imageView.image = _targetPoint.icon;
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
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (BOOL) isLandscape
{
    return DeviceScreenWidth > 470.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    _hiding = NO;
    
    [self onMenuStateChanged];
    [self applyMapInteraction:[self getVisibleHeight] animated:YES];

    [self applyTargetPoint];

    if (self.customController && [self.customController hasTopToolbar])
    {
        if ([self.customController shouldShowToolbar] || self.targetPoint.toolbarNeeded)
            [self showTopToolbar:YES];
    }
    
    if (self.customController)
    {
        if (_showFullScreen)
            [self.customController goFullScreen];
        else if (_showFull)
            [self.customController goFull];
    }
    
    if (_targetPoint.type == OATargetGPXRoute)
    {
        self.zoomView.alpha = 0.0;
        if ([self isLandscape])
            [self.parentView addSubview:self.zoomView];
        else
            [self addSubview:self.zoomView];

        //if ([self.gestureRecognizers containsObject:_panGesture])
        //    [self removeGestureRecognizer:_panGesture];
    }
    else
    {
        //if (![self.gestureRecognizers containsObject:_panGesture])
        //    [self addGestureRecognizer:_panGesture];
    }

    
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -DeviceScreenWidth;
            frame.origin.y = 20.0;
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
            if (self.zoomView.superview)
                _zoomView.alpha = 1.0;
            
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
            frame.origin.y = 20.0;
        else
            frame.origin.y = 0;
        
        self.frame = frame;
        if (self.zoomView.superview)
            _zoomView.alpha = 1.0;
        
        if (onComplete)
            onComplete();

        if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
            [self.menuViewDelegate targetViewEnableMapInteraction];
    }

    [self startLocationUpdate];
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    _hiding = YES;
    
    [self.menuViewDelegate targetSetBottomControlsVisible:YES menuHeight:0 animated:YES];

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
                
                if (self.zoomView.superview)
                    _zoomView.alpha = 0.0;

                if (showingTopToolbar)
                    self.customController.navBar.frame = newTopToolbarFrame;
                
            } completion:^(BOOL finished) {
                
                [self.zoomView removeFromSuperview];
                [self removeFromSuperview];
            
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
            
            if (self.zoomView.superview)
                _zoomView.alpha = 0.0;

            [self.zoomView removeFromSuperview];
            [self removeFromSuperview];
            
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

    [self stopLocationUpdate];
}

- (BOOL) preHide
{
    if (self.customController)
        return [self.customController preHide];
    else
        return YES;
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
    if (_zoomView.superview)
    {
        if ([self isLandscape])
            _zoomView.center = CGPointMake(DeviceScreenWidth - _zoomView.bounds.size.width / 2.0, DeviceScreenHeight / 2.0);
        else
            _zoomView.center = CGPointMake(self.frame.size.width - _zoomView.bounds.size.width / 2.0, _headerY - _zoomView.bounds.size.height / 2.0 - 5.0);
        
        BOOL showZoomView = (!_showFullScreen || [self isLandscape]) && ![self.customController supportMapInteraction];
        _zoomView.alpha = (showZoomView ? 1.0 : 0.0);
    }
    else if (!_hiding && self.customController && [self.customController supportMapInteraction])
    {
        [self applyMapInteraction:[self getVisibleHeight] animated:animated];
    }
}

- (void) layoutSubviews
{
    if (![self isSliding] && !_hiding)
        [self doLayoutSubviews:NO];
}

- (void) doLayoutSubviews
{
    [self doLayoutSubviews:YES];
}

- (CGPoint) doLayoutSubviews:(BOOL)adjustOffset
{
    BOOL landscape = [self isLandscape];
    BOOL hasVisibleToolbar = self.customController && [self.customController hasTopToolbar] && !self.customController.navBar.hidden;
    if (hasVisibleToolbar)
    {
        [self updateToolbarFrame:landscape];
    }
    CGFloat toolBarHeight = hasVisibleToolbar ? self.customController.navBar.bounds.size.height : 0.0;
    CGFloat buttonsHeight = !_hideButtons ? kOATargetPointButtonsViewHeight : 0;

    CGFloat textX = (_imageView.image || !_buttonLeft.hidden ? 50.0 : 16.0) + (_targetPoint.type == OATargetGPXRoute || _targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking ? 10.0 : 0.0);
    CGFloat width = (landscape ? kInfoViewLanscapeWidth : DeviceScreenWidth);
    
    CGFloat labelPreferredWidth = width - textX - 40.0;
    
    _addressLabel.preferredMaxLayoutWidth = labelPreferredWidth;
    _addressLabel.frame = CGRectMake(16.0, 20.0, labelPreferredWidth, 1000.0);
    [_addressLabel sizeToFit];
    
    _coordinateLabel.preferredMaxLayoutWidth = labelPreferredWidth;
    _coordinateLabel.frame = CGRectMake(16.0, _addressLabel.frame.origin.y + _addressLabel.frame.size.height + 10.0, labelPreferredWidth, 1000.0);
    [_coordinateLabel sizeToFit];

    CGFloat topViewHeight;
    if (!_descriptionLabel.hidden)
    {
        _descriptionLabel.preferredMaxLayoutWidth = labelPreferredWidth;
        _descriptionLabel.frame = CGRectMake(16.0, _coordinateLabel.frame.origin.y + _coordinateLabel.frame.size.height + 8.0, labelPreferredWidth, 1000.0);
        [_descriptionLabel sizeToFit];
        CGRect df = _descriptionLabel.frame;
        df.size.height += 14;
        _descriptionLabel.frame = df;

        topViewHeight = _descriptionLabel.frame.origin.y + _descriptionLabel.frame.size.height + 10.0;
    }
    else
    {
        topViewHeight = _coordinateLabel.frame.origin.y + _coordinateLabel.frame.size.height + 17.0;
    }
    
    CGFloat infoViewHeight = (!self.customController || [self.customController hasInfoView]) && !_hideButtons ? _backViewRoute.bounds.size.height : 0;
    //CGFloat h = topViewHeight + buttonsHeight + infoViewHeight;
    
    _topView.frame = CGRectMake(0.0, 0.0, width, topViewHeight);
    CGFloat containerViewHeight = topViewHeight + buttonsHeight + infoViewHeight;
    _containerView.frame = CGRectMake(0.0, landscape ? (toolBarHeight > 0 ? toolBarHeight : 20.0) : DeviceScreenHeight - containerViewHeight, width, containerViewHeight);
    
    //CGFloat hf = 0.0;
    
    if (self.customController && [self.customController hasContent])
    {
        /*
        CGFloat chFull;
        CGFloat chFullScreen;

        CGRect f = self.customController.contentView.frame;
        if (landscape)
        {
            if (self.customController.editing)
                chFull = MAX(DeviceScreenHeight - buttonsHeight - toolBarHeight, (self.customController.showingKeyboard ? [self.customController contentHeight] : 0.0));
            else
                chFull = DeviceScreenHeight - _headerHeight - toolBarHeight;
            
            f.size.height = chFull;
        }
        else
        {
            if (self.customController.editing)
                chFull = [self.customController contentHeight];
            else
                chFull = DeviceScreenHeight * kOATargetPointViewFullHeightKoef - h;

            chFullScreen = DeviceScreenHeight - (hasVisibleToolbar ? toolBarHeight : 20.0) - _headerHeight;

            if (_showFullScreen)
            {
                f.size.height = chFullScreen;
            }
            else
            {
                f.size.height = chFull;
            }
        }
         */
        CGRect f = self.customController.contentView.frame;
        f.size.height = MAX(DeviceScreenHeight - toolBarHeight - (containerViewHeight - topViewHeight), [self.customController contentHeight] + self.customController.keyboardSize.height);
        
        self.customController.contentView.frame = f;
        //hf = chFull;
    }
    
    //_fullInfoHeight = hf;
    //hf += _headerHeight;
    
    CGRect frame = self.frame;
    frame.size.width = width;
    /*
    if (_showFull && !landscape)
    {
        if (_showFullScreen)
        {
            frame.origin.y = (hasVisibleToolbar ? toolBarHeight : 20.0);
            
            frame.size.height = DeviceScreenHeight - frame.origin.y;
        }
        else
        {
            frame.origin.y = DeviceScreenHeight - hf;
            frame.size.height = hf;
        }
    }
    else
    {
        if (landscape)
        {
            if (self.customController && self.customController.editing)
            {
                frame.origin.y = DeviceScreenHeight - hf;
                frame.size.height = hf;
            }
            else
            {
                frame.origin.y = 20.0 + (hasVisibleToolbar ? toolBarHeight - 20.0 : 0.0);
                frame.size.height = DeviceScreenHeight - 20.0;
            }
        }
        else
        {
            frame.origin.y = DeviceScreenHeight - h;
            frame.size.height = h;
        }
    }
     */
    
    CGFloat contentViewHeight = self.customController.contentView.frame.size.height;

    _headerY = _containerView.frame.origin.y;
    _headerHeight = containerViewHeight;
    _headerOffset = 0;
    
    _fullHeight = DeviceScreenHeight * kOATargetPointViewFullHeightKoef;
    _fullOffset = _headerY - (DeviceScreenHeight - _fullHeight);
    
    _fullScreenHeight = _headerHeight + contentViewHeight;
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
    self.contentInset = UIEdgeInsetsMake(-20, 0, self.customController ? self.customController.keyboardSize.height : 0, 0);
    self.contentSize = CGSizeMake(frame.size.width, contentHeight);
    
    [self updateZoomViewFrameAnimated:YES];
    
    CGPoint newOffset;
    if (_showFullScreen)
        newOffset = {0, _fullScreenOffset};
    else if (_showFull)
        newOffset = {0, _fullOffset};
    else
        newOffset = {0, _headerOffset};
    
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
        self.customController.contentView.frame = CGRectMake(0.0, _headerY + _headerHeight, width, contentViewHeight);
    
    if (!_buttonLeft.hidden)
        _buttonShadow.frame = CGRectMake(5.0, 0.0, width - 50.0 - (_buttonLeft.frame.origin.x + _buttonLeft.frame.size.width + 5.0), 73.0);
    else
        _buttonShadow.frame = CGRectMake(0.0, 0.0, width - 50.0, 73.0);
        
    _buttonsView.frame = CGRectMake(0.0, _topView.frame.origin.y + _topView.frame.size.height, width, kOATargetPointButtonsViewHeight + infoViewHeight);

    CGFloat backViewWidth = floor(_buttonsView.frame.size.width / _buttonsCount);
    CGFloat x = 0.0;
    _backView1.frame = CGRectMake(x, 1.0, backViewWidth, kOATargetPointButtonsViewHeight - 1.0);
    x += backViewWidth + 1.0;
    _backView2.frame = CGRectMake(x, 1.0, backViewWidth, kOATargetPointButtonsViewHeight - 1.0);
    x += backViewWidth + 1.0;
    _backView3.frame = CGRectMake(x, 1.0, (_buttonsCount > 3 ? backViewWidth : _buttonsView.frame.size.width - x), kOATargetPointButtonsViewHeight - 1.0);
    
    if (_buttonsCount > 3)
    {
        x += backViewWidth + 1.0;
        _backView4.frame = CGRectMake(x, 1.0, _buttonsView.frame.size.width - x, kOATargetPointButtonsViewHeight - 1.0);
        if (_backView4.hidden)
            _backView4.hidden = NO;
        
        _buttonMore.frame = _backView4.bounds;
        if (_buttonMore.hidden)
            _buttonMore.hidden = NO;
    }
    
    _backViewRoute.frame = CGRectMake(0, _backView1.frame.origin.x + _backView1.frame.size.height + 1.0, _buttonsView.frame.size.width, kOATargetPointInfoViewHeight);
    
    _buttonFavorite.frame = _backView1.bounds;
    _buttonShare.frame = _backView2.bounds;
    _buttonDirection.frame = _backView3.bounds;
    
    _horizontalLine.frame = CGRectMake(0.0, 0.0, _buttonsView.frame.size.width, 0.5);
    _horizontalRouteLine.frame = CGRectMake(0.0, 0.0, _backViewRoute.frame.size.width, 0.5);
    
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
        _imageView.image = [UIImage imageNamed:@"map_parking_pin"];
        [_addressLabel setText:OALocalizedString(@"parking_marker")];
        [self updateAddressLabel];
        
        id d = _targetPoint.targetObj;
        if (d && [d isKindOfClass:[OADestination class]] && ((OADestination *)d).carPickupDateEnabled)
            [OADestinationCell setParkingTimerStr:_targetPoint.targetObj label:self.coordinateLabel shortText:NO];
    }
    else if (_targetPoint.type == OATargetGPXRoute)
    {
        _imageView.image = _targetPoint.icon;
        double distance = [OAGPXRouter sharedInstance].routeDoc.totalDistance;
        self.addressLabel.text = [[OsmAndApp instance] getFormattedDistance:distance];
        [self updateAddressLabel];
    }
    else
    {
        _imageView.image = _targetPoint.icon;
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
        [self updateDescriptionLabel];
    }
    
    if (_targetPoint.type == OATargetParking)
    {
        BOOL parkingAddonSingle = _iapHelper.functionalAddons.count == 1 && [_iapHelper.singleAddon.addonId isEqualToString:kId_Addon_Parking_Set];
        if (parkingAddonSingle)
            _buttonMore.enabled = NO;
    }
    else
    {
        _buttonMore.enabled = YES;
    }
    
    if (self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit)
        _buttonFavorite.enabled = (_targetPoint.type != OATargetWpt);
    //else
    //    _buttonFavorite.enabled = (_targetPoint.type != OATargetFavorite);
}

- (void) updateAddressLabel
{
    if (self.customController)
    {
        NSAttributedString *attributedTypeStr = [self.customController getAttributedTypeStr];
        if (attributedTypeStr)
        {
            [_coordinateLabel setAttributedText:attributedTypeStr];
            [_coordinateLabel setTextColor:UIColorFromRGB(0x808080)];
            return;
        }
        else
        {
            NSString *typeStr = [self.customController getTypeStr];
            NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] init];
            if (_targetPoint.titleAddress.length > 0 && ![_targetPoint.title hasPrefix:_targetPoint.titleAddress])
            {
                if (typeStr.length > 0)
                {
                    NSMutableAttributedString *typeAttrStr = [[NSMutableAttributedString alloc] initWithString:[typeStr stringByAppendingString:@": "]];
                    [typeAttrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, typeAttrStr.length)];
                    NSMutableAttributedString *addressAttrStr = [[NSMutableAttributedString alloc] initWithString:_targetPoint.titleAddress];
                    [addressAttrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:NSMakeRange(0, addressAttrStr.length)];
                    [attributedStr appendAttributedString:typeAttrStr];
                    [attributedStr appendAttributedString:addressAttrStr];
                    typeStr = [NSString stringWithFormat:@"%@: %@", typeStr, _targetPoint.titleAddress];
                }
                else
                {
                    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:_targetPoint.titleAddress]];
                    [attributedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, attributedStr.length)];
                }
            }
            else
            {
                [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:typeStr]];
                [attributedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, attributedStr.length)];
            }
            self.addressStr = [attributedStr string];
            [_coordinateLabel setAttributedText:attributedStr];
            [_coordinateLabel setTextColor:UIColorFromRGB(0x808080)];
            return;
        }
    }
    else
    {
        self.addressStr = _targetPoint.titleAddress;
    }
        
    [_coordinateLabel setText:self.addressStr];
    [_coordinateLabel setTextColor:UIColorFromRGB(0x808080)];
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
    [self.customController setContentBackgroundColor:UIColorFromRGB(0xffffff)];
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
        for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations()) {
            
            if ([OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) destination:_targetPoint.location.longitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) destination:_targetPoint.location.latitude])
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
            
            UIColor* color = [UIColor colorWithRed:favoriteLocation->getColor().r/255.0 green:favoriteLocation->getColor().g/255.0 blue:favoriteLocation->getColor().b/255.0 alpha:1.0];
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            
            _targetPoint.title = favoriteLocation->getTitle().toNSString();
            [_addressLabel setText:_targetPoint.title];
            [self updateAddressLabel];
            _targetPoint.icon = [UIImage imageNamed:favCol.iconName];
            _imageView.image = _targetPoint.icon;
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

- (IBAction) buttonFavoriteClicked:(id)sender
{
    if (self.targetPoint.type == OATargetFavorite)
    {
        self.customController.topToolbarType = ETopToolbarTypeFixed;
        [self showFullMenu];
        [self.customController activateEditing];
        return;
    }
    
    if (self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit)
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
    // http://osmand.net/go.html?lat=12.6313&lon=-7.9955&z=8&title=New+York The location was shared with you by OsmAnd
    
    UIImage *image = [self.mapView getGLScreenshot];
    
    //NSString *title = [_targetPoint.title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    
    NSString *string = [NSString stringWithFormat:kShareLinkTemplate, _targetPoint.location.latitude, _targetPoint.location.longitude, _targetPoint.zoom];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[image, string]
                                      applicationActivities:nil];
    
    activityViewController.popoverPresentationController.sourceView = self;
    activityViewController.popoverPresentationController.sourceRect = _backView2.frame;
    
    [self.navController presentViewController:activityViewController
                                     animated:YES
                                   completion:^{ }];

    [self.menuViewDelegate targetPointShare];
}

- (IBAction) buttonDirectionClicked:(id)sender
{
    [self.menuViewDelegate targetPointDirection];
}

- (IBAction) buttonMoreClicked:(id)sender
{
    NSArray *functionalAddons = _iapHelper.functionalAddons;
    if (functionalAddons.count > 1)
    {
        NSMutableArray *titles = [NSMutableArray array];
        NSMutableArray *images = [NSMutableArray array];
        
        NSInteger tag = 0;
        
        for (OAFunctionalAddon *addon in functionalAddons)
        {
            if (_targetPoint.type == OATargetParking && [addon.addonId isEqualToString:kId_Addon_Parking_Set])
                continue;
            if (_targetPoint.type == OATargetWpt && [addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                continue;

            if ((self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit) && [addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                continue;
            
            [titles addObject:addon.titleWide];
            [images addObject:addon.imageName];
            addon.tag = tag++;
        }

        NSInteger addFavActionTag = -1;
        if ((self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPX) && _targetPoint.type != OATargetFavorite)
        {
            [titles addObject:OALocalizedString(@"ctx_mnu_add_fav")];
            [images addObject:@"menu_star_icon"];
            addFavActionTag = tag++;
        }
        
        [PXAlertView showAlertWithTitle:OALocalizedString(@"other_options")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_cancel")
                            otherTitles:titles
                              otherDesc:nil
                            otherImages:images
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled)
                                 {
                                     for (OAFunctionalAddon *addon in functionalAddons)
                                         if (addon.tag == buttonIndex)
                                         {
                                             if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                                                 [self.menuViewDelegate targetPointAddWaypoint];
                                             else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set])
                                                 [self.menuViewDelegate targetPointParking];
                                             break;
                                         }
                                     if (addFavActionTag == buttonIndex)
                                     {
                                         [self addFavorite];
                                     }
                                 }
                             }];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
    {
        if (self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit)
            [self addFavorite];
        else
            [self.menuViewDelegate targetPointAddWaypoint];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_Parking_Set])
    {
        [self.menuViewDelegate targetPointParking];
    }
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
    
    if (_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit || _targetPoint.type == OATargetGPXRoute)
    {
        [self.menuViewDelegate targetGoToGPX];
    }
    else
    {
        [self.menuViewDelegate targetGoToPoint];
    }
}

- (IBAction) buttonLeftClicked:(id)sender
{
    if (_targetPoint.type == OATargetGPXRoute)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        OAGPXRouter *router = [OAGPXRouter sharedInstance];
        
        [PXAlertView showAlertWithTitle:OALocalizedString(@"est_travel_time")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_cancel")
                            otherTitles:@[OALocalizedString(@"pedestrian"), OALocalizedString(@"pedestrian"), OALocalizedString(@"m_style_bicycle"), OALocalizedString(@"m_style_car")]
                              otherDesc:@[[app getFormattedSpeed:[router getMovementSpeed:OAGPXRouteVariantPedestrianSlow] drive:YES],
                                          [app getFormattedSpeed:[router getMovementSpeed:OAGPXRouteVariantPedestrian] drive:YES],
                                          [app getFormattedSpeed:[router getMovementSpeed:OAGPXRouteVariantBicycle] drive:YES],
                                          [app getFormattedSpeed:[router getMovementSpeed:OAGPXRouteVariantCar] drive:YES]]
                            otherImages:@[@"ic_mode_pedestrian.png", @"ic_mode_pedestrian.png", @"ic_mode_bike.png", @"ic_mode_car.png"]
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled)
                                 {
                                     switch (buttonIndex)
                                     {
                                         case 0:
                                         {
                                             [OAGPXRouter sharedInstance].routeVariantType = OAGPXRouteVariantPedestrianSlow;
                                             break;
                                         }
                                         case 1:
                                         {
                                             [OAGPXRouter sharedInstance].routeVariantType = OAGPXRouteVariantPedestrian;
                                             break;
                                         }
                                         case 2:
                                         {
                                             [OAGPXRouter sharedInstance].routeVariantType = OAGPXRouteVariantBicycle;
                                             break;
                                         }
                                         case 3:
                                         {
                                             [OAGPXRouter sharedInstance].routeVariantType = OAGPXRouteVariantCar;
                                             break;
                                         }
                                         default:
                                             break;
                                     }
                                     
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [self contentChanged];
                                     });
                                 }
                             }];
    }
}

- (void) onMenuStateChanged
{
    if (_showFull || _showFullScreen)
        [_buttonShowInfo setTitle:[OALocalizedString(@"shared_string_collapse") upperCase] forState:UIControlStateNormal];
    else
        [_buttonShowInfo setTitle:[OALocalizedString(@"description") upperCase] forState:UIControlStateNormal];
}

- (void) applyMapInteraction:(CGFloat)height animated:(BOOL)animated
{
    if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
    {
        [self.menuViewDelegate targetViewEnableMapInteraction];
        [self.menuViewDelegate targetSetBottomControlsVisible:YES menuHeight:([self isLandscape] ? 0 : height) animated:animated];
    }
    else
    {
        [self.menuViewDelegate targetViewDisableMapInteraction];
        [self.menuViewDelegate targetSetBottomControlsVisible:NO menuHeight:0 animated:animated];
    }
}

- (UIStatusBarStyle) getStatusBarStyle:(BOOL)contextMenuMode defaultStyle:(UIStatusBarStyle)defaultStyle
{
    if (contextMenuMode)
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
        CGFloat c = self.contentOffset.y - 20;
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
        CGFloat a = _headerY - 20;
        CGFloat b = _headerY - self.customController.navBar.frame.size.height;
        CGFloat c = self.contentOffset.y;
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
        [self doLayoutSubviews:NO];
        [self.menuViewDelegate targetViewHeightChanged:[self getVisibleHeight] animated:YES];
    }];
}

- (void) contentChanged
{
    if (!_buttonLeft.hidden)
        [self updateLeftButton];
    
    if ((_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit || _targetPoint.type == OATargetGPXRoute) && self.customController)
    {
        _targetPoint.targetObj = [self.customController getTargetObj];
        [self updateAddressLabel];

        OAGPX *item = _targetPoint.targetObj;
        if (!item.newGpx)
            self.addressLabel.text = [item getNiceTitle];
        
        if (_targetPoint.type == OATargetGPXRoute)
        {
            double distance = [OAGPXRouter sharedInstance].routeDoc.totalDistance;
            self.addressLabel.text = [[OsmAndApp instance] getFormattedDistance:distance];
        }
    }
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
        newOffset = [self doLayoutSubviews:NO];
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
        [self.menuViewDelegate targetSetTopControlsVisible:showTopControls];
        if (!showTopControls)
            [self.menuViewDelegate targetResetCustomStatusBarStyle];
    }
    return newOffset;
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
    [self.menuViewDelegate targetHideMenu:.3 backButtonClicked:NO];
}

- (void) btnCancelPressed
{
    [self.menuViewDelegate targetHideMenu:.3 backButtonClicked:YES];
}

- (void) btnDeletePressed
{
    [self.menuViewDelegate targetHideContextPinMarker];
    [self.menuViewDelegate targetHideMenu:.3 backButtonClicked:YES];
}

- (void) addWaypoint
{
    [self.menuViewDelegate targetPointAddWaypoint];
}

- (void) updateColors
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    [_zoomView.buttonZoomIn setBackgroundImage:[UIImage imageNamed:isNight ? @"HUD_compass_bg_night" : @"HUD_compass_bg"] forState:UIControlStateNormal];
    [_zoomView.buttonZoomOut setBackgroundImage:[UIImage imageNamed:isNight ? @"HUD_compass_bg_night" : @"HUD_compass_bg"] forState:UIControlStateNormal];
}

#pragma mark - OATargetPointZoomViewDelegate

- (void) zoomInPressed
{
    if (self.menuViewDelegate)
        [self.menuViewDelegate targetZoomIn];
}

- (void) zoomOutPressed
{
    if (self.menuViewDelegate)
        [self.menuViewDelegate targetZoomOut];
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
    if (headerDist < halfDist && headerDist < fullDist)
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
        needCloseMenu = ![self isLandscape] && !_showFull && [self preHide] && !(self.customController && [self.customController supportMapInteraction]);
    
    if (needCloseMenu)
    {
        [self.menuViewDelegate targetHideContextPinMarker];
        [self.menuViewDelegate targetHideMenu:.25 backButtonClicked:NO];
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
            if (targetContentOffset->y > 0)
                [self setTargetContentOffset:newOffset withVelocity:velocity targetContentOffset:targetContentOffset];
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
        [self.menuViewDelegate targetStatusBarChanged];

    if (!_zoomView.superview)
        [self updateZoomViewFrameAnimated:NO];
}

- (BOOL) isScrollAllowed
{
    BOOL scrollDisabled = self.customController && (self.customController.showingKeyboard || (self.customController.editing && [self.customController disablePanWhileEditing]));
    
    if (!scrollDisabled)
    {
        BOOL supportFull = !self.customController || [self.customController supportFullMenu];
        BOOL supportFullScreen = !self.customController || [self.customController supportFullScreen];

        scrollDisabled = !supportFull && !supportFullScreen;
    }
    
    return !scrollDisabled;
}

@end
