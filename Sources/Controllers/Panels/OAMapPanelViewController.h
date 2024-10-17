//
//  OAMapPanelViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATargetPoint.h"
#import "OATargetPointView.h"
#import "OACommonTypes.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OATrackMenuHudViewControllerConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class OAMapViewController, OAFavoriteItem, OAGpxWptItem, OASGpxDataItem, OADestination, OAPointDescription, OAHistoryItem, OAAddress, OARTarg, OAToolbarViewController, OAMapActions, OAMapWidgetRegistry, OAMapHudViewController, OABaseScrollableHudViewController, OAApplicationMode, OASGpxFile, OASGpxTrackAnalysis, OARoutePlanningHudViewController, OATrackMenuViewControllerState, OAObservable, OARTargetPoint, OATargetMenuViewControllerState, OAPOIUIFilter, OASGpxDataItem, OASGpxFile, OASTrackItem;

@interface OAMapPanelViewController : UIViewController<OATargetPointViewDelegate>

- (instancetype) init;

@property (nonatomic, strong, readonly) OAMapViewController* mapViewController;
@property (nonatomic, strong, readonly, nullable) OAMapHudViewController* hudViewController;
@property (nonatomic, readonly, nullable) OABaseScrollableHudViewController* scrollableHudViewController;
@property (nonatomic, readonly, nullable) OABaseScrollableHudViewController* prevScrollableHudViewController;
@property (nonatomic, readonly) OAMapActions *mapActions;
@property (nonatomic, readonly) OAMapWidgetRegistry *mapWidgetRegistry;
@property (nonatomic, readonly, nullable) UIView *shadeView;

@property (nonatomic, readonly) BOOL activeTargetActive;
@property (nonatomic, readonly) OATargetPointType activeTargetType;
@property (nonatomic, readonly) id activeTargetObj;
@property (nonatomic, readonly) id activeViewControllerState;
@property (nonatomic, readonly) BOOL activeTargetChildPushed;

@property (readonly) OAObservable *weatherToolbarStateChangeObservable;

- (void) prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void) prepareMapForReuse:(nullable UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void) doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView;

- (void) modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void) modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void) showScrollableHudViewController:(OABaseScrollableHudViewController *)controller;
- (void) hideScrollableHudViewController;

- (void) showPlanRouteViewController:(OARoutePlanningHudViewController *)controller;
- (void) showRouteLineAppearanceViewController:(OABaseScrollableHudViewController *)controller;

- (BOOL) gpxModeActive;

- (void) openDestinationViewController;

- (void) swapStartAndFinish;

- (void) showContextMenuWithPoints:(NSArray<OATargetPoint *> *)targetPoints;
- (void) showContextMenu:(OATargetPoint *)targetPoint saveState:(BOOL)saveState preferredZoom:(float)preferredZoom;
- (void) showContextMenu:(OATargetPoint *)targetPoint;
- (void) updateContextMenu:(OATargetPoint *)targetPoint;
- (void) reopenContextMenu;
- (void) hideContextMenu;
- (BOOL) isContextMenuVisible;
- (BOOL) isRouteInfoVisible;
- (void) processNoSymbolFound:(CLLocationCoordinate2D)coord forceHide:(BOOL)forceHide;

- (void) closeDashboard;
- (void) closeDashboardWithDuration:(CGFloat)duration;

- (BOOL) isDashboardVisible;
- (BOOL) isTargetMultiMenuViewVisible;
- (void) closeDashboardLastScreen;
- (void) mapSettingsButtonClick:(id)sender;
- (void) mapSettingsButtonClick:(id)sender mode:(OAApplicationMode *)targetMode;
- (void) searchButtonClick:(id)sender;
- (void) showRouteInfo;
- (void) showRouteInfo:(BOOL)fullMenu;
- (void) closeRouteInfo;
- (void) closeRouteInfo:(BOOL)topControlsVisibility onComplete:(nullable void (^)(void))onComplete;
- (void) updateRouteInfo;
- (void) updateRouteInfoData;
- (void) updateTargetDescriptionLabel;
- (void) showWaypoints:(BOOL)isShowAlong;
- (void) showRoutePreferences;
- (void) showConfigureScreen;
- (void) showConfigureScreen:(OAApplicationMode *)targetMode;
- (void) showMapStylesScreen;
- (void) showWeatherLayersScreen;
- (void) showTravelGuides;
- (void) showTerrainScreen;


- (void) addWaypoint;

- (BOOL) isTopToolbarActive;
- (BOOL) isTopToolbarSearchVisible;
- (BOOL) isTopToolbarDiscountVisible;
- (BOOL) isTargetMapRulerNeeds;
- (BOOL) isTargetBackButtonVisible;
- (CGFloat) getTargetToolbarHeight;
- (CGFloat) getTargetMenuHeight;
- (CGFloat) getTargetContainerWidth;

- (BOOL) isTopControlsVisible;
- (void) targetUpdateControlsLayout:(UIStatusBarStyle)customStatusBarStyle;
- (void) updateToolbar;
- (void) updateOverlayUnderlayView;
- (BOOL) isOverlayUnderlayViewVisible;

- (BOOL)hasTopWidget;

- (nullable OATargetPoint *) getCurrentTargetPoint;

- (void) hideTargetPointMenu;

- (void) openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed;
- (void) openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed saveState:(BOOL)saveState;
- (void) openTargetViewWithAddress:(OAAddress *)address name:(NSString *)name typeName:(NSString *)typeName pushed:(BOOL)pushed preferredZoom:(float)preferredZoom;

- (void)openTargetViewWithAddress:(OAAddress *)address
                             name:(NSString *)name
                         typeName:(NSString *)typeName
                           pushed:(BOOL)pushed
                        saveState:(BOOL)saveState
                    preferredZoom:(float)preferredZoom;

- (void) openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed;
- (void) openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu;

- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed;
- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu;
- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu saveState:(BOOL)saveState;

- (void) openRecordingTrackTargetView;
- (void) openTargetViewWithGPX:(OASTrackItem *)item;
- (void) openTargetViewWithGPX:(OASTrackItem *)item selectedTab:(EOATrackMenuHudTab)selectedTab selectedStatisticsTab:(EOATrackMenuHudSegmentsStatisticsTab)selectedStatisticsTab openedFromMap:(BOOL)openedFromMap;

- (void) openTargetViewWithGPX:(OASTrackItem *)item
                  trackHudMode:(EOATrackHudMode)trackHudMode
                         state:(OATrackMenuViewControllerState *)state;

- (void)openTargetViewWithGPX:(OASTrackItem *)item
                        items:(nullable NSArray<OASGpxDataItem *> *)items
                 trackHudMode:(EOATrackHudMode)trackHudMode
                        state:(OATrackMenuViewControllerState *)state;

- (void)openTargetViewWithGPXFromTracksList:(OASTrackItem *)item
                       navControllerHistory:(NSArray<UIViewController *> *)navControllerHistory
                              fromTrackMenu:(BOOL)fromTrackMenu
                                selectedTab:(EOATrackMenuHudTab)selectedTab;

- (void) openTargetViewWithDestination:(OADestination *)destination;

- (void) openTargetViewWithRouteTargetPoint:(OARTargetPoint *)routeTargetPoint pushed:(BOOL)pushed;
- (void) openTargetViewWithRouteTargetSelection:(OATargetPointType)type;
- (void) openTargetViewWithImpassableRoad:(unsigned long long)roadId pushed:(BOOL)pushed;
- (void) openTargetViewWithImpassableRoadSelection;
- (void) openTargetViewWithRouteDetails:(nullable OASGpxFile *)gpx analysis:(nullable OASGpxTrackAnalysis *)analysis;
- (void) openTargetViewWithRouteDetailsGraph:(nullable OASGpxFile *)gpx
                                   trackItem:(nullable OASTrackItem *)trackItem
                                    analysis:(nullable OASGpxTrackAnalysis *)analysis
                            menuControlState:(OATargetMenuViewControllerState *)menuControlState;

- (void)openTargetViewWithRouteDetailsGraph:(nullable OASGpxFile *)gpx
                                  trackItem:(nullable OASTrackItem *)trackItem
                                   analysis:(OASGpxTrackAnalysis *)analysis
                           menuControlState:(OATargetMenuViewControllerState *)menuControlState
                                    isRoute:(BOOL)isRoute;

- (void) openTargetViewFromTracksListWithRouteDetailsGraph:(NSString *)gpxFilepath
                                            isCurrentTrack:(BOOL)isCurrentTrack
                                                     state:(OATrackMenuViewControllerState *)state;
- (void) openTargetViewWithMovableTarget:(OATargetPoint *)targetPoint;
- (void) openTargetViewWithNewGpxWptMovableTarget:(OASTrackItem *)gpx
                                 menuControlState:(OATargetMenuViewControllerState *)menuControlState;
- (void) openTargetViewWithTransportRouteDetails:(NSInteger)routeIndex showFullScreen:(BOOL)showFullScreeen;
- (void) openTargetViewWithDownloadMapSource:(BOOL)pushed;

- (BOOL) hasGpxActiveTargetType;

- (void) displayGpxOnMap:(OASGpxFile *)item;

- (BOOL) goToMyLocationIfInArea:(CLLocationCoordinate2D)topLeft
                    bottomRight:(CLLocationCoordinate2D)bottomRight;

- (void) displayAreaOnMap:(CLLocationCoordinate2D)topLeft
              bottomRight:(CLLocationCoordinate2D)bottomRight
                     zoom:(float)zoom
              bottomInset:(float)bottomInset
                leftInset:(float)leftInset
                 animated:(BOOL)animated;

- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft
             bottomRight:(CLLocationCoordinate2D)bottomRight
                    zoom:(float)zoom
              screenBBox:(CGSize)screenBBox
             bottomInset:(float)bottomInset
               leftInset:(float)leftInset
                topInset:(float)topInset
                animated:(BOOL)animated;

- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft
             bottomRight:(CLLocationCoordinate2D)bottomRight
                    zoom:(float)zoom
                 maxZoom:(float)maxZoom
              screenBBox:(CGSize)screenBBox
             bottomInset:(float)bottomInset
               leftInset:(float)leftInset
                topInset:(float)topInset
                animated:(BOOL)animated;

- (void) applyTargetPoint:(OATargetPoint *)targetPoint;
- (void) moveMapToLat:(double)lat lon:(double)lon zoom:(int)zoom withTitle:(NSString *)title;

- (void) showDestinations;

- (void) showToolbar:(OAToolbarViewController *)toolbarController;
- (void) hideToolbar:(OAToolbarViewController *)toolbarController;
- (void) showPoiToolbar:(OAPOIUIFilter *)filter latitude:(double)latitude longitude:(double)longitude;

- (void) openSearch;
- (void) openSearch:(nullable NSObject *)object location:(nullable CLLocation *)location;
- (void) openSearch:(OAQuickSearchType)searchType;
- (void) openSearch:(OAQuickSearchType)searchType location:(nullable CLLocation *)location tabIndex:(NSInteger)tabIndex;
- (void) openSearch:(OAQuickSearchType)searchType location:(nullable CLLocation *)location tabIndex:(NSInteger)tabIndex searchQuery:(nullable NSString *)searchQuery object:(nullable NSObject *)object;

- (void) setRouteTargetPoint:(BOOL)target intermediate:(BOOL)intermediate latitude:(double)latitude longitude:(double)longitude pointDescription:(nullable OAPointDescription *)pointDescription;

- (void) recreateAllControls;
- (void) recreateControls;
- (void) refreshMap;
- (void) refreshMap:(BOOL)redrawMap;
- (void) updateColors;

- (void) addMapMarker:(double)lat lon:(double)lon description:(NSString *)descr;

// Navigation
- (void) displayCalculatedRouteOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight;
- (void) displayCalculatedRouteOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight animated:(BOOL)animated;

- (void) buildRoute:(nullable CLLocation *)start end:(nullable CLLocation *)end appMode:(OAApplicationMode *)appMode;

- (void) onNavigationClick:(BOOL)hasTargets;
- (void) switchToRouteFollowingLayout;
- (BOOL) switchToRoutePlanningLayout;
- (void) startNavigation;
- (void) stopNavigation;

- (void) onHandleIncomingURL:(NSString *)ext;

- (void) onCarPlayConnected;
- (void) onCarPlayDisconnected:(nullable void (^)(void))onComplete;

// CarPlay
- (void) setMapViewController:(nullable OAMapViewController *)mapViewController;
- (void)detachFromCarPlayWindow;

- (void)openNewTargetViewFromTracksListWithRouteDetailsGraph:(OASTrackItem *)trackItem
                                                       state:(OATrackMenuViewControllerState *)state;


- (void)openNewTargetViewWithRouteDetailsGraph:(OASGpxFile *)gpx
                                    analysis:(OASGpxTrackAnalysis *)analysis
                            menuControlState:(OATargetMenuViewControllerState *)menuControlState
                                       isRoute:(BOOL)isRoute;

@end
 
NS_ASSUME_NONNULL_END
