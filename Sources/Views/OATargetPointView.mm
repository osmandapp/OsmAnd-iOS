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

#import "OpeningHoursParser.h"
#include "java/util/Calendar.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>

#import <QuartzCore/QuartzCore.h>

@interface OATargetPointZoomView ()

@property (weak, nonatomic) IBOutlet UIButton *buttonZoomIn;
@property (weak, nonatomic) IBOutlet UIButton *buttonZoomOut;

@end

@implementation OATargetPointZoomView

#pragma mark - Actions

- (IBAction)buttonZoomInClicked:(id)sender
{
    if (self.delegate)
        [self.delegate zoomInPressed];
}

- (IBAction)buttonZoomOutClicked:(id)sender
{
    if (self.delegate)
        [self.delegate zoomOutPressed];
}

@end


@interface OATargetPointView() <OATargetPointZoomViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UIImageView *topImageView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *buttonLeft;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;

@property (weak, nonatomic) IBOutlet OAButton *buttonFavorite;
@property (weak, nonatomic) IBOutlet OAButton *buttonShare;
@property (weak, nonatomic) IBOutlet OAButton *buttonDirection;
@property (weak, nonatomic) IBOutlet OAButton *buttonMore;

@property (weak, nonatomic) IBOutlet UIButton *buttonShadow;
@property (weak, nonatomic) IBOutlet UIButton *buttonClose;
@property (weak, nonatomic) IBOutlet UIButton *buttonRight;

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;
@property (weak, nonatomic) IBOutlet UIView *backView4;

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
    CALayer *_verticalLine1;
    CALayer *_verticalLine2;
    CALayer *_verticalLine3;

    UIScrollView *_infoView;
    
    CALayer *_horizontalLineInfo1;
    CALayer *_horizontalLineInfo2;
    CALayer *_horizontalLineInfo3;
    CALayer *_horizontalLineInfo4;
    CALayer *_horizontalLineInfo5;
    CALayer *_horizontalLineInfo6;
    
    UIFont *_infoFont;
    
    UIImageView *_infoCoordsImage;
    UIButton *_infoCoordsText;
    UIImageView *_infoPhoneImage;
    UIButton *_infoPhoneText;
    UIImageView *_infoOpeningHoursImage;
    UIButton *_infoOpeningHoursText;
    UIImageView *_infoUrlImage;
    UIButton *_infoUrlText;

    UIImageView *_infoOperatorImage;
    UIButton *_infoOperatorText;
    UIImageView *_infoBrandImage;
    UIButton *_infoBrandText;
    UIImageView *_infoWheelchairImage;
    UIButton *_infoWheelchairText;
    UIImageView *_infoFuelImage;
    UIButton *_infoFuelText;

    UIImageView *_infoDescImage;
    UITextView *_infoDescText;
    
    CGFloat _frameTop;

    CGFloat _fullHeight;
    CGFloat _fullScreenHeight;
    CGFloat _fullInfoHeight;
    
    BOOL _hideButtons;
    BOOL _sliding;
    BOOL _toolbarAnimating;
    CGPoint _topViewStartSlidingPos;
    CGPoint _buttonsViewStartSlidingPos;
    
    UIPanGestureRecognizer *_panGesture;

    OATargetPointType _previousTargetType;
    UIImage *_previousTargetIcon;
    
    BOOL _coordsHidden;
    NSString *_formattedCoords;
    
    BOOL _toolbarVisible;
    CGFloat _toolbarHeight;
}

- (instancetype)init
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

- (instancetype)initWithFrame:(CGRect)frame
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

- (void) setupInfoButton:(UIButton *)button
{
    button.titleLabel.font = [_infoFont copy];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

-(void)awakeFromNib
{
    _iapHelper = [OAIAPHelper sharedInstance];
    
    self.buttonDirection.imageView.clipsToBounds = NO;
    self.buttonDirection.imageView.contentMode = UIViewContentModeCenter;

    _horizontalLineInfo1 = [CALayer layer];
    _horizontalLineInfo1.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo2 = [CALayer layer];
    _horizontalLineInfo2.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo3 = [CALayer layer];
    _horizontalLineInfo3.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo4 = [CALayer layer];
    _horizontalLineInfo4.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo5 = [CALayer layer];
    _horizontalLineInfo5.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo6 = [CALayer layer];
    _horizontalLineInfo6.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    
    _infoView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 100.0)];
    _infoView.backgroundColor = UIColorFromRGB(0xf2f2f2);

    [_infoView.layer addSublayer:_horizontalLineInfo1];
    [_infoView.layer addSublayer:_horizontalLineInfo2];
    [_infoView.layer addSublayer:_horizontalLineInfo3];
    [_infoView.layer addSublayer:_horizontalLineInfo4];
    [_infoView.layer addSublayer:_horizontalLineInfo5];
    [_infoView.layer addSublayer:_horizontalLineInfo6];
    
    _infoFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    _infoCoordsImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_coordinates"]];
    _infoCoordsImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoCoordsImage];

    _infoPhoneImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_phone_number"]];
    _infoPhoneImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoPhoneImage];
    
    _infoOpeningHoursImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_working_time"]];
    _infoOpeningHoursImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoOpeningHoursImage];

    _infoUrlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_website"]];
    _infoUrlImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoUrlImage];


    _infoOperatorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_operator"]];
    _infoOperatorImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoOperatorImage];

    _infoBrandImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_operator"]];
    _infoBrandImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoBrandImage];

    _infoWheelchairImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_coordinates"]];
    _infoWheelchairImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoWheelchairImage];

    _infoFuelImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_coordinates"]];
    _infoFuelImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoFuelImage];

    
    _infoDescImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_description"]];
    _infoDescImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoDescImage];
    
    _infoCoordsText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoCoordsText];
    _infoCoordsText.userInteractionEnabled = NO;
    [_infoView addSubview:_infoCoordsText];

    _infoPhoneText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoPhoneText];
    [_infoPhoneText addTarget:self action:@selector(callPhone) forControlEvents:UIControlEventTouchUpInside];
    [_infoView addSubview:_infoPhoneText];
    
    _infoOpeningHoursText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoOpeningHoursText];
    _infoOpeningHoursText.userInteractionEnabled = NO;
    [_infoView addSubview:_infoOpeningHoursText];
    
    _infoUrlText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoUrlText];
    _infoUrlText.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_infoUrlText addTarget:self action:@selector(callUrl) forControlEvents:UIControlEventTouchUpInside];
    [_infoView addSubview:_infoUrlText];
    

    _infoOperatorText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoOperatorText];
    _infoOperatorText.userInteractionEnabled = NO;
    [_infoView addSubview:_infoOperatorText];

    _infoBrandText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoBrandText];
    _infoBrandText.userInteractionEnabled = NO;
    [_infoView addSubview:_infoBrandText];

    _infoWheelchairText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoWheelchairText];
    _infoWheelchairText.userInteractionEnabled = NO;
    [_infoView addSubview:_infoWheelchairText];

    _infoFuelText = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setupInfoButton:_infoFuelText];
    _infoFuelText.userInteractionEnabled = NO;
    [_infoView addSubview:_infoFuelText];

    
    _infoDescText = [[UITextView alloc] init];
    _infoDescText.font = [_infoFont copy];
    _infoDescText.textColor = [UIColor blackColor];
    _infoDescText.backgroundColor = self.backgroundColor;
    _infoDescText.editable = NO;
    _infoDescText.selectable = NO;
    [_infoView addSubview:_infoDescText];
    
    [self doUpdateUI];

    [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_add_fav") forState:UIControlStateNormal];
    [_buttonShare setTitle:OALocalizedString(@"ctx_mnu_share") forState:UIControlStateNormal];
    [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];

    _backView4.hidden = YES;
    _buttonMore.hidden = YES;

    // drop shadow
    [_topView.layer setShadowColor:[UIColor blackColor].CGColor];
    [_topView.layer setShadowOpacity:0.3];
    [_topView.layer setShadowRadius:3.0];
    [_topView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine1 = [CALayer layer];
    _verticalLine1.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine2 = [CALayer layer];
    _verticalLine2.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine3 = [CALayer layer];
    _verticalLine3.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    
    [_buttonsView.layer addSublayer:_horizontalLine];
    [_buttonsView.layer addSublayer:_verticalLine1];
    [_buttonsView.layer addSublayer:_verticalLine2];
    [_buttonsView.layer addSublayer:_verticalLine3];
    
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
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveToolbar:)];
    //_panGesture.cancelsTouchesInView = NO;
    _panGesture.delegate = self;
    
}


- (void)startLocationUpdate
{
    if (self.locationServicesUpdateObserver)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(doLocationUpdate)
                                                                     andObserve:app.locationServices.updateObserver];
}

- (void)stopLocationUpdate
{
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

- (void)doLocationUpdate
{
    if (_targetPoint.type == OATargetParking || _targetPoint.type == OATargetDestination)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{

        // Obtain fresh location and heading
        OsmAndAppInstance app = [OsmAndApp instance];
        CLLocation* newLocation = app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;
        
        [self updateDirectionButton:newLocation.coordinate newDirection:newDirection];
        
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

- (void)updateDirectionButton
{
    if (_targetPoint.type == OATargetParking || _targetPoint.type == OATargetDestination)
    {
        self.buttonDirection.imageView.transform = CGAffineTransformIdentity;
    }
    else
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        CLLocation* newLocation = app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;
        
        [self updateDirectionButton:newLocation.coordinate newDirection:newDirection];
    }
}

- (void)updateDirectionButton:(CLLocationCoordinate2D)coordinate newDirection:(CLLocationDirection)newDirection
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

- (void)moveToolbar:(UIPanGestureRecognizer *)gesture
{
    if ([self isLandscape] || (self.customController && self.customController.showingKeyboard))
        return;
    
    if (self.customController && self.customController.editing && [self.customController disablePanWhileEditing])
        return;
    
    CGPoint translatedPoint = [gesture translationInView:self.superview];
    CGPoint translatedVelocity = [gesture velocityInView:self.superview];
    
    CGFloat h = kOATargetPointViewHeightPortrait;
    if ([self isLandscape])
        h = kOATargetPointViewHeightLandscape;
    
    if (_hideButtons)
        h -= kOATargetPointButtonsViewHeight;

    if ([gesture state] == UIGestureRecognizerStateBegan)
    {
        _sliding = YES;
        _topViewStartSlidingPos = self.frame.origin;
        _buttonsViewStartSlidingPos = _buttonsView.frame.origin;
    }
    
    if ([gesture state] == UIGestureRecognizerStateChanged)
    {
        CGRect f = self.frame;
        if ([self isLandscape] || ![self hasInfo])
        {
            f.origin.y = _topViewStartSlidingPos.y + translatedPoint.y;
            if (DeviceScreenHeight - f.origin.y > h)
                f.origin.y = DeviceScreenHeight - h;
        }
        else
        {
            f.origin.y = _topViewStartSlidingPos.y + translatedPoint.y;
            
            if (_showFullScreen && f.origin.y < _frameTop)
                f.origin.y = _frameTop;
            else if (!_showFullScreen && self.customController && [self.customController supportMapInteraction] && f.origin.y > DeviceScreenHeight - h)
                f.origin.y = DeviceScreenHeight - h;
            
            f.size.height = DeviceScreenHeight - f.origin.y;
            if (f.size.height < 0)
                f.size.height = 0;
            
            if (self.customController)
            {
                CGRect cf = self.customController.contentView.frame;
                cf.size.height = f.size.height - h;
                if (cf.size.height < 0)
                    cf.size.height = 0;
                self.customController.contentView.frame = cf;
            }
            else
            {
                CGRect cf = _infoView.frame;
                cf.size.height = f.size.height - h;
                if (cf.size.height < 0)
                    cf.size.height = 0;
                _infoView.frame = cf;
            }
        }
        
        if (![self isLandscape] && [self hasInfo] && !_hideButtons)
        {
            CGFloat by = _buttonsViewStartSlidingPos.y - translatedPoint.y * 1.3;
            if (f.size.height < h && by <= _topView.frame.origin.y + _topView.frame.size.height)
                _buttonsView.center = CGPointMake(_buttonsView.center.x, _topView.frame.origin.y + _topView.frame.size.height + _buttonsView.bounds.size.height / 2.0);
            else
                _buttonsView.center = CGPointMake(_buttonsView.center.x, f.size.height - _buttonsView.bounds.size.height / 2.0);
        }

        self.frame = f;
        
        [self updateZoomViewFrame];
        
        [self.delegate targetViewSizeChanged:f animated:NO];
    }
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed)
    {
        if (translatedVelocity.y < 200.0)
        //if (self.frame.origin.y < (DeviceScreenHeight - h - 20.0))
        {
            CGRect frame = self.frame;

            BOOL goFull = NO;
            BOOL goFullScreen = NO;
            if ([self hasInfo])
            {
                goFull = !_showFull && frame.size.height < _fullHeight;
                goFullScreen = !_showFullScreen && frame.size.height > _fullHeight && self.customController && [self.customController supportFullScreen];

                if (!goFullScreen && self.customController && ![self.customController supportFullMenu] && [self.customController supportFullScreen])
                    goFullScreen = YES;

                _showFull = YES;
                if (goFullScreen)
                {
                    _showFullScreen = YES;
                    frame.size.height = _fullScreenHeight;
                    frame.origin.y = DeviceScreenHeight - _fullScreenHeight;
                }
                else if (!_showFullScreen)
                {
                    frame.size.height = _fullHeight;
                    frame.origin.y = DeviceScreenHeight - _fullHeight;
                }
                
                if (self.customController && [self.customController hasTopToolbar] && ([self.customController shouldShowToolbar:_showFull] || self.targetPoint.toolbarNeeded))
                    [self showTopToolbar:YES];
                
                if (self.customController)
                {
                    if (goFullScreen)
                        [self.customController goFullScreen];
                    else if (goFull)
                        [self.customController goFull];
                }
                
                [self applyMapInteraction:_fullHeight];
            }
            else
            {
                _showFull = NO;
                frame.size.height = h;
                frame.origin.y = DeviceScreenHeight - h;

                if (self.customController && [self.customController hasTopToolbar] && (![self.customController shouldShowToolbar:_showFull] && !self.targetPoint.toolbarNeeded))
                    [self hideTopToolbar:YES];

                if (self.customController && !_showFull)
                    [self.customController goHeaderOnly];
                
                [self applyMapInteraction:h];
            }
            
            if (self.customController)
            {
                CGRect cf = self.customController.contentView.frame;
                cf.size.height = frame.size.height - h;
                if (cf.size.height < 0)
                    cf.size.height = 0;
                if (self.customController.contentView.frame.size.height < cf.size.height)
                    self.customController.contentView.frame = cf;
            }
            else
            {
                CGRect cf = _infoView.frame;
                cf.size.height = frame.size.height - h;
                if (cf.size.height < 0)
                    cf.size.height = 0;
                if (_infoView.frame.size.height < cf.size.height)
                    _infoView.frame = cf;
            }

            [UIView animateWithDuration:.3 animations:^{
                self.frame = frame;
                [self updateZoomViewFrame];
                [self updateButtonClose];
                if (![self isLandscape] && !_hideButtons)
                {
                    _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y - kOATargetPointButtonsViewHeight, DeviceScreenWidth, kOATargetPointButtonsViewHeight);
                }
            } completion:^(BOOL finished) {
                if (!goFull)
                {
                    _sliding = NO;
                    [self setNeedsLayout];
                }
                
            }];
            
            if (goFull)
            {
                _sliding = NO;
                [self setNeedsLayout];
            }

            [self.delegate targetViewSizeChanged:frame animated:YES];
        }
        else
        {
            if (!_showFull && self.customController && [self.customController supportMapInteraction])
                return;

            if (_showFull || translatedVelocity.y < 200.0 || ![self preHide])
            {
                CGRect frame = self.frame;

                if (_showFullScreen)
                {
                    _showFullScreen = NO;
                    _showFull = (frame.size.height > _fullHeight);
                    if (_showFull && self.customController && ![self.customController supportFullMenu])
                        _showFull = NO;
                }
                else
                {
                    _showFull = NO;
                }
                
                if (_showFull)
                {
                    frame.size.height = _fullHeight;
                    frame.origin.y = DeviceScreenHeight - _fullHeight;
                }
                else
                {
                    frame.origin.y = DeviceScreenHeight - h;
                    frame.size.height = h;
                }

                CGFloat delta = self.frame.origin.y - frame.origin.y;
                CGFloat duration = (delta > 0.0 ? .2 : fabs(delta / (translatedVelocity.y * 0.5)));
                if (duration > .2)
                    duration = .2;
                if (duration < .1)
                    duration = .1;
                
                if (self.customController && [self.customController hasTopToolbar] && (![self.customController shouldShowToolbar:_showFull] && !self.targetPoint.toolbarNeeded))
                    [self hideTopToolbar:YES];
                
                if (self.customController && !_showFull)
                    [self.customController goHeaderOnly];

                [self applyMapInteraction:(_showFull ? _fullHeight : h)];
                
                [UIView animateWithDuration:duration animations:^{
                    
                    self.frame = frame;
                    [self updateZoomViewFrame];
                    [self updateButtonClose];

                    if (![self isLandscape] && !_hideButtons)
                    {
                        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y - kOATargetPointButtonsViewHeight, DeviceScreenWidth, kOATargetPointButtonsViewHeight);
                    }
                    
                } completion:^(BOOL finished) {
                    _sliding = NO;
                    [self setNeedsLayout];
                }];
                
                [self.delegate targetViewSizeChanged:frame animated:YES];
            }
            else
            {
                CGFloat delta = self.frame.origin.y - DeviceScreenHeight;
                CGFloat duration = (delta > 0.0 ? .3 : fabs(delta / translatedVelocity.y));
                if (duration > .3)
                    duration = .3;
                
                [self.delegate targetHideMenu:duration backButtonClicked:NO];
            }
        }
    }
}

- (void)updateToolbarFrame:(BOOL)landscape
{
    if (_toolbarAnimating)
        return;
    
    BOOL useGradient = (_activeTargetType != OATargetGPX) && (_activeTargetType != OATargetGPXEdit) && !landscape;
    [self.customController useGradient:useGradient];
    
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

- (void)showTopToolbar:(BOOL)animated
{
    if (!self.customController || !self.customController.hasTopToolbar || !self.customController.navBar.hidden)
        return;

    BOOL useGradient = (_activeTargetType != OATargetGPX) && (_activeTargetType != OATargetGPXEdit) && ![self isLandscape];
    [self.customController useGradient:useGradient];

    CGRect topToolbarFrame;

    if ([self isLandscape])
    {
        CGRect f = self.customController.navBar.frame;
        self.customController.navBar.frame = CGRectMake(- kInfoViewLanscapeWidth, 0.0, kInfoViewLanscapeWidth, f.size.height);
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
    
    [self.delegate targetSetTopControlsVisible:showTopControls];
    
    if (animated)
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

- (void)hideTopToolbar:(BOOL)animated
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

        [self.delegate targetSetTopControlsVisible:YES];

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

- (BOOL)isToolbarVisible
{
    return _toolbarVisible;
}

- (CGFloat)toolbarHeight
{
    return _toolbarHeight;
}

- (void)showFullMenu
{
    if (![self hasInfo])
        return;
    
    CGRect frame = self.frame;
    
    if ([self isLandscape])
    {
        _showFull = YES;
        frame.size.height = _fullHeight;
        frame.origin.y = DeviceScreenHeight - _fullHeight;
    }
    else
    {
        _showFull = YES;
        frame.size.height = _fullHeight;
        frame.origin.y = DeviceScreenHeight - _fullHeight;
    }
    
    if ([self.customController hasTopToolbar] && ([self.customController shouldShowToolbar:_showFull] || self.targetPoint.toolbarNeeded))
        [self showTopToolbar:YES];
    
    if (self.customController)
        [self.customController goFull];
    
    [UIView animateWithDuration:.3 animations:^{
        
        self.frame = frame;
        
        if (![self isLandscape] && _hideButtons)
            _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - frame.origin.y + 1.0, _buttonsView.bounds.size.width, _buttonsView.bounds.size.height);
    }];
    
    [self.delegate targetViewSizeChanged:frame animated:YES];
}

- (void)callUrl
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[_targetPoint.url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
}

- (NSString *)stripNonDigits:(NSString *)input
{
    NSCharacterSet *doNotWant = [[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet];
    return [[input componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @""];
}

- (void)callPhone
{
    NSArray* phones = [_targetPoint.phone componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",:;."]];
    NSMutableArray *parsedPhones = [NSMutableArray array];
    for (NSString *phone in phones)
    {
        NSString *p = [self stripNonDigits:phone];
        [parsedPhones addObject:p];
    }
    
    NSMutableArray *images = [NSMutableArray array];
    for (int i = 0; i <parsedPhones.count; i++)
        [images addObject:@"ic_phone_number"];
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"make_call")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:parsedPhones
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                                 for (int i = 0; i < parsedPhones.count; i++)
                                 {
                                     if (buttonIndex == i)
                                     {
                                         NSString *p = parsedPhones[i];
                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel://" stringByAppendingString:p]]];
                                         break;
                                     }
                                 }
                         }];
    
}

- (void)prepare
{
    [self doInit:NO];
    [self doUpdateUI];
    [self doLayoutSubviews];
}

- (void)prepareNoInit
{
    [self doUpdateUI];
    [self doLayoutSubviews];
}

- (void)prepareForRotation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([self isLandscapeSupported] && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        [self showTopToolbar:NO];
    }
}

- (void)clearCustomControllerIfNeeded
{
    _toolbarVisible = NO;
    _toolbarHeight = 20.0;

    if (self.customController)
    {
        [self.customController removeFromParentViewController];
        [self.customController.navBar removeFromSuperview];
        [self.customController.contentView removeFromSuperview];
        self.customController.delegate = nil;
        _customController = nil;
        [self.navController setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)updateUIOnInit
{
    if (_targetPoint.type == OATargetGPX)
    {
        OAGPX *item = _targetPoint.targetObj;
        _buttonRight.hidden = (item.newGpx || !item);
    }
    else
    {
        _buttonRight.hidden = YES;
    }
}

- (void)doInit:(BOOL)showFull
{
    _showFull = showFull;
    _showFullScreen = NO;
    [self clearCustomControllerIfNeeded];
    [self updateUIOnInit];
}

- (void)doInit:(BOOL)showFull showFullScreen:(BOOL)showFullScreen
{
    _showFull = showFull;
    _showFullScreen = showFullScreen;
    [self clearCustomControllerIfNeeded];
    [self updateUIOnInit];
}

- (void)updateButtonClose
{
    _buttonClose.alpha = ((_hideButtons && _showFull) || (_targetPoint.type == OATargetGPXRoute) || (_targetPoint.type == OATargetGPXEdit) || (!_buttonRight.hidden) ? 0.0 : 1.0);
}

- (void)doUpdateUI
{
    _hideButtons = (_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit || _targetPoint.type == OATargetGPXRoute || _activeTargetType == OATargetGPXEdit || _activeTargetType == OATargetGPXRoute);
    self.buttonsView.hidden = _hideButtons;
    [self updateButtonClose];
    
    _buttonsCount = 3 + (_iapHelper.functionalAddons.count > 0 ? 1 : 0);
    
    if (self.customController.contentView)
    {
        [_infoView removeFromSuperview];
        [self insertSubview:self.customController.contentView atIndex:0];
    }
    else
    {
        [self insertSubview:_infoView atIndex:0];
    }
    
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
    
    if (_targetPoint.openingHours)
    {
        NetOsmandUtilOpeningHoursParser_OpeningHours *parser = [NetOsmandUtilOpeningHoursParser parseOpenedHoursWithNSString:_targetPoint.openingHours];
        JavaUtilCalendar *cal = JavaUtilCalendar_getInstance();
        BOOL isOpened = [parser isOpenedForTimeWithJavaUtilCalendar:cal];
        
        UIColor *color;
        if (isOpened)
            color = UIColorFromRGB(0x2BBE31);
        else
            color = UIColorFromRGB(0xDA3A3A);
        [_infoOpeningHoursText setTitleColor:color forState:UIControlStateNormal];
    }
    
    if (_targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking)
    {
        [_buttonDirection setTitle:OALocalizedString(@"shared_string_dismiss") forState:UIControlStateNormal];
        [_buttonDirection setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_buttonDirection setImage:[UIImage imageNamed:@"ic_trip_removepoint"] forState:UIControlStateNormal];
        [_buttonDirection setTintColor:[UIColor redColor]];
    }
    else
    {
        [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];
        [_buttonDirection setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateNormal];
        [_buttonDirection setImage:[UIImage imageNamed:@"menu_direction_icon_2"] forState:UIControlStateNormal];
        [_buttonDirection setTintColor:UIColorFromRGB(0x666666)];
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
    
    BOOL coordsHidden = (_targetPoint.titleAddress.length > 0 && [_targetPoint.title rangeOfString:_targetPoint.titleAddress].length == 0);
    
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
    
    _infoCoordsImage.hidden = !coordsHidden;
    _infoCoordsText.hidden = !coordsHidden;

    _infoPhoneImage.hidden = _targetPoint.phone == nil;
    _infoPhoneText.hidden = _targetPoint.phone == nil;
    
    _infoOpeningHoursImage.hidden = _targetPoint.openingHours == nil;
    _infoOpeningHoursText.hidden = _targetPoint.openingHours == nil;
    
    _infoUrlImage.hidden = _targetPoint.url == nil;
    _infoUrlText.hidden = _targetPoint.url == nil;

    
    _infoOperatorImage.hidden = _targetPoint.oper == nil;
    _infoOperatorText.hidden = _targetPoint.oper == nil;

    _infoBrandImage.hidden = _targetPoint.brand == nil;
    _infoBrandText.hidden = _targetPoint.brand == nil;

    _infoWheelchairImage.hidden = _targetPoint.wheelchair == nil;
    _infoWheelchairText.hidden = _targetPoint.wheelchair == nil;

    _infoFuelImage.hidden = _targetPoint.fuelTags.count == 0;
    _infoFuelText.hidden = _targetPoint.fuelTags.count == 0;

    
    _infoDescImage.hidden = _targetPoint.desc == nil;
    _infoDescText.hidden = _targetPoint.desc == nil;
    
    [self updateDirectionButton];
}

- (BOOL)newItem
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

- (void)updateLeftButton
{
    if (_targetPoint.type == OATargetGPXRoute)
    {
        [_buttonLeft setImage:[UIImage imageNamed:[[OAGPXRouter sharedInstance] getRouteVariantTypeIconName]] forState:UIControlStateNormal];
    }
}

- (BOOL)hasInfo
{
    return _coordsHidden || _targetPoint.phone || _targetPoint.openingHours || _targetPoint.url || _targetPoint.desc || (self.customController && [self.customController contentHeight] > 0.0);
}

- (void)applyTargetObjectChanges
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_targetPoint.type == OATargetWpt)
        {
            OAGpxWptItem *item = _targetPoint.targetObj;
            _targetPoint.title = item.point.name;
            [_addressLabel setText:_targetPoint.title];
            
            UIColor* color = item.color;
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            _targetPoint.icon = [UIImage imageNamed:favCol.iconName];
            _imageView.image = _targetPoint.icon;
        }
        
    });
}

- (BOOL)isLandscapeSupported
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (BOOL)isLandscape
{
    return DeviceScreenWidth > 470.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (void)show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    [self applyMapInteraction:self.frame.size.height];
    
    [self applyTargetPoint];

    if (self.customController && [self.customController hasTopToolbar])
    {
        if ([self.customController shouldShowToolbar:(_showFull || [self isLandscape])] || self.targetPoint.toolbarNeeded)
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
        [self.parentView addSubview:self.zoomView];

        if ([self.gestureRecognizers containsObject:_panGesture])
            [self removeGestureRecognizer:_panGesture];
    }
    else
    {
        if (![self.gestureRecognizers containsObject:_panGesture])
            [self addGestureRecognizer:_panGesture];
    }

    
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -self.bounds.size.width;
            frame.origin.y = 20.0 - kOATargetPointTopPanTreshold + (self.customController && self.customController.navBar.hidden == NO ? 44.0 : 0.0);
            self.frame = frame;

            frame.origin.x = 0.0;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.origin.y = DeviceScreenHeight + 10.0;
            self.frame = frame;

            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            
            self.frame = frame;
            if (self.zoomView.superview)
                _zoomView.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            if (onComplete)
                onComplete();
            
            if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
                [self.delegate targetViewEnableMapInteraction];
        }];
    }
    else
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.y = 20.0 - kOATargetPointTopPanTreshold;
        else
            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        
        self.frame = frame;
        if (self.zoomView.superview)
            _zoomView.alpha = 1.0;
        
        if (onComplete)
            onComplete();

        if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
            [self.delegate targetViewEnableMapInteraction];
    }

    [self startLocationUpdate];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [self.delegate targetSetBottomControlsVisible:YES menuHeight:0];

    if (self.superview)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.x = -frame.size.width;
        else
            frame.origin.y = DeviceScreenHeight + 10.0;

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
                
                [_infoView removeFromSuperview];
                [self.zoomView removeFromSuperview];
                [self removeFromSuperview];
            
                [self clearCustomControllerIfNeeded];
                [self restoreTargetType];

                if (onComplete)
                    onComplete();
                
                _sliding = NO;
            }];
        }
        else
        {
            self.frame = frame;
            
            if (self.zoomView.superview)
                _zoomView.alpha = 0.0;

            [_infoView removeFromSuperview];
            [self.zoomView removeFromSuperview];
            [self removeFromSuperview];
            
            [self clearCustomControllerIfNeeded];
            [self restoreTargetType];

            if (onComplete)
                onComplete();

            _sliding = NO;
        }
    }
    else
    {
        _sliding = NO;
    }

    [self stopLocationUpdate];
}

- (BOOL)preHide
{
    if (self.customController)
        return [self.customController preHide];
    else
        return YES;
}

- (UIView *)bottomMostView
{
    return self;
}

- (void)updateZoomViewFrame
{
    if (_zoomView.superview)
    {
        if ([self isLandscape])
            _zoomView.center = CGPointMake(DeviceScreenWidth - _zoomView.bounds.size.width / 2.0, DeviceScreenHeight / 2.0);
        else
            _zoomView.center = CGPointMake(DeviceScreenWidth - _zoomView.bounds.size.width / 2.0, self.frame.origin.y - (self.frame.origin.y - self.customController.navBar.frame.size.height) / 2.0);
        
        BOOL showZoomView = (!_showFullScreen || [self isLandscape]) && ![self.customController supportMapInteraction];
        _zoomView.alpha = (showZoomView ? 1.0 : 0.0);
        
    }
}

- (void)layoutSubviews
{
    if (!_sliding)
        [self doLayoutSubviews];
}

- (void)doLayoutSubviews
{
    CGFloat h = kOATargetPointViewHeightPortrait;
    BOOL landscape = [self isLandscape];
    if (landscape)
        h = kOATargetPointViewHeightLandscape;
    
    if (_hideButtons)
        h -= kOATargetPointButtonsViewHeight;
    
    if (self.customController && [self.customController hasTopToolbar] && !self.customController.navBar.hidden)
        [self updateToolbarFrame:landscape];

    _topImageView.hidden = (landscape || ![self hasInfo]);

    [self updateButtonClose];
    
    if (landscape)
        _topView.frame = CGRectMake(0.0, kOATargetPointTopPanTreshold, kInfoViewLanscapeWidth, kOATargetPointTopViewHeight);
    else
        _topView.frame = CGRectMake(0.0, kOATargetPointTopPanTreshold, DeviceScreenWidth, kOATargetPointTopViewHeight);
    
    CGFloat hf = 0.0;
    
    if (!self.customController || ![self.customController hasContent])
    {
        CGFloat infoWidth = (landscape ? kInfoViewLanscapeWidth : DeviceScreenWidth);
        
        if (_coordsHidden)
        {
            CGSize s = [OAUtilities calculateTextBounds:_formattedCoords width:infoWidth - 55.0 font:_infoFont];
            CGFloat ih = MAX(44.0, s.height + 16.0);
            
            _infoCoordsImage.frame = CGRectMake(0.0, hf, 50.0, ih);
            _infoCoordsText.frame = CGRectMake(50.0, hf, infoWidth - 55.0, ih - 1.0);
            [_infoCoordsText setTitle:_formattedCoords forState:UIControlStateNormal];
            
            hf += ih;
            
            _horizontalLineInfo4.frame = CGRectMake(15.0, hf - 1.0, infoWidth - 15.0, .5);
            _horizontalLineInfo4.hidden = NO;
        }
        else
        {
            _horizontalLineInfo4.hidden = YES;
        }
        
        if (_targetPoint.phone)
        {
            CGSize s = [OAUtilities calculateTextBounds:_targetPoint.phone width:infoWidth - 55.0 font:_infoFont];
            CGFloat ih = MAX(44.0, s.height + 16.0);
            
            _infoPhoneImage.frame = CGRectMake(0.0, hf, 50.0, ih);
            _infoPhoneText.frame = CGRectMake(50.0, hf, infoWidth - 55.0, ih - 1.0);
            [_infoPhoneText setTitle:_targetPoint.phone forState:UIControlStateNormal];
            
            hf += ih;
            
            _horizontalLineInfo1.frame = CGRectMake(15.0, hf - 1.0, infoWidth - 15.0, .5);
            _horizontalLineInfo1.hidden = NO;
        }
        else
        {
            _horizontalLineInfo1.hidden = YES;
        }
        
        if (_targetPoint.openingHours)
        {
            CGSize s = [OAUtilities calculateTextBounds:_targetPoint.openingHours width:infoWidth - 55.0 font:_infoFont];
            CGFloat ih = MAX(44.0, s.height + 16.0);
            
            _infoOpeningHoursImage.frame = CGRectMake(0.0, hf, 50.0, ih);
            _infoOpeningHoursText.frame = CGRectMake(50.0, hf, infoWidth - 55.0, ih - 1.0);
            [_infoOpeningHoursText setTitle:_targetPoint.openingHours forState:UIControlStateNormal];
            
            hf += ih;
            
            _horizontalLineInfo2.frame = CGRectMake(15.0, hf - 1.0, infoWidth - 15.0, .5);
            _horizontalLineInfo2.hidden = NO;
        }
        else
        {
            _horizontalLineInfo2.hidden = YES;
        }
        
        
        if (_targetPoint.oper)
        {
            CGSize s = [OAUtilities calculateTextBounds:_targetPoint.oper width:infoWidth - 55.0 font:_infoFont];
            CGFloat ih = MAX(44.0, s.height + 16.0);
            
            _infoOperatorImage.frame = CGRectMake(0.0, hf, 50.0, ih);
            _infoOperatorText.frame = CGRectMake(50.0, hf, infoWidth - 55.0, ih - 1.0);
            [_infoOperatorText setTitle:_targetPoint.oper forState:UIControlStateNormal];
            
            hf += ih;
            
            _horizontalLineInfo5.frame = CGRectMake(15.0, hf - 1.0, infoWidth - 15.0, .5);
            _horizontalLineInfo5.hidden = NO;
        }
        else
        {
            _horizontalLineInfo5.hidden = YES;
        }
        
        if (_targetPoint.brand)
        {
            if (!_targetPoint.oper || ![_targetPoint.oper isEqualToString:_targetPoint.brand])
            {
                CGSize s = [OAUtilities calculateTextBounds:_targetPoint.brand width:infoWidth - 55.0 font:_infoFont];
                CGFloat ih = MAX(44.0, s.height + 16.0);
                
                _infoBrandImage.frame = CGRectMake(0.0, hf, 50.0, ih);
                _infoBrandText.frame = CGRectMake(50.0, hf, infoWidth - 55.0, ih - 1.0);
                [_infoBrandText setTitle:_targetPoint.brand forState:UIControlStateNormal];
                
                hf += ih;
                
                _horizontalLineInfo6.frame = CGRectMake(15.0, hf - 1.0, infoWidth - 15.0, .5);
                _horizontalLineInfo6.hidden = NO;
            }
            else
            {
                _infoBrandImage.hidden = YES;
                _infoBrandText.hidden = YES;
                _horizontalLineInfo6.hidden = YES;
            }
        }
        else
        {
            _horizontalLineInfo6.hidden = YES;
        }
        
        
        
        if (_targetPoint.url)
        {
            CGFloat ih = 44.0;
            
            _infoUrlImage.frame = CGRectMake(0.0, hf, 50.0, ih);
            _infoUrlText.frame = CGRectMake(50.0, hf, infoWidth - 55.0, ih - 1.0);
            [_infoUrlText setTitle:_targetPoint.url forState:UIControlStateNormal];
            
            hf += ih;
            
            _horizontalLineInfo3.frame = CGRectMake(15.0, hf - 1.0, infoWidth - 15.0, .5);
            _horizontalLineInfo3.hidden = NO;
        }
        else
        {
            _horizontalLineInfo3.hidden = YES;
        }
        
        if (_targetPoint.desc)
        {
            CGFloat hText = 150.0;
            if (landscape)
                hText = 80.0;
            
            CGSize s = [OAUtilities calculateTextBounds:_targetPoint.desc width:infoWidth - 50.0 font:_infoFont];
            CGFloat ih = MAX(44.0, (s.height > 24.0 ? s.height + 36.0 : s.height + 16.0));
            
            _infoDescImage.frame = CGRectMake(0.0, hf, 50.0, ih);
            _infoDescText.frame = CGRectMake(50.0, hf, infoWidth - 50.0, ih - 1.0);
            _infoDescText.text = _targetPoint.desc;
            
            if (ih == 44.0)
                _infoDescText.contentInset = UIEdgeInsetsMake(4,-4,0,0);
            else
                _infoDescText.contentInset = UIEdgeInsetsMake(0,-4,0,0);
            
            hf += ih;
        }
        
        hf -= 1.0;
        _infoView.contentSize = CGSizeMake((landscape ? kInfoViewLanscapeWidth : DeviceScreenWidth), hf);
        hf = MIN(hf, DeviceScreenHeight * kOATargetPointViewFullHeightKoef - h);
    }
    else
    {
        CGFloat chFull;
        CGFloat chFullScreen;

        CGRect f = self.customController.contentView.frame;
        if (landscape)
        {
            if (self.customController.editing)
                chFull = MAX(DeviceScreenHeight - (_hideButtons ? 0.0 : kOATargetPointButtonsViewHeight) - ([self.customController hasTopToolbar] && !self.customController.navBar.hidden ? self.customController.navBar.bounds.size.height : 0.0), (self.customController.showingKeyboard ? [self.customController contentHeight] : 0.0));
            else
                chFull = DeviceScreenHeight - kOATargetPointViewHeightLandscape + (_hideButtons ? kOATargetPointButtonsViewHeight : 0.0) - ([self.customController hasTopToolbar] && !self.customController.navBar.hidden ? self.customController.navBar.bounds.size.height : 0.0) - kOATargetPointTopPanTreshold;
            
            f.size.height = chFull;
        }
        else
        {
            if (self.customController.editing)
                chFull = [self.customController contentHeight];
            else
                chFull = MIN([self.customController contentHeight], DeviceScreenHeight * kOATargetPointViewFullHeightKoef - h);

            chFullScreen = DeviceScreenHeight - (self.customController && self.customController.navBar.hidden == NO ? self.customController.navBar.bounds.size.height : 20.0) - kOATargetPointTopViewHeight;

            if (_showFullScreen)
            {
                f.size.height = chFullScreen;
                if (self.customController && [self.customController fullScreenWithoutHeader])
                    f.size.height += kOATargetPointTopViewHeight;
            }
            else
            {
                f.size.height = chFull;
            }
        }
    
        self.customController.contentView.frame = f;
        hf = chFull;
    }
    
    _fullInfoHeight = hf;

    hf += _topView.frame.size.height + (_hideButtons ? 0.0 : _buttonsView.frame.size.height) + kOATargetPointTopPanTreshold;
    
    CGRect frame = self.frame;
    frame.size.width = (landscape ? kInfoViewLanscapeWidth : DeviceScreenWidth);
    if (_showFull && !landscape)
    {
        if (_showFullScreen)
        {
            frame.origin.y = (self.customController && self.customController.navBar.hidden == NO ? self.customController.navBar.bounds.size.height - kOATargetPointTopPanTreshold : 20.0);
            
            if (self.customController && [self.customController fullScreenWithoutHeader])
                frame.origin.y -= kOATargetPointTopViewHeight;
            
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
                frame.origin.y = 20.0 - kOATargetPointTopPanTreshold + (self.customController && self.customController.navBar.hidden == NO ? self.customController.navBar.bounds.size.height - 20.0 : 0.0);
                frame.size.height = DeviceScreenHeight - (20.0 - kOATargetPointTopPanTreshold);
            }
        }
        else
        {
            frame.origin.y = DeviceScreenHeight - h;
            frame.size.height = h;
        }
    }

    self.frame = frame;
    
    [self updateZoomViewFrame];
    
    _frameTop = frame.origin.y;
    _fullHeight = hf;
    _fullScreenHeight = DeviceScreenHeight - (self.customController && self.customController.navBar.hidden == NO ? self.customController.navBar.bounds.size.height - kOATargetPointTopPanTreshold : 20.0);
    
    if (_imageView.image)
    {
        if (_imageView.bounds.size.width < _imageView.image.size.width ||
            _imageView.bounds.size.height < _imageView.image.size.height)
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
        else
            _imageView.contentMode = UIViewContentModeTop;
    }
    
    CGFloat textX = (_imageView.image || !_buttonLeft.hidden ? 40.0 : 16.0) + (_targetPoint.type == OATargetGPXRoute || _targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking ? 10.0 : 0.0);
    
    CGFloat width = self.frame.size.width;
    
    if (landscape)
    {
        CGFloat y = _topView.frame.origin.y + _topView.frame.size.height;
        _infoView.frame = CGRectMake(0.0, y, width, DeviceScreenHeight - y - kOATargetPointButtonsViewHeight);
        
        if (self.customController.contentView)
            self.customController.contentView.frame = CGRectMake(0.0, _topView.frame.origin.y + _topView.frame.size.height, width, self.customController.contentView.frame.size.height);
    }
    else
    {
        _infoView.frame = CGRectMake(0.0, _topView.frame.origin.y + _topView.frame.size.height, width, _fullInfoHeight);

        if (self.customController.contentView)
            self.customController.contentView.frame = CGRectMake(0.0, _topView.frame.origin.y + _topView.frame.size.height, width, self.customController.contentView.frame.size.height);
    }
    
    _addressLabel.frame = CGRectMake(textX, 3.0, width - textX - 40.0, 36.0);

    CGFloat clh = [OAUtilities calculateTextBounds:_coordinateLabel.text width:width - textX - 40.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:12.0]].height;
    if (clh < 20)
        _coordinateLabel.frame = CGRectMake(textX, 35.0, width - textX - 40.0, 30.0);
    else
        _coordinateLabel.frame = CGRectMake(textX, 35.0, width - textX - 40.0, 36.0);
    
    if (!_buttonLeft.hidden)
        _buttonShadow.frame = CGRectMake(_buttonLeft.frame.origin.x + _buttonLeft.frame.size.width + 5.0, 0.0, width - 50.0 - (_buttonLeft.frame.origin.x + _buttonLeft.frame.size.width + 5.0), 73.0);
    else
        _buttonShadow.frame = CGRectMake(0.0, 0.0, width - 50.0, 73.0);
    
    _buttonClose.frame = CGRectMake(width - 36.0, 0.0, 36.0, 36.0);
    
    if (_hideButtons)
        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y + 1.0, width, kOATargetPointButtonsViewHeight);
    else
        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y - kOATargetPointButtonsViewHeight, width, kOATargetPointButtonsViewHeight);
    
    CGFloat backViewWidth = floor(_buttonsView.frame.size.width / _buttonsCount);
    CGFloat x = 0.0;
    _backView1.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
    x += backViewWidth + 1.0;
    _backView2.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
    x += backViewWidth + 1.0;
    _backView3.frame = CGRectMake(x, 1.0, (_buttonsCount > 3 ? backViewWidth : _buttonsView.frame.size.width - x), _buttonsView.frame.size.height - 1.0);
    
    if (_buttonsCount > 3)
    {
        x += backViewWidth + 1.0;
        _backView4.frame = CGRectMake(x, 1.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height - 1.0);
        if (_backView4.hidden)
            _backView4.hidden = NO;
        
        _buttonMore.frame = _backView4.bounds;
        if (_buttonMore.hidden)
            _buttonMore.hidden = NO;
    }
    
    _buttonFavorite.frame = _backView1.bounds;
    _buttonShare.frame = _backView2.bounds;
    _buttonDirection.frame = _backView3.bounds;
    
    _horizontalLine.frame = CGRectMake(0.0, 0.0, _buttonsView.frame.size.width, 0.5);
    _verticalLine1.frame = CGRectMake(_backView2.frame.origin.x - 0.5, 0.5, 0.5, _buttonsView.frame.size.height);
    _verticalLine2.frame = CGRectMake(_backView3.frame.origin.x - 0.5, 0.5, 0.5, _buttonsView.frame.size.height);
    if (_buttonsCount > 3)
    {
        _verticalLine3.frame = CGRectMake(_backView4.frame.origin.x - 0.5, 0.5, 0.5, _buttonsView.frame.size.height);
        _verticalLine3.hidden = NO;
    }
    else
    {
        _verticalLine3.hidden = YES;
    }
}

-(void)setTargetPoint:(OATargetPoint *)targetPoint
{
    _targetPoint = targetPoint;
    _previousTargetType = targetPoint.type;
    _previousTargetIcon = targetPoint.icon;
}

-(void)updateTargetPointType:(OATargetPointType)targetType
{
    _targetPoint.type = targetType;
    [self applyTargetPoint];
}

-(void)restoreTargetType
{
    _targetPoint.toolbarNeeded = NO;

    if (_previousTargetType != _targetPoint.type && _targetPoint.type != OATargetFavorite && _targetPoint.type != OATargetWpt)
    {
        _targetPoint.type = _previousTargetType;
        _targetPoint.icon = _previousTargetIcon;
        [self applyTargetPoint];
    }
}

- (void)applyTargetPoint
{
    if (_targetPoint.type == OATargetParking)
    {
        _imageView.image = [UIImage imageNamed:@"map_parking_pin"];
        [_addressLabel setText:OALocalizedString(@"parking_marker")];
        OADestination *d = _targetPoint.targetObj;
        [self updateCoordinateLabel];
        if (d && d.carPickupDateEnabled)
            [OADestinationCell setParkingTimerStr:_targetPoint.targetObj label:self.coordinateLabel shortText:NO];
    }
    else if (_targetPoint.type == OATargetGPXRoute)
    {
        _imageView.image = _targetPoint.icon;
        double distance = [OAGPXRouter sharedInstance].routeDoc.totalDistance;
        self.addressLabel.text = [[OsmAndApp instance] getFormattedDistance:distance];
        [self updateCoordinateLabel];
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
        [self updateCoordinateLabel];
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

- (void)updateCoordinateLabel
{
    _formattedCoords = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:self.targetPoint.location];

    if (_targetPoint.titleAddress.length > 0 && [_targetPoint.title rangeOfString:_targetPoint.titleAddress].length == 0)
    {
        _coordsHidden = YES;
        self.addressStr = _targetPoint.titleAddress;
    }
    else
    {
        _coordsHidden = NO;
        self.addressStr = _formattedCoords;
    }
    
    if (self.customController)
    {
        self.customController.showCoords = _coordsHidden;
        self.customController.formattedCoords = _formattedCoords;
    }
    
    if (_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit)
    {
        OAGPX *item = _targetPoint.targetObj;
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
        UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:12];

        if (item.newGpx && item.wptPoints == 0)
        {
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:OALocalizedString(@"select_wpt_on_map")]];
        }
        else
        {
            NSMutableString *distanceStr = [[[OsmAndApp instance] getFormattedDistance:item.totalDistance] mutableCopy];
            if (item.points > 0)
                [distanceStr appendFormat:@" (%d)", item.points];
            NSString *waypointsStr = [NSString stringWithFormat:@"%d", item.wptPoints];
            NSString *timeMovingStr = [[OsmAndApp instance] getFormattedTimeInterval:item.timeMoving shortFormat:NO];
            NSString *avgSpeedStr = [[OsmAndApp instance] getFormattedSpeed:item.avgSpeed];
            
            NSMutableAttributedString *stringDistance = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", distanceStr]];
            NSMutableAttributedString *stringWaypoints = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", waypointsStr]];
            NSMutableAttributedString *stringTimeMoving;
            if (item.timeMoving > 0)
                stringTimeMoving = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", timeMovingStr]];
            NSMutableAttributedString *stringAvgSpeed;
            if (item.avgSpeed > 0)
                stringAvgSpeed =[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", avgSpeedStr]];
            
            NSTextAttachment *distanceAttachment = [[NSTextAttachment alloc] init];
            distanceAttachment.image = [UIImage imageNamed:@"ic_gpx_distance.png"];
            
            NSTextAttachment *waypointsAttachment = [[NSTextAttachment alloc] init];
            waypointsAttachment.image = [UIImage imageNamed:@"ic_gpx_points.png"];
            
            NSTextAttachment *timeMovingAttachment;
            if (item.timeMoving > 0)
            {
                timeMovingAttachment = [[NSTextAttachment alloc] init];
                timeMovingAttachment.image = [UIImage imageNamed:@"ic_travel_time.png"];
            }
            NSTextAttachment *avgSpeedAttachment;
            if (item.avgSpeed > 0)
            {
                avgSpeedAttachment = [[NSTextAttachment alloc] init];
                avgSpeedAttachment.image = [UIImage imageNamed:@"ic_average_speed.png"];
            }
            
            NSAttributedString *distanceStringWithImage = [NSAttributedString attributedStringWithAttachment:distanceAttachment];
            NSAttributedString *waypointsStringWithImage = [NSAttributedString attributedStringWithAttachment:waypointsAttachment];
            NSAttributedString *timeMovingStringWithImage;
            if (item.timeMoving > 0)
                timeMovingStringWithImage = [NSAttributedString attributedStringWithAttachment:timeMovingAttachment];
            NSAttributedString *avgSpeedStringWithImage;
            if (item.avgSpeed > 0)
                avgSpeedStringWithImage = [NSAttributedString attributedStringWithAttachment:avgSpeedAttachment];
            
            [stringDistance replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:distanceStringWithImage];
            [stringDistance addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
            [stringWaypoints replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:waypointsStringWithImage];
            [stringWaypoints addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
            if (item.timeMoving > 0)
            {
                [stringTimeMoving replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:timeMovingStringWithImage];
                [stringTimeMoving addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
            }
            if (item.avgSpeed > 0)
            {
                [stringAvgSpeed replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:avgSpeedStringWithImage];
                [stringAvgSpeed addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
            }
            
            [string appendAttributedString:stringDistance];
            [string appendAttributedString:stringWaypoints];
            if (stringTimeMoving)
                [string appendAttributedString:stringTimeMoving];
            if (stringAvgSpeed)
                [string appendAttributedString:stringAvgSpeed];
        }
        
        [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
        [_coordinateLabel setAttributedText:string];
        [_coordinateLabel setTextColor:UIColorFromRGB(0x969696)];
    }
    else if (_targetPoint.type == OATargetGPXRoute)
    {
        int wptCount = [OAGPXRouter sharedInstance].routeDoc.activePoints.count;
        NSTimeInterval tripDuration = [[OAGPXRouter sharedInstance] getRouteDuration];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
        UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:12];
        
        NSString *waypointsStr = [NSString stringWithFormat:@"%d", wptCount];
        NSString *timeMovingStr = [[OsmAndApp instance] getFormattedTimeInterval:tripDuration shortFormat:NO];
        
        NSMutableAttributedString *stringWaypoints = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", waypointsStr]];
        NSMutableAttributedString *stringTimeMoving;
        if (tripDuration > 0)
            stringTimeMoving = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@", timeMovingStr]];
        
        NSTextAttachment *waypointsAttachment = [[NSTextAttachment alloc] init];
        waypointsAttachment.image = [UIImage imageNamed:@"ic_gpx_points.png"];
        
        NSTextAttachment *timeMovingAttachment;
        if (tripDuration > 0)
        {
            NSString *imageName = [[OAGPXRouter sharedInstance] getRouteVariantTypeSmallIconName];
            timeMovingAttachment = [[NSTextAttachment alloc] init];
            timeMovingAttachment.image = [UIImage imageNamed:imageName];
        }
        
        NSAttributedString *waypointsStringWithImage = [NSAttributedString attributedStringWithAttachment:waypointsAttachment];
        NSAttributedString *timeMovingStringWithImage;
        if (tripDuration > 0)
            timeMovingStringWithImage = [NSAttributedString attributedStringWithAttachment:timeMovingAttachment];
        
        [stringWaypoints replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:waypointsStringWithImage];
        [stringWaypoints addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
        if (tripDuration > 0)
        {
            [stringTimeMoving replaceCharactersInRange:NSMakeRange(1, 1) withAttributedString:timeMovingStringWithImage];
            [stringTimeMoving addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(1, 1)];
        }
        
        [string appendAttributedString:stringWaypoints];
        if (stringTimeMoving)
            [string appendAttributedString:stringTimeMoving];
        
        [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];

        [_coordinateLabel setAttributedText:string];
        [_coordinateLabel setTextColor:UIColorFromRGB(0x969696)];
    }
    else
    {
        [_coordinateLabel setText:self.addressStr];
        [_coordinateLabel setTextColor:UIColorFromRGB(0x969696)];
    }
}

-(void)setMapViewInstance:(UIView*)mapView
{
    self.mapView = (OAMapRendererView *)mapView;
}

-(void)setNavigationController:(UINavigationController*)controller
{
    self.navController = controller;
}

-(void)setParentViewInstance:(UIView*)parentView
{
    self.parentView = parentView;
}

-(void)setCustomViewController:(OATargetMenuViewController *)customController
{
    [self clearCustomControllerIfNeeded];

    _customController = customController;
    self.customController.delegate = self;
    self.customController.navController = self.navController;
    [self.customController setContentBackgroundColor:UIColorFromRGB(0xf2f2f2)];
    
    self.customController.showCoords = (_targetPoint.titleAddress.length > 0 && [_targetPoint.title rangeOfString:_targetPoint.titleAddress].length == 0);

    if (self.superview)
    {
        [self doUpdateUI];
        [self doLayoutSubviews];
        [self showFullMenu];
    }
}

- (void)onFavoritesCollectionChanged
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
                [self.delegate targetHide];
            });
    }
}

- (void)onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    if (_targetPoint.type == OATargetFavorite)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIColor* color = [UIColor colorWithRed:favoriteLocation->getColor().r/255.0 green:favoriteLocation->getColor().g/255.0 blue:favoriteLocation->getColor().b/255.0 alpha:1.0];
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            
            _targetPoint.title = favoriteLocation->getTitle().toNSString();
            [_addressLabel setText:_targetPoint.title];
            _targetPoint.icon = [UIImage imageNamed:favCol.iconName];
            _imageView.image = _targetPoint.icon;
        });
    }
}

- (void)addFavorite
{
    NSString *locText;
    if (self.isAddressFound)
        locText = self.targetPoint.title;
    else
        locText = self.addressStr;
    
    [self.delegate targetPointAddFavorite];
}

- (void)quickHide
{
    [UIView animateWithDuration:.3 animations:^{
       
        self.alpha = 0.0;
        if (self.customController && [self.customController hasTopToolbar])
            self.customController.navBar.alpha = 0.0;
    }];
}

- (void)quickShow
{
    [UIView animateWithDuration:.3 animations:^{
        
        self.alpha = 1.0;
        if (self.customController && [self.customController hasTopToolbar])
            self.customController.navBar.alpha = 1.0;
    }];
}

#pragma mark - Actions

- (IBAction)buttonFavoriteClicked:(id)sender
{
    if (/*self.targetPoint.type == OATargetWpt ||*/ self.targetPoint.type == OATargetFavorite)
    {
        [self showFullMenu];
        [self.customController activateEditing];
        return;
    }
    
    if (self.activeTargetType == OATargetGPX || self.activeTargetType == OATargetGPXEdit)
        [self.delegate targetPointAddWaypoint];
    else
        [self addFavorite];
}

- (IBAction)buttonShareClicked:(id)sender {

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

    [self.delegate targetPointShare];
}

- (IBAction)buttonDirectionClicked:(id)sender
{
    [self.delegate targetPointDirection];
}

- (IBAction)buttonMoreClicked:(id)sender
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
                                                 [self.delegate targetPointAddWaypoint];
                                             else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set])
                                                 [self.delegate targetPointParking];
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
            [self.delegate targetPointAddWaypoint];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_Parking_Set])
    {
        [self.delegate targetPointParking];
    }
}

- (IBAction)buttonShadowClicked:(id)sender
{
    if (_showFullScreen)
        return;
    
    if (_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit || _targetPoint.type == OATargetGPXRoute)
    {
        [self.delegate targetGoToGPX];
    }
    else
    {
        [self.delegate targetGoToPoint];
    }
}

- (IBAction)buttonCloseClicked:(id)sender
{
    if ([self preHide])
        [self.delegate targetHide];
}

- (IBAction)buttonLeftClicked:(id)sender
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

- (IBAction)buttonRightClicked:(id)sender
{
    if (_targetPoint.type == OATargetGPX)
    {
        [self.delegate targetGoToGPXRoute];
    }
}

- (void)applyMapInteraction:(CGFloat)height
{
    if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
    {
        [self.delegate targetViewEnableMapInteraction];
        [self.delegate targetSetBottomControlsVisible:YES menuHeight:height];
    }
    else
    {
        [self.delegate targetViewDisableMapInteraction];
        [self.delegate targetSetBottomControlsVisible:NO menuHeight:0];
    }
}

#pragma mark
#pragma mark - OATargetMenuViewControllerDelegate

- (void) contentHeightChanged:(CGFloat)newHeight
{
    [UIView animateWithDuration:.3 animations:^{
        [self doLayoutSubviews];
        [self.delegate targetViewSizeChanged:self.frame animated:YES];
    }];
}

- (void) contentChanged
{
    if (!_buttonLeft.hidden)
        [self updateLeftButton];
    
    if ((_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit || _targetPoint.type == OATargetGPXRoute) && self.customController)
    {
        _targetPoint.targetObj = [self.customController getTargetObj];
        [self updateCoordinateLabel];

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

- (void) requestHeaderOnlyMode;
{
    if (![self isLandscape])
    {
        _showFull = NO;
        _showFullScreen = NO;

        CGFloat h = kOATargetPointViewHeightPortrait;
        if ([self isLandscape])
            h = kOATargetPointViewHeightLandscape;
        
        if (_hideButtons)
            h -= kOATargetPointButtonsViewHeight;

        if (self.customController && [self.customController hasTopToolbar] && (![self.customController shouldShowToolbar:_showFull] && !self.targetPoint.toolbarNeeded))
            [self hideTopToolbar:YES];
        
        if (self.customController)
            [self.customController goHeaderOnly];

        [self applyMapInteraction:h];
        
        [UIView animateWithDuration:.3 animations:^{
            [self doLayoutSubviews];
        }];
    }
}

- (void)requestFullScreenMode
{
    if (![self isLandscape] && !_showFullScreen)
    {
        _showFull = YES;
        _showFullScreen = YES;

        if (self.customController)
            [self.customController goFullScreen];

        [UIView animateWithDuration:.3 animations:^{
            [self doLayoutSubviews];
        }];
    }
}

- (BOOL)isInFullMode
{
    return _showFull;
}

- (BOOL)isInFullScreenMode
{
    return _showFullScreen;
}

- (void) btnOkPressed
{
    _previousTargetType = _targetPoint.type;
    _previousTargetIcon = _targetPoint.icon;
    [self.delegate targetHideMenu:.3 backButtonClicked:NO];
}

- (void) btnCancelPressed
{
    [self.delegate targetHideMenu:.3 backButtonClicked:YES];
}

- (void) btnDeletePressed
{
    [self.delegate targetHideContextPinMarker];
    [self.delegate targetHideMenu:.3 backButtonClicked:YES];
}

- (void) addWaypoint
{
    [self.delegate targetPointAddWaypoint];
}

#pragma mark - OATargetPointZoomViewDelegate

- (void) zoomInPressed
{
    if (self.delegate)
        [self.delegate targetZoomIn];
}

- (void) zoomOutPressed
{
    if (self.delegate)
        [self.delegate targetZoomOut];
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint p = [touch locationInView:self.topView];
    return p.y < _topView.frame.size.height;
}

@end
