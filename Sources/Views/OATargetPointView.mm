//
//  OATargetPointView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATargetPointView.h"
#import "OsmAndApp.h"
#import "OAFavoriteItemViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "PXAlertView.h"
#import "OAUtilities.h"

#import "OpeningHoursParser.h"
#include "java/util/Calendar.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>


@interface OATargetPointView()

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UIImageView *topImageView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;

@property (weak, nonatomic) IBOutlet OAButton *buttonFavorite;
@property (weak, nonatomic) IBOutlet OAButton *buttonShare;
@property (weak, nonatomic) IBOutlet OAButton *buttonDirection;
@property (weak, nonatomic) IBOutlet OAButton *buttonMore;

@property (weak, nonatomic) IBOutlet UIButton *buttonShadow;
@property (weak, nonatomic) IBOutlet UIButton *buttonClose;

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;
@property (weak, nonatomic) IBOutlet UIView *backView4;

@property NSString* formattedLocation;
@property OAMapRendererView* mapView;
@property UINavigationController* navController;
@property UIView* parentView;

@property OATargetMenuViewController* customController;

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
    
    UIFont *_infoFont;
    
    UIImageView *_infoPhoneImage;
    UIButton *_infoPhoneText;
    UIImageView *_infoOpeningHoursImage;
    UIButton *_infoOpeningHoursText;
    UIImageView *_infoUrlImage;
    UIButton *_infoUrlText;
    UIImageView *_infoDescImage;
    UITextView *_infoDescText;
    
    BOOL _showFull;
    CGFloat _fullHeight;
    CGFloat _fullInfoHeight;
    BOOL _hideButtons;
    BOOL _sliding;
    CGPoint _topViewStartSlidingPos;
    CGPoint _buttonsViewStartSlidingPos;
    
    UIPanGestureRecognizer *_panGesture;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            self.frame = frame;
        }
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
    
    _horizontalLineInfo1 = [CALayer layer];
    _horizontalLineInfo1.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo2 = [CALayer layer];
    _horizontalLineInfo2.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _horizontalLineInfo3 = [CALayer layer];
    _horizontalLineInfo3.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    
    _infoView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 100.0)];
    _infoView.backgroundColor = UIColorFromRGB(0xf2f2f2);

    [_infoView.layer addSublayer:_horizontalLineInfo1];
    [_infoView.layer addSublayer:_horizontalLineInfo2];
    [_infoView.layer addSublayer:_horizontalLineInfo3];
    
    _infoFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    _infoPhoneImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_phone_number"]];
    _infoPhoneImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoPhoneImage];
    
    _infoOpeningHoursImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_working_time"]];
    _infoOpeningHoursImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoOpeningHoursImage];

    _infoUrlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_website"]];
    _infoUrlImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoUrlImage];

    _infoDescImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_description"]];
    _infoDescImage.contentMode = UIViewContentModeCenter;
    [_infoView addSubview:_infoDescImage];
    
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
    
    _infoDescText = [[UITextView alloc] init];
    _infoDescText.font = [_infoFont copy];
    _infoDescText.textColor = [UIColor blackColor];
    _infoDescText.backgroundColor = self.backgroundColor;
    _infoDescText.editable = NO;
    _infoDescText.selectable = NO;
    [_infoView addSubview:_infoDescText];
    
    [self doUpdateUI];

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
    [self addGestureRecognizer:_panGesture];

}

- (void)moveToolbar:(UIPanGestureRecognizer *)gesture
{
    if ([self isLandscape])
        return;
    
    CGPoint translatedPoint = [gesture translationInView:self.superview];
    CGPoint translatedVelocity = [gesture velocityInView:self.superview];
    
    CGFloat h = kOATargetPointViewHeightPortrait;
    if ([self isLandscape])
        h = kOATargetPointViewHeightLandscape;

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
        
        if (![self isLandscape] && [self hasInfo])
        {
            CGFloat by = _buttonsViewStartSlidingPos.y - translatedPoint.y * 1.3;
            if (f.size.height < h && by <= _topView.frame.origin.y + _topView.frame.size.height)
                _buttonsView.center = CGPointMake(_buttonsView.center.x, _topView.frame.origin.y + _topView.frame.size.height + _buttonsView.bounds.size.height / 2.0);
            else //if (by < f.size.height - _buttonsView.bounds.size.height)
                _buttonsView.center = CGPointMake(_buttonsView.center.x, f.size.height - _buttonsView.bounds.size.height / 2.0);
            //else
            //    _buttonsView.center = CGPointMake(_buttonsView.center.x, by + _buttonsView.bounds.size.height / 2.0);
        }

        self.frame = f;
        
        [self.delegate targetViewSizeChanged:f animated:NO];
    }
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed)
    {
        if (translatedVelocity.y < 0.0)
        //if (self.frame.origin.y < (DeviceScreenHeight - h - 20.0))
        {
            CGRect frame = self.frame;

            BOOL goFull = NO;
            if ([self hasInfo])
            {
                goFull = !_showFull && frame.size.height < _fullHeight;
                _showFull = YES;
                _hideButtons = NO;
                frame.size.height = _fullHeight;
                frame.origin.y = DeviceScreenHeight - _fullHeight;
            }
            else
            {
                _showFull = NO;
                _hideButtons = NO;
                frame.size.height = h;
                frame.origin.y = DeviceScreenHeight - h;
            }
            
            [UIView animateWithDuration:.3 animations:^{
                self.frame = frame;
                if (![self isLandscape])
                {
                    if (_hideButtons)
                        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - frame.origin.y + 1.0, _buttonsView.bounds.size.width, _buttonsView.bounds.size.height);
                    else
                        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y - 53.0, DeviceScreenWidth, 53.0);
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
            if (_showFull || translatedVelocity.y < 0.0)
            {
                _showFull = NO;
                _hideButtons = NO;
                
                CGRect frame = self.frame;
                frame.origin.y = DeviceScreenHeight - h;
                frame.size.height = h;

                CGFloat delta = self.frame.origin.y - frame.origin.y;
                CGFloat duration = (delta > 0.0 ? .2 : fabs(delta / (translatedVelocity.y * 0.5)));
                if (duration > .2)
                    duration = .2;
                if (duration < .1)
                    duration = .1;
                
                [UIView animateWithDuration:duration animations:^{
                    self.frame = frame;
                    if (![self isLandscape])
                        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y - 53.0, DeviceScreenWidth, 53.0);
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
                [self.delegate targetHideMenu:duration];
            }
        }
    }
}

- (void)showFullMenu
{
    if (![self hasInfo])
        return;
    
    BOOL showTopToolbar = (self.customController && [self.customController hasTopToolbar] && self.customController.navBar.hidden);
    
    CGRect topToolbatFrame;
    
    if (showTopToolbar)
    {
        if ([self isLandscape])
        {
            CGRect f = self.customController.navBar.frame;
            self.customController.navBar.frame = CGRectMake(0.0, -f.size.height, kInfoViewLanscapeWidth, f.size.height);
            topToolbatFrame = CGRectMake(0.0, 0.0, kInfoViewLanscapeWidth, f.size.height);
        }
        else
        {
            CGRect f = self.customController.navBar.frame;
            self.customController.navBar.frame = CGRectMake(0.0, -f.size.height, DeviceScreenWidth, f.size.height);
            topToolbatFrame = CGRectMake(0.0, 0.0, DeviceScreenWidth, f.size.height);
        }
        self.customController.navBar.hidden = NO;
        [self.parentView addSubview:self.customController.navBar];
    }
    
    CGRect frame = self.frame;
    
    if ([self isLandscape])
    {
        
    }
    else
    {
        _showFull = YES;
        _hideButtons = NO;
        frame.size.height = _fullHeight;
        frame.origin.y = DeviceScreenHeight - _fullHeight;
    }
    
    [UIView animateWithDuration:.3 animations:^{
        
        self.frame = frame;
        
        if (showTopToolbar)
            self.customController.navBar.frame = topToolbatFrame;
        
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
    [self doInit];
    [self doUpdateUI];
    [self doLayoutSubviews];
}

- (void)prepareForRotation
{
    if (![self isLandscape] && [self hasInfo])
    {
        [self.parentView insertSubview:_infoView belowSubview:self];
    }
    else
    {
        [self insertSubview:_infoView atIndex:0];
    }
}

- (void)clearCustomControllerIfNeeded
{
    if (self.customController)
    {
        [self.customController.navBar removeFromSuperview];
        [self.customController.contentView removeFromSuperview];
        [self.customController setContentHeightChangeListener:nil];
        self.customController = nil;
    }
}

- (void)doInit
{
    _showFull = NO;
    [self clearCustomControllerIfNeeded];
}

- (void)doUpdateUI
{
    _hideButtons = NO;
    _buttonsCount = 3 + (_iapHelper.functionalAddons.count > 0 ? 1 : 0);
    
    if ([self isLandscape])
    {
        if (self.customController)
        {
            [_infoView removeFromSuperview];
            if (self.superview)
                [self.parentView insertSubview:self.customController.contentView belowSubview:self];
            else
                [self.parentView addSubview:self.customController.contentView];
        }
        else
        {
            if (self.superview)
                [self.parentView insertSubview:_infoView belowSubview:self];
            else
                [self.parentView addSubview:_infoView];
        }
    }
    else
    {
        if (self.customController.contentView)
        {
            [_infoView removeFromSuperview];
            [self insertSubview:self.customController.contentView atIndex:0];
        }
        else
        {
            [self insertSubview:_infoView atIndex:0];
        }
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
            NSString *title = addon.titleShort;
            NSString *imageName = addon.imageName;
            [self.buttonMore setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            [self.buttonMore setTitle:title forState:UIControlStateNormal];
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
        [_buttonDirection setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
        [_buttonDirection setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_buttonDirection setImage:[UIImage imageNamed:@"icon_remove"] forState:UIControlStateNormal];
        [_buttonDirection setTintColor:[UIColor redColor]];
    }
    else
    {
        [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];
        [_buttonDirection setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateNormal];
        [_buttonDirection setImage:[UIImage imageNamed:@"menu_direction_icon"] forState:UIControlStateNormal];
        [_buttonDirection setTintColor:UIColorFromRGB(0x666666)];
    }
    
    _infoPhoneImage.hidden = _targetPoint.phone == nil;
    _infoPhoneText.hidden = _targetPoint.phone == nil;
    
    _infoOpeningHoursImage.hidden = _targetPoint.openingHours == nil;
    _infoOpeningHoursText.hidden = _targetPoint.openingHours == nil;
    
    _infoUrlImage.hidden = _targetPoint.url == nil;
    _infoUrlText.hidden = _targetPoint.url == nil;
    
    _infoDescImage.hidden = _targetPoint.desc == nil;
    _infoDescText.hidden = _targetPoint.desc == nil;
}

- (BOOL)hasInfo
{
    return _targetPoint.phone || _targetPoint.openingHours || _targetPoint.url || _targetPoint.desc || self.customController;
}

- (BOOL)isLandscape
{
    return DeviceScreenWidth > 470.0;
}

- (void)show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -self.bounds.size.width;
            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
            self.frame = frame;

            _infoView.frame = CGRectMake(-kInfoViewLanscapeWidth, 0.0, kInfoViewLanscapeWidth, DeviceScreenHeight);

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
            if ([self isLandscape])
                _infoView.frame = CGRectMake(0.0, 0.0, kInfoViewLanscapeWidth, DeviceScreenHeight);
            
        } completion:^(BOOL finished) {
            if (onComplete)
                onComplete();
        }];
    }
    else
    {
        CGRect frame = self.frame;
        frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        self.frame = frame;
        
        if ([self isLandscape])
            _infoView.frame = CGRectMake(0.0, 0.0, kInfoViewLanscapeWidth, DeviceScreenHeight);
        
        if (onComplete)
            onComplete();
    }
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
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
                
                if (showingTopToolbar)
                    self.customController.navBar.frame = newTopToolbarFrame;
                
                if ([self isLandscape])
                    _infoView.frame = CGRectMake(-kInfoViewLanscapeWidth, 0.0, kInfoViewLanscapeWidth, DeviceScreenHeight);
                
            } completion:^(BOOL finished) {
                
                [_infoView removeFromSuperview];
                if (finished)
                    [self removeFromSuperview];
            
                [self clearCustomControllerIfNeeded];

                if (onComplete)
                    onComplete();
                
                _sliding = NO;
            }];
        }
        else
        {
            self.frame = frame;
            if ([self isLandscape])
                _infoView.frame = CGRectMake(-kInfoViewLanscapeWidth, 0.0, kInfoViewLanscapeWidth, DeviceScreenHeight);
            
            [_infoView removeFromSuperview];
            [self removeFromSuperview];
            
            [self clearCustomControllerIfNeeded];

            if (onComplete)
                onComplete();

            _sliding = NO;
        }
    }
    else
    {
        _sliding = NO;
    }
}


- (UIView *)bottomMostView
{
    if ([self isLandscape] && [self hasInfo])
        return _infoView;
    else
        return self;
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
    
    _topImageView.hidden = (landscape || ![self hasInfo]);
    
    if (landscape)
        _topView.frame = CGRectMake(0.0, kOATargetPointTopPanTreshold, kInfoViewLanscapeWidth, kOATargetPointTopViewHeight);
    else
        _topView.frame = CGRectMake(0.0, kOATargetPointTopPanTreshold, DeviceScreenWidth, kOATargetPointTopViewHeight);
    
    CGFloat hf = (landscape ? 20.0 : 0.0);
    
    if (!self.customController)
    {
        CGFloat infoWidth = (landscape ? kInfoViewLanscapeWidth : DeviceScreenWidth);
        
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
        CGRect f = self.customController.contentView.frame;
        if (landscape)
            f.size.height = DeviceScreenHeight - kOATargetPointViewHeightLandscape - ([self.customController hasTopToolbar] ? self.customController.navBar.bounds.size.height : 0.0);
        else
            f.size.height = MIN([self.customController contentHeight], DeviceScreenHeight * kOATargetPointViewFullHeightKoef - h);
    
        self.customController.contentView.frame = f;
        hf = f.size.height;
    }
    
    _fullInfoHeight = hf;

    hf += _topView.frame.size.height + _buttonsView.frame.size.height + kOATargetPointTopPanTreshold;
    
    CGRect frame = self.frame;
    frame.size.width = (landscape ? kInfoViewLanscapeWidth : DeviceScreenWidth);
    if (_showFull && !landscape)
    {
        frame.origin.y = DeviceScreenHeight - hf;
        frame.size.height = hf;
    }
    else
    {
        frame.origin.y = DeviceScreenHeight - h;
        frame.size.height = h;
    }

    self.frame = frame;
    
    _fullHeight = hf;
    
    if (_imageView.image)
    {
        if (_imageView.bounds.size.width < _imageView.image.size.width ||
            _imageView.bounds.size.height < _imageView.image.size.height)
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
        else
            _imageView.contentMode = UIViewContentModeTop;
    }
    
    CGFloat textX = (_imageView.image ? 40.0 : 16.0) + (_targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking ? 10.0 : 0.0);
    
    CGFloat width = self.frame.size.width;
    
    if (landscape)
    {
        _infoView.frame = CGRectMake(0.0, 0.0, kInfoViewLanscapeWidth, DeviceScreenHeight);
        
        if (self.customController)
            self.customController.contentView.frame = CGRectMake(0.0, ([self.customController hasTopToolbar] ? self.customController.navBar.bounds.size.height : 0.0), kInfoViewLanscapeWidth, self.customController.contentView.frame.size.height);
    }
    else
    {
        _infoView.frame = CGRectMake(0.0, _topView.frame.origin.y + _topView.frame.size.height, width, _fullInfoHeight);

        if (self.customController.contentView)
            self.customController.contentView.frame = CGRectMake(0.0, _topView.frame.origin.y + _topView.frame.size.height, width, self.customController.contentView.frame.size.height);
    }
    
    _addressLabel.frame = CGRectMake(textX, 3.0, width - textX - 40.0, 36.0);
    _coordinateLabel.frame = CGRectMake(textX, 39.0, width - textX - 40.0, 21.0);
    
    _buttonShadow.frame = CGRectMake(0.0, 0.0, width - 50.0, 73.0);
    _buttonClose.frame = CGRectMake(width - 36.0, 0.0, 36.0, 36.0);
    
    if (_hideButtons)
        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y + 1.0, width, 53.0);
    else
        _buttonsView.frame = CGRectMake(0.0, DeviceScreenHeight - self.frame.origin.y - 53.0, width, 53.0);
    
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

    _imageView.image = _targetPoint.icon;
    [_addressLabel setText:_targetPoint.title];
    self.formattedLocation = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:self.targetPoint.location];
    [_coordinateLabel setText:self.formattedLocation];
    
    //_buttonDirection.enabled = _targetPoint.type != OATargetDestination;
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

    if (_targetPoint.type == OATargetFavorite)
        [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_edit_fav") forState:UIControlStateNormal];
    else
        [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_add_fav") forState:UIControlStateNormal];
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

    self.customController = customController;
    [self.customController setContentBackgroundColor:UIColorFromRGB(0xf2f2f2)];
    
    OATargetPointView * __weak weakSelf = self;
    [self.customController setContentHeightChangeListener:^(CGFloat newHeight) {
        [UIView animateWithDuration:.3 animations:^{
            [weakSelf doLayoutSubviews];
            [weakSelf.delegate targetViewSizeChanged:weakSelf.frame animated:YES];
        }];
    }];

    [self doUpdateUI];
    [self doLayoutSubviews];
    [self showFullMenu];
}

- (void)onFavoritesCollectionChanged
{
    if (_targetPoint.type == OATargetFavorite)
    {
        BOOL favoriteOnTarget = NO;
        for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations()) {
            
            int favLon = (int)(OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) * 10000.0);
            int favLat = (int)(OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) * 10000.0);
            
            if ((int)(_targetPoint.location.latitude * 10000.0) == favLat && (int)(_targetPoint.location.longitude * 10000.0) == favLon)
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

#pragma mark - Actions
- (IBAction)buttonFavoriteClicked:(id)sender {
    
    NSString *locText;
    if (self.isAddressFound)
        locText = self.targetPoint.title;
    else
        locText = self.formattedLocation;
    
    OAFavoriteItemViewController* favoriteViewController;
    if (_targetPoint.type == OATargetFavorite)
    {
        for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
        {
            int favLon = (int)(OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) * 10000.0);
            int favLat = (int)(OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) * 10000.0);
            
            if ((int)(_targetPoint.location.latitude * 10000.0) == favLat && (int)(_targetPoint.location.longitude * 10000.0) == favLon)
            {
                OAFavoriteItem* item = [[OAFavoriteItem alloc] init];
                item.favorite = favLoc;
                favoriteViewController = [[OAFavoriteItemViewController alloc] initWithFavoriteItem:item];
                break;
            }
        }
    }
    else
    {
        favoriteViewController = [[OAFavoriteItemViewController alloc] initWithLocation:self.targetPoint.location
                                                                               andTitle:locText];
    }
    
    if (favoriteViewController)
    {
        [self.navController pushViewController:favoriteViewController animated:YES];

        /*
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            // For iPhone and iPod, push menu to navigation controller
            [self.navController pushViewController:favoriteViewController animated:YES];
        }
        else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            // For iPad, open menu in a popover with it's own navigation controller
            UINavigationController* navigationController = [[OANavigationController alloc] initWithRootViewController:favoriteViewController];
            UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
            
            [popoverController presentPopoverFromRect:CGRectMake(_targetPoint.touchPoint.x, _targetPoint.touchPoint.y, 0.0f, 0.0f)
                                               inView:self.mapView
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
        }
         */
    }
    
    [self.delegate targetPointAddFavorite];
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
        
        for (OAFunctionalAddon *addon in functionalAddons)
        {
            if (_targetPoint.type == OATargetParking && [addon.addonId isEqualToString:kId_Addon_Parking_Set])
                continue;

            [titles addObject:addon.titleWide];
            [images addObject:addon.imageName];
        }
        
        [PXAlertView showAlertWithTitle:OALocalizedString(@"other_options")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_cancel")
                            otherTitles:titles
                            otherImages:images
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled)
                                     for (OAFunctionalAddon *addon in functionalAddons)
                                         if (addon.sortIndex == buttonIndex)
                                         {
                                             if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                                                 [self.delegate targetPointAddWaypoint];
                                             else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set])
                                                 [self.delegate targetPointParking];
                                             break;
                                         }
                             }];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
    {
        [self.delegate targetPointAddWaypoint];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_Parking_Set])
    {
        [self.delegate targetPointParking];
    }
}

- (IBAction)buttonShadowClicked:(id)sender
{
    [self.delegate targetGoToPoint];
}

- (IBAction)buttonCloseClicked:(id)sender
{
    [self.delegate targetHide];
}

@end
