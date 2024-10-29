//
//  OATargetPointView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAScrollView.h"
#import "OATargetMenuViewController.h"
#import "OATargetPoint.h"

#define kInfoViewLanscapeWidth 320.0
#define kOATargetPointButtonsViewHeight 82.0
#define kOATargetPointInfoViewHeight 50.0
#define kOATargetPointViewFullHeightKoef 0.75

@class OAFavoriteItem, OAGpxWptItem, OASGpxDataItem;

@protocol OATargetPointViewDelegate;

@interface OATargetPointView : OAScrollView<OATargetMenuViewControllerDelegate>

@property (nonatomic) OATargetPoint *targetPoint;
@property (nonatomic, assign) BOOL isAddressFound;
@property (strong, nonatomic) id<OATargetPointViewDelegate> menuViewDelegate;
@property (nonatomic) OATargetMenuViewController* customController;

@property (nonatomic, assign) OATargetPointType activeTargetType;

@property (nonatomic, readonly) BOOL showFull;
@property (nonatomic, readonly) BOOL showFullScreen;
@property (nonatomic) BOOL skipOpenRouteSettings;

- (void) setMapViewInstance:(UIView *)mapView;
- (void) setNavigationController:(UINavigationController *)controller;
- (void) setParentViewInstance:(UIView *)parentView;
- (void) updateTargetPointType:(OATargetPointType)targetType;
- (void) updateDescriptionLabel;

- (void) setCustomViewController:(OATargetMenuViewController *)customController needFullMenu:(BOOL)needFullMenu;

- (UIView *) bottomMostView;

- (BOOL) isLandscape;

- (void) doInit:(BOOL)showFull;
- (void) doInit:(BOOL)showFull showFullScreen:(BOOL)showFullScreen;
- (void) prepare;
- (void) prepareNoInit;
- (void) prepareForRotation:(UIInterfaceOrientation)toInterfaceOrientation;
- (void) updateColors;

- (void) showTopToolbar:(BOOL)animated;

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete;
- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;
- (BOOL) preHide;

- (void) hideByMapGesture;
- (BOOL) forceHideIfSupported;
- (BOOL) needsManualContextMode;

- (void) applyTargetObjectChanges;

- (BOOL) isToolbarVisible;
- (CGFloat) toolbarHeight;

- (void) quickHide;
- (void) quickShow;

- (CGFloat) getHeaderViewY; // in screen coords
- (CGFloat) getHeaderViewHeight;
- (CGFloat) getVisibleHeight;

- (UIStatusBarStyle) getStatusBarStyle:(BOOL)contextMenuMode defaultStyle:(UIStatusBarStyle)defaultStyle;
- (BOOL) containsRef:(NSArray<OATransportStopRoute *> *)routes transportRoute:(OATransportStopRoute *)transportRoute;
- (NSMutableArray<OATransportStopRoute *> *)filterNearbyTransportRoutes:(NSArray<OATransportStopRoute *> *)routes filterFromRoutes:(NSArray<OATransportStopRoute *> *)filterFromRoutes;
- (NSMutableArray<OATransportStopRoute *> *) filterTransportRoutes:(NSArray<OATransportStopRoute *> *)routes;

@end


@protocol OATargetPointViewDelegate <NSObject>

- (void) targetPointAddFavorite;
- (void) targetPointEditFavorite:(OAFavoriteItem *)item;
- (void) targetPointShare;
- (void) targetPointDirection;

// Addons
- (void) targetPointParking;
- (void) targetPointAddWaypoint;
- (void) targetPointAddWaypoint:(NSString *)gpxFileName
                       location:(CLLocationCoordinate2D)location
                          title:(NSString *)title;
- (void) targetPointEditWaypoint:(OAGpxWptItem *)item;

- (void) targetHideContextPinMarker;
- (void) targetHide;
- (void) targetOpenRouteSettings;
- (void) targetOpenPlanRoute;
- (void) targetHideMenu:(CGFloat)animationDuration backButtonClicked:(BOOL)backButtonClicked onComplete:(void (^)(void))onComplete;
- (void) targetHideMenuByMapGesture;
- (void) targetGoToPoint;
- (void) targetGoToGPX;
- (void) targetViewHeightChanged:(CGFloat)height animated:(BOOL)animated;
- (void) targetViewOnAppear:(CGFloat)height animated:(BOOL)animated;
- (void) targetUpdateControlsLayout:(BOOL)customStatusBarStyleNeeded customStatusBarStyle:(UIStatusBarStyle)customStatusBarStyle;
- (void) targetStatusBarChanged;
- (void) targetResetRulerPosition;
- (void) targetOpenAvoidRoad;

- (void) targetViewEnableMapInteraction;
- (void) targetViewDisableMapInteraction;

- (void) targetZoomIn;
- (void) targetZoomOut;

- (void) navigate:(OATargetPoint *)targetPoint;
- (void) navigateFrom:(OATargetPoint *)targetPoint;

- (void) targetResetCustomStatusBarStyle;

@end
