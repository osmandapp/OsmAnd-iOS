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

typedef NS_ENUM(NSInteger, EOAPlanRouteShowAlongType) {
    EOAPlanRouteShowAlongTypePoi = 0,
    EOAPlanRouteShowAlongTypeFavorites,
    EOAPlanRouteShowAlongTypeTrafficWarnings
};

@interface OAPlanRouteShowAlongSettingsBridge : NSObject

- (instancetype)initWithApplicationMode:(OAApplicationMode *)applicationMode;
- (BOOL)isEnabledForType:(EOAPlanRouteShowAlongType)type;
- (void)setEnabled:(BOOL)enabled forType:(EOAPlanRouteShowAlongType)type;

@end

typedef NS_ENUM(NSInteger, EOAPlanRoutePointEditMode) {
    EOAPlanRoutePointEditModeMove = 0,
    EOAPlanRoutePointEditModeAddBefore,
    EOAPlanRoutePointEditModeAddAfter
};

@interface OAPlanRouteEditingBridge : NSObject

@property (nonatomic, copy, nullable) void (^onChange)(void);
@property (nonatomic, copy, nullable) void (^onRouteInfoChanged)(void);
@property (nonatomic, copy, nullable) void (^onNewSegmentStarted)(void);
@property (nonatomic, copy, nullable) void (^onPointEditModeRequested)(EOAPlanRoutePointEditMode mode);
@property (nonatomic, copy, nullable, getter=changeRouteTypeBeforeHandler) void (^onChangeRouteTypeBefore)(NSInteger pointIndex);
@property (nonatomic, copy, nullable, getter=changeRouteTypeAfterHandler) void (^onChangeRouteTypeAfter)(NSInteger pointIndex);
@property (nonatomic, weak, nullable) UIViewController *presenterViewController;

@property (nonatomic, readonly) BOOL hasPoints;
@property (nonatomic, readonly, nullable) OASGpxFile *currentGpxFile;
@property (nonatomic, readonly, nullable) OASGpxFile *exportedGpxFile;
@property (nonatomic, readonly) BOOL isAddNewSegmentAllowed;
@property (nonatomic, readonly, nullable) OAApplicationMode *defaultAppMode;
@property (nonatomic, readonly) BOOL isTrackReadyToCalculate;
@property (nonatomic, readonly) BOOL shouldShowApproximationWarning;
@property (nonatomic, readonly, nullable) UIViewController *approximationWarningViewController;
@property (nonatomic, readonly) BOOL hasChanges;
@property (nonatomic, readonly) BOOL canUndo;
@property (nonatomic, readonly) BOOL canRedo;
@property (nonatomic, readonly) BOOL hasRoute;
@property (nonatomic, readonly) double routeDistance;
@property (nonatomic, readonly) NSTimeInterval routeDuration;
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
- (void)prepareNewRouteWithApplicationMode:(OAApplicationMode *)applicationMode;
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
- (void)addPoiGroup:(NSString *)groupName;
- (void)renamePoiGroupFromName:(NSString *)oldName toName:(NSString *)newName;
- (void)openPoiGroupAppearanceForName:(NSString *)groupName presentingViewController:(UIViewController *)presentingViewController;
- (void)deletePoiGroupWithName:(NSString *)groupName;
- (void)openEditPoiPoint:(OAGpxWptItem *)point presentingViewController:(UIViewController *)presentingViewController;
- (void)deletePoiPoint:(OAGpxWptItem *)point;

- (void)deletePointAtIndex:(NSInteger)index;
- (void)movePointFrom:(NSInteger)from to:(NSInteger)to;
- (void)reorderSegmentFrom:(NSInteger)from to:(NSInteger)to;
- (void)deleteSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes;
- (void)startNewSegment;
- (void)applyMode:(OAApplicationMode *)mode pointIndex:(NSInteger)pointIndex wholeRoute:(BOOL)wholeRoute;
- (void)refreshRouteForMode:(OAApplicationMode *)mode;
- (void)sortSegmentDoorToDoorWithPointIndexes:(NSArray<NSNumber *> *)indexes;
- (void)selectPointAtIndex:(NSInteger)index;
- (void)showPointOptionsAtIndex:(NSInteger)index;
- (void)addPointBeforeIndex:(NSInteger)index;
- (void)addPointAfterIndex:(NSInteger)index;
- (void)trimBeforeIndex:(NSInteger)index;
- (void)trimAfterIndex:(NSInteger)index;
- (void)applyPointEdit;
- (void)cancelPointEdit;
- (void)addAnotherPoint;

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
