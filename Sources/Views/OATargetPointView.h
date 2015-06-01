//
//  OATargetPointView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OANavigationController.h"
#import "OATargetMenuViewController.h"
#import "OAButton.h"

#define kOATargetPointTopPanTreshold 16.0
#define kOATargetPointViewHeightPortrait 125.0 + kOATargetPointTopPanTreshold
#define kOATargetPointViewHeightLandscape 125.0 + kOATargetPointTopPanTreshold
#define kInfoViewLanscapeWidth 320.0
#define kOATargetPointTopViewHeight 73.0
#define kOATargetPointViewFullHeightKoef 0.66

@class OATargetPoint;

@protocol OATargetPointViewDelegate;

@interface OATargetPointView : UIView

@property (nonatomic) OATargetPoint *targetPoint;
@property (nonatomic, assign) BOOL isAddressFound;
@property (strong, nonatomic) id<OATargetPointViewDelegate> delegate;

-(void)setMapViewInstance:(UIView *)mapView;
-(void)setNavigationController:(UINavigationController *)controller;
-(void)setParentViewInstance:(UIView *)parentView;

-(void)setCustomViewController:(OATargetMenuViewController *)customController;

- (UIView *)bottomMostView;

- (BOOL)isLandscape;
- (BOOL)hasInfo;

- (void)doInit:(BOOL)showFull;
- (void)prepare;
- (void)prepareNoInit;
- (void)prepareForRotation;

- (void)show:(BOOL)animated onComplete:(void (^)(void))onComplete;
- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;


@end


@protocol OATargetPointViewDelegate <NSObject>

-(void)targetPointAddFavorite;
-(void)targetPointShare;
-(void)targetPointDirection;

// Addons
-(void)targetPointParking;
-(void)targetPointAddWaypoint;

-(void)targetHide;
-(void)targetHideMenu:(CGFloat)animationDuration;
-(void)targetGoToPoint;
-(void)targetViewSizeChanged:(CGRect)newFrame animated:(BOOL)animated;
-(void)targetSetTopControlsVisible:(BOOL)visible;

@end