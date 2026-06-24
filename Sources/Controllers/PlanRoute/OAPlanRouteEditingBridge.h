//
//  OAPlanRouteEditingBridge.h
//  OsmAnd Maps
//
//  Created by OsmAnd on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode;

@interface OAPlanRoutePointData : NSObject

@property (nonatomic, readonly) NSInteger globalIndex;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) double distanceFromPrevious;
@property (nonatomic, readonly) double bearing;
@property (nonatomic, readonly) BOOL isStart;
@property (nonatomic, readonly) BOOL isDestination;

@end

@interface OAPlanRouteGroupData : NSObject

@property (nonatomic, readonly, nullable) OAApplicationMode *appMode;
@property (nonatomic, readonly) double distance;
@property (nonatomic, readonly) NSInteger lastGlobalIndex;
@property (nonatomic, readonly) NSArray<OAPlanRoutePointData *> *points;

@end

@interface OAPlanRouteSegmentData : NSObject

@property (nonatomic, readonly) NSInteger index;
@property (nonatomic, readonly) BOOL routed;
@property (nonatomic, readonly) BOOL multiMode;
@property (nonatomic, readonly, nullable) OAApplicationMode *singleMode;
@property (nonatomic, readonly) double distance;
@property (nonatomic, readonly) NSArray<OAPlanRouteGroupData *> *groups;

@end

@interface OAPlanRouteEditingBridge : NSObject

@property (nonatomic, copy, nullable) void (^onChange)(void);

@property (nonatomic, readonly) BOOL hasContext;
@property (nonatomic, readonly) BOOL hasPoints;
@property (nonatomic, readonly) BOOL isAddNewSegmentAllowed;
@property (nonatomic, readonly) BOOL hasChanges;
@property (nonatomic, readonly) BOOL canUndo;
@property (nonatomic, readonly) BOOL canRedo;
@property (nonatomic, readonly) BOOL hasRoute;
@property (nonatomic, readonly) double routeDistance;
@property (nonatomic, readonly) double distanceToMapCenter;
@property (nonatomic, readonly) double bearingToMapCenter;

- (void)dismiss;
- (void)prepareNewRoute;
- (void)openTrackWithFilePath:(NSString *)filePath;
- (void)addCenterPoint;
- (void)setCrosshairScreenPoint:(CGPoint)point;
- (void)undo;
- (void)redo;
- (void)reverseRoute;
- (void)clearAllPoints;

- (NSArray<OAPlanRouteSegmentData *> *)buildSegments;
- (NSArray<OAApplicationMode *> *)availableModes;

- (void)deletePointAtIndex:(NSInteger)index;
- (void)movePointFrom:(NSInteger)from to:(NSInteger)to;
- (void)deleteSegmentWithPointIndexes:(NSArray<NSNumber *> *)indexes;
- (void)startNewSegment;
- (void)applyMode:(OAApplicationMode *)mode pointIndex:(NSInteger)pointIndex wholeRoute:(BOOL)wholeRoute;
- (void)sortSegmentDoorToDoorWithPointIndexes:(NSArray<NSNumber *> *)indexes;
- (void)selectPointAtIndex:(NSInteger)index;

- (void)saveAs:(NSString *)fileName
        folder:(nullable NSString *)folder
     showOnMap:(BOOL)showOnMap
    onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

- (void)saveAsCopy:(NSString *)fileName
            folder:(nullable NSString *)folder
         showOnMap:(BOOL)showOnMap
        onComplete:(void (^)(BOOL success, NSString * _Nullable outPath))onComplete;

- (void)enterNavigationWithTrackName:(NSString *)trackName;

@end

NS_ASSUME_NONNULL_END
