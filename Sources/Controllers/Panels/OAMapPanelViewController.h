//
//  OAMapPanelViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAMapViewController.h"
#import "OACommonTypes.h"
#import "OATargetPointView.h"
#import "OAGPXRouteViewController.h"

@class OAFavoriteItem;
@class OAGpxWptItem;
@class OAGPX;
@class OADestination;
@class OAHistoryItem;

@interface OAMapPanelViewController : UIViewController<OATargetPointViewDelegate>

- (instancetype)init;

@property (nonatomic, strong, readonly) OAMapViewController* mapViewController;
@property (nonatomic, strong, readonly) UIViewController* hudViewController;

- (void)prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void)prepareMapForReuse:(UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void)doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView;

- (void)modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void)modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (BOOL)gpxModeActive;

- (void)openDestinationCardsView;
- (void)hideDestinationCardsView;
- (void)hideDestinationCardsViewAnimated:(BOOL)animated;
- (void)openHideDestinationCardsView;

- (void)hideContextMenu;

- (void)closeMapSettings;
- (void)closeMapSettingsWithDuration:(CGFloat)duration;

- (void)mapSettingsButtonClick:(id)sender;
- (void)searchButtonClick:(id)sender;

- (void)setTopControlsVisible:(BOOL)visible;
- (void)updateOverlayUnderlayView:(BOOL)show;

- (void)openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed;
- (void)openTargetViewWithFavorite:(double)lat longitude:(double)lon caption:(NSString *)caption icon:(UIImage *)icon pushed:(BOOL)pushed;
- (void)openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed;
- (void)openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu;

- (void)openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed;
- (void)openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu;
- (void)openTargetViewWithGPX:(OAGPX *)item pushed:(BOOL)pushed;

- (void)openTargetViewWithGPXEdit:(OAGPX *)item pushed:(BOOL)pushed;

- (void)openTargetViewWithGPXRoute:(BOOL)pushed;
- (void)openTargetViewWithGPXRoute:(BOOL)pushed segmentType:(OAGpxRouteSegmentType)segmentType;
- (void)openTargetViewWithGPXRoute:(OAGPX *)item pushed:(BOOL)pushed;
- (void)openTargetViewWithGPXRoute:(OAGPX *)item pushed:(BOOL)pushed segmentType:(OAGpxRouteSegmentType)segmentType;
- (void)openTargetViewWithDestination:(OADestination *)destination;

- (BOOL)hasGpxActiveTargetType;
- (void)displayGpxOnMap:(OAGPX *)item;
- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight zoom:(float)zoom;
- (BOOL)goToMyLocationIfInArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight;

- (NSString *)findRoadNameByLat:(double)lat lon:(double)lon;

@end
