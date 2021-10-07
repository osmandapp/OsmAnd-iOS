//
//  OAMapPanelViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAMapViewController.h"
#import "OATargetPointView.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OABaseTrackMenuHudViewController.h"

@class OAFavoriteItem;
@class OAGpxWptItem;
@class OAGPX;
@class OADestination, OAPointDescription;
@class OAHistoryItem, OAAddress, OARTargetPoint;
@class OAToolbarViewController;
@class OAMapActions, OAMapWidgetRegistry;
@class OAMapHudViewController, OABaseScrollableHudViewController, OAApplicationMode;
@class OAGPXDocument, OAGPXTrackAnalysis;

@protocol OATrackMenuViewControllerDelegate;

@interface OAMapPanelViewController : UIViewController<OATargetPointViewDelegate>

- (instancetype) init;

@property (nonatomic, strong, readonly) OAMapViewController* mapViewController;
@property (nonatomic, strong, readonly) OAMapHudViewController* hudViewController;
@property (nonatomic, readonly) OABaseScrollableHudViewController* scrollableHudViewController;
@property (nonatomic, readonly) OAMapActions *mapActions;
@property (nonatomic, readonly) OAMapWidgetRegistry *mapWidgetRegistry;
@property (nonatomic, readonly) UIView *shadeView;

@property (nonatomic, readonly) BOOL activeTargetActive;
@property (nonatomic, readonly) OATargetPointType activeTargetType;
@property (nonatomic, readonly) id activeTargetObj;
@property (nonatomic, readonly) id activeViewControllerState;
@property (nonatomic, readonly) BOOL activeTargetChildPushed;

- (void) prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void) prepareMapForReuse:(UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void) doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView;

- (void) modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void) modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void) showScrollableHudViewController:(OABaseScrollableHudViewController *)controller;
- (void) hideScrollableHudViewController;

- (BOOL) gpxModeActive;

- (void) destinationsAdded;
- (void) openDestinationCardsView;
- (void) hideDestinationCardsView;
- (void) hideDestinationCardsViewAnimated:(BOOL)animated;
- (void) openHideDestinationCardsView;

- (void) swapStartAndFinish;

- (void) showContextMenuWithPoints:(NSArray<OATargetPoint *> *)targetPoints;
- (void) showContextMenu:(OATargetPoint *)targetPoint saveState:(BOOL)saveState;
- (void) showContextMenu:(OATargetPoint *)targetPoint;
- (void) updateContextMenu:(OATargetPoint *)targetPoint;
- (void) reopenContextMenu;
- (void) hideContextMenu;
- (BOOL) isContextMenuVisible;
- (BOOL) isRouteInfoVisible;
- (void) processNoSymbolFound:(CLLocationCoordinate2D)coord forceHide:(BOOL)forceHide;

- (void) closeDashboard;
- (void) closeDashboardWithDuration:(CGFloat)duration;

- (void) mapSettingsButtonClick:(id)sender;
- (void) mapSettingsButtonClick:(id)sender mode:(OAApplicationMode *)targetMode;
- (void) searchButtonClick:(id)sender;
- (void) showRouteInfo;
- (void) showRouteInfo:(BOOL)fullMenu;
- (void) closeRouteInfo;
- (void) closeRouteInfo:(void (^)(void))onComplete;
- (void) updateRouteInfo;
- (void) showWaypoints;
- (void) showRoutePreferences;
- (void) showConfigureScreen;
- (void) showConfigureScreen:(OAApplicationMode *)targetMode;
- (void) setBottomControlsVisible:(BOOL)visible menuHeight:(CGFloat)menuHeight animated:(BOOL)animated;
- (void) showMapStylesScreen;

- (void) addWaypoint;

- (BOOL) isTopToolbarActive;

- (BOOL) isTopControlsVisible;
- (void) setTopControlsVisible:(BOOL)visible;
- (void) setTopControlsVisible:(BOOL)visible customStatusBarStyle:(UIStatusBarStyle)customStatusBarStyle;
- (void) updateToolbar;
- (void) updateOverlayUnderlayView;
- (BOOL) isOverlayUnderlayViewVisible;

- (OATargetPoint *) getCurrentTargetPoint;

- (void) hideTargetPointMenu;

- (void) openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed;
- (void) openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed saveState:(BOOL)saveState;
- (void) openTargetViewWithAddress:(OAAddress *)address name:(NSString *)name typeName:(NSString *)typeName pushed:(BOOL)pushed;
- (void) openTargetViewWithAddress:(OAAddress *)address name:(NSString *)name typeName:(NSString *)typeName pushed:(BOOL)pushed saveState:(BOOL)saveState;
- (void) openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed;
- (void) openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu;

- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed;
- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu;
- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu saveState:(BOOL)saveState;

- (void) openTrackAppearance:(OAGPX *)item
          trackMenuDelegate:(id<OATrackMenuViewControllerDelegate>)trackMenuDelegate;

- (void) openTargetViewWithGPX:(OAGPX *)item;
- (void) openTargetViewWithGPX:(OAGPX *)item trackHudMode:(EOATrackHudMode)trackHudMode tab:(EOATrackMenuHudTab)tab;

- (void) openTargetViewWithDestination:(OADestination *)destination;

- (void) openTargetViewWithRouteTargetPoint:(OARTargetPoint *)routeTargetPoint pushed:(BOOL)pushed;
- (void) openTargetViewWithRouteTargetSelection:(OATargetPointType)type;
- (void) openTargetViewWithImpassableRoad:(unsigned long long)roadId pushed:(BOOL)pushed;
- (void) openTargetViewWithImpassableRoadSelection;
- (void) openTargetViewWithRouteDetails:(OAGPXDocument *)gpx analysis:(OAGPXTrackAnalysis *)analysis;
- (void)openTargetViewWithRouteDetailsGraph:(OAGPXDocument *)gpx analysis:(OAGPXTrackAnalysis *)analysis trackMenuDelegate:(id<OATrackMenuViewControllerDelegate>)trackMenuDelegate modeType:(EOARouteStatisticsMode)modeType;
- (void) openTargetViewWithMovableTarget:(OATargetPoint *)targetPoint;
- (void) openTargetViewWithTransportRouteDetails:(NSInteger)routeIndex showFullScreen:(BOOL)showFullScreeen;
- (void) openTargetViewWithDownloadMapSource:(BOOL)pushed;

- (BOOL) hasGpxActiveTargetType;
- (void) displayGpxOnMap:(OAGPX *)item;
- (void) displayAreaOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight zoom:(float)zoom bottomInset:(float)bottomInset leftInset:(float)leftInset;
- (void) displayAreaOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight zoom:(float)zoom screenBBox:(CGSize)screenBBox bottomInset:(float)bottomInset leftInset:(float)leftInset topInset:(float)topInset;
- (BOOL) goToMyLocationIfInArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight;

- (void) applyTargetPoint:(OATargetPoint *)targetPoint;

- (void) showCards;

- (void) showToolbar:(OAToolbarViewController *)toolbarController;
- (void) hideToolbar:(OAToolbarViewController *)toolbarController;
- (void) showPoiToolbar:(OAPOIUIFilter *)filter latitude:(double)latitude longitude:(double)longitude;

- (void) openSearch;
- (void) openSearch:(NSObject *)object location:(CLLocation *)location;
- (void) openSearch:(OAQuickSearchType)searchType;
- (void) openSearch:(OAQuickSearchType)searchType location:(CLLocation *)location tabIndex:(NSInteger)tabIndex;
- (void) openSearch:(OAQuickSearchType)searchType location:(CLLocation *)location tabIndex:(NSInteger)tabIndex searchQuery:(NSString *)searchQuery object:(NSObject *)object;

- (void) setRouteTargetPoint:(BOOL)target intermediate:(BOOL)intermediate latitude:(double)latitude longitude:(double)longitude pointDescription:(OAPointDescription *)pointDescription;

- (void) recreateControls;
- (void) refreshMap;
- (void) refreshMap:(BOOL)redrawMap;
- (void) updateColors;

- (void) addMapMarker:(double)lat lon:(double)lon description:(NSString *)descr;

// Navigation
- (void) displayCalculatedRouteOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight;
- (void) displayCalculatedRouteOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight animated:(BOOL)animated;

- (void) onNavigationClick:(BOOL)hasTargets;
- (void) switchToRouteFollowingLayout;
- (BOOL) switchToRoutePlanningLayout;
- (void) startNavigation;
- (void) stopNavigation;

- (void) refreshToolbar;

- (void) onHandleIncomingURL:(NSString *)ext;

- (void) onCarPlayConnected;
- (void) onCarPlayDisconnected:(void (^ __nullable)(void))onComplete;

// CarPlay
- (void) setMapViewController:(OAMapViewController * _Nullable)mapViewController;

@end
