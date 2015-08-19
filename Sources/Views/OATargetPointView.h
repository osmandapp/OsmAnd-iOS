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
#import "OATargetPoint.h"

#define kOATargetPointTopPanTreshold 16.0
#define kOATargetPointViewHeightPortrait 125.0 + kOATargetPointTopPanTreshold
#define kOATargetPointViewHeightLandscape 125.0 + kOATargetPointTopPanTreshold
#define kInfoViewLanscapeWidth 320.0
#define kOATargetPointTopViewHeight 73.0
#define kOATargetPointButtonsViewHeight 53.0
#define kOATargetPointViewFullHeightKoef 0.66

@class OATargetPoint;

@protocol OATargetPointViewDelegate;

@protocol OATargetPointZoomViewDelegate <NSObject>

-(void)zoomInPressed;
-(void)zoomOutPressed;

@end

@interface OATargetPointZoomView : UIView

@property (weak, nonatomic) id<OATargetPointZoomViewDelegate> delegate;

@end

@interface OATargetPointView : UIView<OATargetMenuViewControllerDelegate>

@property (nonatomic) OATargetPoint *targetPoint;
@property (nonatomic, assign) BOOL isAddressFound;
@property (strong, nonatomic) id<OATargetPointViewDelegate> delegate;
@property (nonatomic) OATargetMenuViewController* customController;

@property (nonatomic, assign) OATargetPointType activeTargetType;

@property (nonatomic, readonly) BOOL showFull;
@property (nonatomic, readonly) BOOL showFullScreen;

-(void)setMapViewInstance:(UIView *)mapView;
-(void)setNavigationController:(UINavigationController *)controller;
-(void)setParentViewInstance:(UIView *)parentView;
-(void)updateTargetPointType:(OATargetPointType)targetType;

-(void)setCustomViewController:(OATargetMenuViewController *)customController;

- (UIView *)bottomMostView;

- (BOOL)isLandscape;
- (BOOL)hasInfo;

- (void)doInit:(BOOL)showFull;
- (void)doInit:(BOOL)showFull showFullScreen:(BOOL)showFullScreen;
- (void)prepare;
- (void)prepareNoInit;
- (void)prepareForRotation:(UIInterfaceOrientation)toInterfaceOrientation;

- (void)showTopToolbar:(BOOL)animated;

- (void)show:(BOOL)animated onComplete:(void (^)(void))onComplete;
- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;
- (BOOL)preHide;

- (void)applyTargetObjectChanges;

- (BOOL)isToolbarVisible;
- (CGFloat)toolbarHeight;

- (void)quickHide;
- (void)quickShow;

@end


@protocol OATargetPointViewDelegate <NSObject>

-(void)targetPointAddFavorite;
-(void)targetPointShare;
-(void)targetPointDirection;

// Addons
-(void)targetPointParking;
-(void)targetPointAddWaypoint;

-(void)targetHideContextPinMarker;
-(void)targetHide;
-(void)targetHideMenu:(CGFloat)animationDuration backButtonClicked:(BOOL)backButtonClicked;
-(void)targetGoToPoint;
-(void)targetGoToGPX;
-(void)targetGoToGPXRoute;
-(void)targetViewSizeChanged:(CGRect)newFrame animated:(BOOL)animated;
-(void)targetSetTopControlsVisible:(BOOL)visible;
-(void)targetSetBottomControlsVisible:(BOOL)visible menuHeight:(CGFloat)menuHeight;

-(void)targetViewEnableMapInteraction;
-(void)targetViewDisableMapInteraction;

-(void)targetZoomIn;
-(void)targetZoomOut;

@end