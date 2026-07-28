//
//  OAPlanRouteEditingBridge.h
//  OsmAnd Maps
//
//  Created by OsmAnd on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode, PlanRoutePointData, PlanRouteGroupData, PlanRouteSegmentData, UIViewController, OASGpxFile, OAGpxWptItem, OARouteStatistics, TrackChartPoints;

@interface OAPlanRouteEditingBridge : NSObject

@property (nonatomic, copy, nullable) void (^onChange)(void);
@property (nonatomic, copy, nullable) void (^onRouteInfoChanged)(void);
@property (nonatomic, copy, nullable) void (^onPointSelected)(NSInteger index);
@property (nonatomic, copy, nullable, getter=changeRouteTypeBeforeHandler) void (^onChangeRouteTypeBefore)(NSInteger pointIndex);
@property (nonatomic, copy, nullable, getter=changeRouteTypeAfterHandler) void (^onChangeRouteTypeAfter)(NSInteger pointIndex);
@property (nonatomic, weak, nullable) UIViewController *presenterViewController;

@property (nonatomic, readonly) BOOL hasContext;
@property (nonatomic, readonly) BOOL hasPoints;
@property (nonatomic, readonly, nullable) OASGpxFile *currentGpxFile;
@property (nonatomic, readonly, nullable) OASGpxFile *exportedGpxFile;
@property (nonatomic, readonly) BOOL isAddNewSegmentAllowed;
@property (nonatomic, readonly, nullable) OAApplicationMode *defaultAppMode;
@property (nonatomic, readonly) BOOL hasChanges;
@property (nonatomic, readonly) BOOL canUndo;
@property (nonatomic, readonly) BOOL canRedo;
@property (nonatomic, readonly) BOOL hasRoute;
@property (nonatomic, readonly) double routeDistance;
@property (nonatomic, readonly) double distanceToMapCenter;
@property (nonatomic, readonly) double bearingToMapCenter;
@property (nonatomic, readonly) BOOL isCalculatingElevation;
@property (nonatomic, readonly) BOOL isCalculatingRoute;

- (NSArray<OARouteStatistics *> *)calculateRouteStatistics;
- (void)startElevationCalculationWithNearbyRoads:(BOOL)useNearbyRoads;
- (void)cancelElevationCalculation;

- (void)hideChartHighlight;
- (void)showChartHighlightedLocation:(TrackChartPoints *)points;
- (void)showChartStatisticsLocation:(TrackChartPoints *)points;

- (void)dismiss;
- (void)prepareNewRoute;
- (void)addPointAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)openTrackWithFilePath:(NSString *)filePath;
- (void)addCenterPoint;
- (void)setCrosshairScreenPoint:(CGPoint)point;
- (void)undo;
- (void)redo;
- (void)reverseRoute;
- (void)clearAllPoints;
- (void)openAddPoiWithFilePath:(nullable NSString *)filePath presentingViewController:(UIViewController *)presentingViewController;

- (NSArray<PlanRouteSegmentData *> *)buildSegments;
- (NSArray<OAGpxWptItem *> *)buildPoiItems;
- (NSArray<NSString *> *)buildPoiGroupNames;
- (NSArray<OAApplicationMode *> *)availableModes;
- (void)addPoiGroup:(NSString *)groupName NS_SWIFT_NAME(addPoiGroup(_:));
- (void)renamePoiGroupFromName:(NSString *)oldName toName:(NSString *)newName NS_SWIFT_NAME(renamePoiGroup(from:to:));
- (void)openPoiGroupAppearanceForName:(NSString *)groupName presentingViewController:(UIViewController *)presentingViewController NS_SWIFT_NAME(openPoiGroupAppearance(_:presenting:));
- (void)deletePoiGroupWithName:(NSString *)groupName NS_SWIFT_NAME(deletePoiGroup(_:));
- (void)openEditPoiPoint:(OAGpxWptItem *)point presentingViewController:(UIViewController *)presentingViewController NS_SWIFT_NAME(openEditPoiPoint(_:presenting:));
- (void)deletePoiPoint:(OAGpxWptItem *)point NS_SWIFT_NAME(deletePoiPoint(_:));

- (void)deletePointAtIndex:(NSInteger)index;
- (void)movePointFrom:(NSInteger)from to:(NSInteger)to;
- (void)reorderSegmentFrom:(NSInteger)from to:(NSInteger)to NS_SWIFT_NAME(reorderSegment(from:to:));
- (void)deleteSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes;
- (void)startNewSegment;
- (void)applyMode:(OAApplicationMode *)mode pointIndex:(NSInteger)pointIndex wholeRoute:(BOOL)wholeRoute;
- (void)applyModeAllNextFromIndex:(NSInteger)pointIndex appMode:(nullable OAApplicationMode *)appMode NS_SWIFT_NAME(applyModeAllNext(fromIndex:appMode:));
- (void)refreshRouteForMode:(OAApplicationMode *)mode NS_SWIFT_NAME(refreshRoute(for:));
- (void)clearAppMode;
- (void)sortSegmentDoorToDoorWithPointIndexes:(NSArray<NSNumber *> *)indexes;
- (void)selectPointAtIndex:(NSInteger)index;
- (void)showPointOptionsAtIndex:(NSInteger)index NS_SWIFT_NAME(showPointOptions(at:));
- (void)addPointBeforeIndex:(NSInteger)index NS_SWIFT_NAME(addPointBefore(index:));
- (void)addPointAfterIndex:(NSInteger)index NS_SWIFT_NAME(addPointAfter(index:));
- (void)trimBeforeIndex:(NSInteger)index NS_SWIFT_NAME(trimBefore(index:));
- (void)trimAfterIndex:(NSInteger)index NS_SWIFT_NAME(trimAfter(index:));

- (void)saveAs:(NSString *)fileName
        folder:(nullable NSString *)folder
     showOnMap:(BOOL)showOnMap
    onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

- (void)saveAsCopy:(NSString *)fileName
            folder:(nullable NSString *)folder
         showOnMap:(BOOL)showOnMap
        onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

- (void)saveSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes
                           fileName:(NSString *)fileName
                          showOnMap:(BOOL)showOnMap
                         onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

- (void)appendToTrack:(NSString *)filePath
           onComplete:(void (^)(BOOL success))onComplete;

- (void)enterNavigationWithTrackName:(NSString *)trackName;

@end

NS_ASSUME_NONNULL_END
