#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import <OsmAndShared/OsmAndShared.h>
#import "OAApplicationMode.h"
#import "OAMeasurementEditingContext.h"
#import "OAMeasurementCommandManager.h"
#import "OAMeasurementToolLayer.h"
#import "OAPlanRouteEditingBridge.h"
#import "OAClearPointsCommand.h"
#import "OAAddPointCommand.h"
#import "OARoadSegmentData.h"
#import "OARemovePointCommand.h"
#import "OASplitPointsCommand.h"
#import "OAReversePointsCommand.h"
#import "OAJoinPointsCommand.h"

#include <routePlannerFrontEnd.h>

@protocol PlanRouteHistoryPointData <NSObject>
@property (nonatomic, readonly) double distanceFromPrevious;
@property (nonatomic, readonly) BOOL isStart;
@end

@protocol PlanRouteHistoryGroupData <NSObject>
@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) double distance;
@property (nonatomic, readonly) NSArray<id<PlanRouteHistoryPointData>> *points;
@property (nonatomic, readonly) NSArray<NSNumber *> *profilePointIndexes;
@end

@protocol PlanRouteHistorySegmentData <NSObject>
@property (nonatomic, readonly) double distance;
@property (nonatomic, readonly) NSArray<id<PlanRouteHistoryGroupData>> *groups;
@property (nonatomic, readonly) BOOL hasGapAfter;
@property (nonatomic, readonly) double gapDistance;
@end

@interface OAMeasurementToolLayer (HistoryTesting)
- (void)drawRouteSegments;
@end

@interface OAMeasurementEditingContext (RouteCalculationTesting)
- (NSArray<NSArray<OASWptPt *> *> *)getPointsToCalculate;
@end

@interface OAPlanRouteEditingBridge (HistoryTouchTesting)
- (void)onTouch:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress;
- (double)routeDistanceFrom:(OASWptPt *)from to:(OASWptPt *)to;
@end

@interface OAPlanRouteHistoryLayer : OAMeasurementToolLayer
@end

@interface OAPlanRouteHistoryContext : OAMeasurementEditingContext
@end

@implementation OAPlanRouteHistoryContext
- (void)scheduleRouteCalculateIfNotEmpty {}
@end

@implementation OAPlanRouteHistoryLayer
- (BOOL)updateLayer { return YES; }
- (void)resetLayer {}
- (void)moveMapToPoint:(NSInteger)position {}
@end

@interface OAPlanRouteHistoryBridge : OAPlanRouteEditingBridge
@property (nonatomic) OAPlanRouteHistoryLayer *testLayer;
@property (nonatomic) NSArray<NSNumber *> *testLegDistances;
@end

@implementation OAPlanRouteHistoryBridge
- (OAMeasurementToolLayer *)layer { return self.testLayer; }
- (double)routeDistanceFrom:(OASWptPt *)from to:(OASWptPt *)to
{
    NSUInteger index = [self.testLayer.editingCtx.getPoints indexOfObject:to];
    if (index > 0 && index <= self.testLegDistances.count)
        return self.testLegDistances[index - 1].doubleValue;
    return [super routeDistanceFrom:from to:to];
}
@end

@interface OAPlanRouteHistoryTests : XCTestCase
@property (nonatomic) OAMeasurementEditingContext *context;
@property (nonatomic) OAPlanRouteHistoryLayer *layer;
@property (nonatomic) OAPlanRouteHistoryBridge *bridge;
@property (nonatomic) NSArray<OASWptPt *> *original;
@end

@implementation OAPlanRouteHistoryTests

- (void)setUp
{
    [super setUp];
    self.context = [[OAPlanRouteHistoryContext alloc] init];
    self.layer = [[OAPlanRouteHistoryLayer alloc] init];
    self.layer.editingCtx = self.context;
    self.bridge = [[OAPlanRouteHistoryBridge alloc] init];
    self.bridge.testLayer = self.layer;
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger i = 0; i < 8; i++)
    {
        OASWptPt *point = [[OASWptPt alloc] init];
        point.lat = 50 + i * 0.001;
        point.lon = 20 + i * 0.002;
        [points addObject:point];
    }
    self.original = points;
    [self.context addPoints:points];
}

- (NSArray<NSNumber *> *)latitudes:(NSArray<OASWptPt *> *)points
{
    NSMutableArray *result = [NSMutableArray array];
    for (OASWptPt *point in points)
        [result addObject:@(point.lat)];
    return result;
}

- (void)assertFinishedPoints:(NSArray<NSNumber *> *)expected
{
    XCTAssertEqualObjects([self latitudes:self.context.getAllPoints], expected);
    XCTAssertEqualObjects([self latitudes:self.context.getPoints], expected);
    XCTAssertEqual(self.context.getAfterPoints.count, 0);
}

- (void)addPointNumber:(NSInteger)number
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:51 + number * 0.001 longitude:21];
    XCTAssertTrue([self.context.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:self.layer coordinate:location]]);
}

- (NSArray<NSString *> *)profiles:(NSArray<OASWptPt *> *)points
{
    NSMutableArray *result = [NSMutableArray array];
    for (OASWptPt *point in points)
        [result addObject:point.getProfileType ?: @""];
    return result;
}

- (void)testMovingGapOrCrossingSegmentBoundaryDoesNotCreateHistory
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    NSArray *expected = [self latitudes:self.original];
    for (NSArray<NSNumber *> *move in @[@[@3, @1], @[@0, @3], @[@0, @4], @[@4, @2], @[@-1, @2], @[@0, @99]])
    {
        [self.bridge movePointFrom:move[0].integerValue to:move[1].integerValue];
        [self assertFinishedPoints:expected];
        XCTAssertFalse(self.context.commandManager.canUndo);
        XCTAssertEqual(self.segments.count, 2);
    }
}

- (void)testReorderKeepsProfilesWithPointsAndUndoRestoresThem
{
    [self prepareThreeProfileRoute];
    NSArray *profiles = [self profiles:self.context.getPoints];
    NSArray *latitudes = [self latitudes:self.context.getPoints];
    [self.bridge movePointFrom:0 to:1];
    XCTAssertEqualObjects(self.context.getPoints[0].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertFalse(self.context.getPoints[1].hasProfile);
    NSArray *reordered = [self latitudes:self.context.getPoints];
    for (NSInteger cycle = 0; cycle < 2; cycle++)
    {
        [self.bridge undo];
        [self assertFinishedPoints:latitudes];
        XCTAssertEqualObjects([self profiles:self.context.getPoints], profiles);
        [self.bridge redo];
        [self assertFinishedPoints:reordered];
    }
}

- (void)testSortKeepsGapEndpointAndNeighbourSegmentInPlace
{
    self.original[1].lat = 51;
    self.original[2].lat = 50.0001;
    self.original[3].lat = 50.00001;
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    NSArray *original = [self latitudes:self.context.getPoints];
    [self.bridge sortSegmentDoorToDoorWithPointIndexes:@[@0, @1, @2, @3]];
    XCTAssertEqual(self.context.getPoints[1], self.original[2]);
    XCTAssertEqual(self.context.getPoints[3], self.original[3]);
    XCTAssertEqual(self.context.getPoints[4], self.original[4]);
    XCTAssertEqual(self.segments.count, 2);
    [self.bridge undo];
    [self assertFinishedPoints:original];
    [self.bridge redo];
    XCTAssertEqual(self.context.getPoints[3], self.original[3]);
}

- (void)verifyMenuInsertionBefore:(BOOL)before index:(NSInteger)index gap:(BOOL)gap
{
    [self prepareThreeProfileRoute];
    if (gap)
        [self.original[2] setGap];
    [self.context updateSegmentsForSnap];
    NSArray *original = [self latitudes:self.context.getPoints];
    NSArray *originalProfiles = [self profiles:self.context.getPoints];
    NSInteger insertionIndex = before ? index : index + 1;
    OASWptPt *source = self.context.getPoints[index];
    if (before && index > 0 && !self.context.getPoints[index - 1].isGap)
        source = self.context.getPoints[index - 1];
    NSString *expectedProfile = source.getProfileType ?: @"";
    if (before)
        [self.bridge addPointBeforeIndex:index];
    else
        [self.bridge addPointAfterIndex:index];
    [self addPointNumber:0];
    [self.bridge cancelPointEdit];
    NSArray *inserted = [self latitudes:self.context.getPoints];
    NSArray *insertedProfiles = [self profiles:self.context.getPoints];
    XCTAssertEqual(inserted.count, original.count + 1);
    XCTAssertEqualObjects(insertedProfiles[insertionIndex], expectedProfile);
    if (gap)
        XCTAssertEqual(self.segments.count, 2);
    for (NSInteger cycle = 0; cycle < 2; cycle++)
    {
        [self.bridge undo];
        [self assertFinishedPoints:original];
        XCTAssertEqualObjects([self profiles:self.context.getPoints], originalProfiles);
        [self.bridge redo];
        [self assertFinishedPoints:inserted];
        XCTAssertEqualObjects([self profiles:self.context.getPoints], insertedProfiles);
    }
    [self.bridge undo];
}

- (void)testAddBeforeAndAfterAtEveryMixedProfileBoundarySupportsRepeatedHistory
{
    for (NSInteger index = 0; index < 6; index++)
    {
        [self verifyMenuInsertionBefore:YES index:index gap:NO];
        [self verifyMenuInsertionBefore:NO index:index gap:NO];
    }
}

- (void)testAddBeforeAndAfterGapEndpointsPreservesSegmentsAndHistory
{
    for (NSInteger index = 2; index <= 3; index++)
    {
        [self verifyMenuInsertionBefore:YES index:index gap:YES];
        [self verifyMenuInsertionBefore:NO index:index gap:YES];
    }
}

- (void)testAddAfterSinglePointSegmentMovesOnlyItsGap
{
    [self.original[0] setGap];
    [self.context updateSegmentsForSnap];
    [self.bridge addPointAfterIndex:0];
    [self addPointNumber:0];
    [self.bridge cancelPointEdit];
    XCTAssertFalse(self.context.getPoints[0].isGap);
    XCTAssertTrue(self.context.getPoints[1].isGap);
    XCTAssertEqual(self.segments.count, 2);
    [self.bridge undo];
    XCTAssertTrue(self.context.getPoints[0].isGap);
    [self.bridge redo];
    XCTAssertFalse(self.context.getPoints[0].isGap);
    XCTAssertTrue(self.context.getPoints[1].isGap);
    XCTAssertEqual(self.segments.count, 2);
}

- (void)testCancellingMenuInsertionWithoutAddingPreservesProfilesAndHistory
{
    [self prepareThreeProfileRoute];
    NSArray *original = [self latitudes:self.context.getPoints];
    NSArray *profiles = [self profiles:self.context.getPoints];
    [self.bridge addPointBeforeIndex:1];
    [self.bridge cancelPointEdit];
    [self.bridge addPointAfterIndex:2];
    [self.bridge cancelPointEdit];
    [self assertFinishedPoints:original];
    XCTAssertEqualObjects([self profiles:self.context.getPoints], profiles);
    XCTAssertFalse(self.context.commandManager.canUndo);
}

- (void)testTrimAtMixedProfileAndGapBoundariesPreservesRemainingLegTypes
{
    for (NSInteger before = 0; before <= 1; before++)
    {
        for (NSInteger index = 0; index < 6; index++)
        {
            [self prepareThreeProfileRoute];
            [self.original[2] setGap];
            [self.context updateSegmentsForSnap];
            NSArray *original = [self latitudes:self.context.getPoints];
            NSArray *profiles = [self profiles:self.context.getPoints];
            NSRange range = before ? NSMakeRange(index, 6 - index) : NSMakeRange(0, index + 1);
            NSArray *expected = [original subarrayWithRange:range];
            NSArray *expectedProfiles = [profiles subarrayWithRange:range];
            if (before)
                [self.bridge trimBeforeIndex:index];
            else
                [self.bridge trimAfterIndex:index];
            for (NSInteger cycle = 0; cycle < 2; cycle++)
            {
                [self assertFinishedPoints:expected];
                XCTAssertEqualObjects([self profiles:self.context.getPoints], expectedProfiles);
                for (id<PlanRouteHistorySegmentData> segment in self.segments)
                {
                    double sum = 0;
                    for (id<PlanRouteHistoryGroupData> group in segment.groups)
                        sum += group.distance;
                    XCTAssertEqualWithAccuracy(sum, segment.distance, 0.001);
                }
                [self.bridge undo];
                [self assertFinishedPoints:original];
                XCTAssertEqualObjects([self profiles:self.context.getPoints], profiles);
                [self.bridge redo];
            }
            [self.bridge undo];
        }
    }
}

- (void)testTrimAfterSynchronizesContinuationWithRemainingEndpointAndHistory
{
    for (OAApplicationMode *mode in @[OAApplicationMode.DEFAULT, OAApplicationMode.BICYCLE])
    {
        [self prepareThreeProfileRoute];
        self.context.appMode = OAApplicationMode.PEDESTRIAN;
        if (mode == OAApplicationMode.DEFAULT)
            [self.original[0] removeProfileType];
        else
            [self.original[0] setProfileTypeProfileType:mode.stringKey];
        [self.bridge trimAfterIndex:0];
        for (NSInteger cycle = 0; cycle < 2; cycle++)
        {
            XCTAssertEqual(self.context.getPointsCount, 1);
            XCTAssertEqualObjects(self.context.appMode.stringKey, mode.stringKey);
            [self addPointNumber:0];
            XCTAssertEqualObjects([OAApplicationMode valueOfStringKey:self.context.getPoints.lastObject.getProfileType
                                                                 def:OAApplicationMode.DEFAULT].stringKey, mode.stringKey);
            [self.bridge undo];
            [self.bridge undo];
            XCTAssertEqualObjects(self.context.appMode.stringKey, OAApplicationMode.PEDESTRIAN.stringKey);
            XCTAssertEqual(self.context.getPointsCount, 6);
            [self.bridge redo];
        }
        [self.bridge undo];
    }
}

- (void)testTrimAfterGapPreservesPendingContinuationMode
{
    [self prepareThreeProfileRoute];
    [self.original[2] setGap];
    self.context.appMode = OAApplicationMode.PEDESTRIAN;
    [self.bridge trimAfterIndex:2];
    XCTAssertTrue(self.context.getPoints.lastObject.isGap);
    XCTAssertEqualObjects(self.context.appMode.stringKey, OAApplicationMode.PEDESTRIAN.stringKey);
    [self.bridge undo];
    [self.bridge redo];
    XCTAssertTrue(self.context.getPoints.lastObject.isGap);
    XCTAssertEqualObjects(self.context.appMode.stringKey, OAApplicationMode.PEDESTRIAN.stringKey);
}

- (void)testChangingWholeSegmentPreservesNeighbourSegmentAndGap
{
    [self prepareThreeProfileRoute];
    [self.original[2] setGap];
    [self.context updateSegmentsForSnap];
    NSArray *profiles = [self profiles:self.context.getPoints];
    [self.bridge applyMode:OAApplicationMode.PEDESTRIAN pointIndexes:@[@0, @1, @2]];
    XCTAssertEqualObjects(self.original[0].getProfileType, OAApplicationMode.PEDESTRIAN.stringKey);
    XCTAssertEqualObjects(self.original[1].getProfileType, OAApplicationMode.PEDESTRIAN.stringKey);
    XCTAssertTrue(self.original[2].isGap);
    XCTAssertEqualObjects([[self profiles:self.context.getPoints] subarrayWithRange:NSMakeRange(3, 3)],
                          [profiles subarrayWithRange:NSMakeRange(3, 3)]);
    [self.bridge undo];
    XCTAssertEqualObjects([self profiles:self.context.getPoints], profiles);
    [self.bridge redo];
    XCTAssertTrue(self.original[2].isGap);
    XCTAssertEqual(self.segments.count, 2);
}

- (void)testContinueWithDifferentProfilePreservesExistingLegs
{
    NSArray<OASWptPt *> *pair = @[self.original[0], self.original[1]];
    OARoadSegmentData *geometry = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                                   start:pair[0] end:pair[1] points:pair segments:{}];
    self.context.roadSegmentData[pair] = geometry;
    [self.bridge applyMode:OAApplicationMode.BICYCLE pointIndex:7 wholeRoute:NO];
    for (NSInteger index = 0; index < 7; index++)
        XCTAssertFalse(self.original[index].hasProfile);
    XCTAssertEqualObjects(self.original.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqual(self.context.roadSegmentData[pair], geometry);
    XCTAssertFalse(self.bridge.isCalculatingRoute);
    [self addPointNumber:0];
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
    [self.bridge undo];
    [self.bridge undo];
    XCTAssertFalse(self.context.getPoints.lastObject.hasProfile);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.DEFAULT);
    XCTAssertEqual(self.context.roadSegmentData[pair], geometry);
    [self.bridge redo];
    [self.bridge redo];
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
}

- (NSArray<id<PlanRouteHistorySegmentData>> *)segments
{
    return (NSArray *)[self.bridge buildSegments];
}

- (void)prepareThreeProfileRoute
{
    [self.context setPoints:[self.original subarrayWithRange:NSMakeRange(0, 6)]];
    for (OASWptPt *point in self.context.getPoints)
        [point removeProfileType];
    [self.original[1] setProfileTypeProfileType:OAApplicationMode.BICYCLE.stringKey];
    [self.original[2] setProfileTypeProfileType:OAApplicationMode.BICYCLE.stringKey];
    [self.original[3] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
    [self.original[4] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
    [self.original[5] setProfileTypeProfileType:OAApplicationMode.CAR.stringKey];
    self.context.appMode = OAApplicationMode.CAR;
    self.bridge.testLegDistances = @[@175, @368, @1200, @600, @900];
}

- (void)testProfileGroupsUseIncomingLegsAndExcludeFutureProfile
{
    [self prepareThreeProfileRoute];
    id<PlanRouteHistorySegmentData> segment = self.segments.firstObject;
    XCTAssertEqual(segment.groups.count, 3);
    id<PlanRouteHistoryGroupData> straight = segment.groups[0];
    id<PlanRouteHistoryGroupData> cycling = segment.groups[1];
    id<PlanRouteHistoryGroupData> walking = segment.groups[2];
    XCTAssertNil(straight.appMode);
    XCTAssertEqual(cycling.appMode, OAApplicationMode.BICYCLE);
    XCTAssertEqual(walking.appMode, OAApplicationMode.PEDESTRIAN);
    XCTAssertEqualObjects([straight.points valueForKey:@"globalIndex"], (@[@0, @1]));
    XCTAssertEqualObjects([cycling.points valueForKey:@"globalIndex"], (@[@2, @3]));
    XCTAssertEqualObjects([walking.points valueForKey:@"globalIndex"], (@[@4, @5]));
    XCTAssertEqualObjects(straight.profilePointIndexes, @[@0]);
    XCTAssertEqualObjects(cycling.profilePointIndexes, (@[@1, @2]));
    XCTAssertEqualObjects(walking.profilePointIndexes, (@[@3, @4, @5]));
    XCTAssertEqualWithAccuracy(straight.distance, 175, 0.001);
    XCTAssertEqualWithAccuracy(cycling.distance, 1568, 0.001);
    XCTAssertEqualWithAccuracy(walking.distance, 1500, 0.001);
    XCTAssertEqualWithAccuracy(segment.distance, 3243, 0.001);
    XCTAssertEqualWithAccuracy(straight.distance + cycling.distance + walking.distance, segment.distance, 0.001);
}

- (void)testTwoProfileRouteKeepsBoundaryPointInStraightSection
{
    [self prepareThreeProfileRoute];
    [self.context setPoints:[self.original subarrayWithRange:NSMakeRange(0, 4)]];
    self.bridge.testLegDistances = @[@175, @368, @2887];
    id<PlanRouteHistorySegmentData> segment = self.segments.firstObject;
    XCTAssertEqual(segment.groups.count, 2);
    XCTAssertEqualObjects([segment.groups[0].points valueForKey:@"globalIndex"], (@[@0, @1]));
    XCTAssertEqualWithAccuracy(segment.groups[0].distance, 175, 0.001);
    XCTAssertEqualWithAccuracy(segment.groups[1].distance, 3255, 0.001);
    XCTAssertEqualWithAccuracy(segment.distance, 3430, 0.001);
}

- (void)testGapStartsNewGroupingAndExcludesDisconnectedLeg
{
    [self prepareThreeProfileRoute];
    [self.original[2] setGap];
    NSArray<id<PlanRouteHistorySegmentData>> *segments = self.segments;
    XCTAssertEqual(segments.count, 2);
    XCTAssertEqual(segments[0].groups.count, 2);
    XCTAssertEqualObjects([segments[0].groups.lastObject.points valueForKey:@"globalIndex"], @[@2]);
    XCTAssertEqualObjects(segments[0].groups.lastObject.profilePointIndexes, @[@1]);
    XCTAssertEqualWithAccuracy(segments[0].distance, 543, 0.001);
    XCTAssertTrue(segments[0].hasGapAfter);
    XCTAssertGreaterThan(segments[0].gapDistance, 0);
    XCTAssertEqual(segments[1].groups.count, 1);
    XCTAssertEqualObjects([segments[1].groups[0].points valueForKey:@"globalIndex"], (@[@3, @4, @5]));
    XCTAssertTrue(segments[1].groups[0].points.firstObject.isStart);
    XCTAssertEqualWithAccuracy(segments[1].groups[0].points.firstObject.distanceFromPrevious, 0, 0.001);
    XCTAssertEqualWithAccuracy(segments[1].distance, 1500, 0.001);
}

- (void)testContinueChangesOnlyFutureProfileUntilPointIsAdded
{
    [self prepareThreeProfileRoute];
    [self.bridge applyMode:OAApplicationMode.BICYCLE pointIndex:5 wholeRoute:NO];
    id<PlanRouteHistorySegmentData> segment = self.segments.firstObject;
    XCTAssertEqual(segment.groups.count, 3);
    XCTAssertEqual(segment.groups.lastObject.appMode, OAApplicationMode.PEDESTRIAN);
    XCTAssertEqualObjects([segment.groups.lastObject.points valueForKey:@"globalIndex"], (@[@4, @5]));
    XCTAssertEqualWithAccuracy(segment.distance, 3243, 0.001);
    [self addPointNumber:0];
    id<PlanRouteHistoryGroupData> nextGroup = self.segments.firstObject.groups.lastObject;
    XCTAssertEqual(self.segments.firstObject.groups.count, 4);
    XCTAssertEqual(nextGroup.appMode, OAApplicationMode.BICYCLE);
    XCTAssertEqualObjects([nextGroup.points valueForKey:@"globalIndex"], @[@6]);
    XCTAssertGreaterThan(nextGroup.distance, 0);
}

- (void)testChangingMiddleGroupPreservesNeighbourGeometryAndSupportsUndoRedo
{
    [self prepareThreeProfileRoute];
    for (NSInteger index = 0; index < 5; index++)
        [self cacheRouteForPair:@[self.original[index], self.original[index + 1]]
                          mode:[OAApplicationMode valueOfStringKey:self.original[index].getProfileType def:OAApplicationMode.DEFAULT]];
    NSDictionary *geometry = [self.context.roadSegmentData copy];
    id<PlanRouteHistoryGroupData> cycling = self.segments.firstObject.groups[1];
    [self.bridge applyMode:OAApplicationMode.CAR pointIndexes:cycling.profilePointIndexes];
    XCTAssertFalse(self.original[0].hasProfile);
    XCTAssertEqualObjects(self.original[1].getProfileType, OAApplicationMode.CAR.stringKey);
    XCTAssertEqualObjects(self.original[2].getProfileType, OAApplicationMode.CAR.stringKey);
    XCTAssertEqualObjects(self.original[3].getProfileType, OAApplicationMode.PEDESTRIAN.stringKey);
    XCTAssertEqualObjects(self.original[4].getProfileType, OAApplicationMode.PEDESTRIAN.stringKey);
    for (NSNumber *indexNumber in @[@0, @3, @4])
    {
        NSInteger index = indexNumber.integerValue;
        NSArray *pair = @[self.original[index], self.original[index + 1]];
        XCTAssertEqual(self.context.roadSegmentData[pair], geometry[pair]);
    }
    XCTAssertNil((self.context.roadSegmentData[@[self.original[1], self.original[2]]]));
    XCTAssertNil((self.context.roadSegmentData[@[self.original[2], self.original[3]]]));
    [self.bridge undo];
    XCTAssertEqualObjects(self.original[1].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqualObjects(self.original[2].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqualObjects(self.context.roadSegmentData, geometry);
    [self.bridge redo];
    XCTAssertEqualObjects(self.original[1].getProfileType, OAApplicationMode.CAR.stringKey);
    XCTAssertEqualObjects(self.original[2].getProfileType, OAApplicationMode.CAR.stringKey);
}

- (void)testChangingLastGroupUpdatesProfileForNextPoint
{
    [self prepareThreeProfileRoute];
    id<PlanRouteHistoryGroupData> walking = self.segments.firstObject.groups.lastObject;
    [self.bridge applyMode:OAApplicationMode.BICYCLE pointIndexes:walking.profilePointIndexes];
    XCTAssertEqualObjects(self.original[3].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqualObjects(self.original[4].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqualObjects(self.original[5].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self addPointNumber:0];
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
}

- (void)testSinglePointAndPendingGapDoNotCreateFutureProfileGroups
{
    [self.context setPoints:@[self.original[0]]];
    [self.bridge applyMode:OAApplicationMode.BICYCLE pointIndex:0 wholeRoute:NO];
    id<PlanRouteHistoryGroupData> group = self.segments.firstObject.groups.firstObject;
    XCTAssertEqual(group.points.count, 1);
    XCTAssertEqualObjects(group.profilePointIndexes, @[@0]);
    [self prepareThreeProfileRoute];
    [self.original[5] setGap];
    id<PlanRouteHistorySegmentData> segment = self.segments.firstObject;
    XCTAssertEqual(segment.groups.count, 3);
    XCTAssertEqualObjects(segment.groups.lastObject.profilePointIndexes, (@[@3, @4]));
    XCTAssertEqualWithAccuracy(segment.groups.lastObject.distance, 1500, 0.001);
}

- (void)testStraightPairsAreQueuedAfterRoutedPairCompletes
{
    XCTAssertEqual(self.context.getPointsToCalculate.count, 0);
    [self.original[6] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
    NSArray<OASWptPt *> *routedPair = @[self.original[6], self.original[7]];
    XCTAssertEqualObjects(self.context.getPointsToCalculate, @[routedPair]);
    self.context.roadSegmentData[routedPair] = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.PEDESTRIAN
                                                                                start:routedPair[0] end:routedPair[1]
                                                                               points:routedPair segments:{}];
    NSArray<NSArray<OASWptPt *> *> *pendingPairs = self.context.getPointsToCalculate;
    NSMutableArray<NSArray<OASWptPt *> *> *expectedPairs = [NSMutableArray array];
    for (NSInteger index = 0; index < 6; index++)
        [expectedPairs addObject:@[self.original[index], self.original[index + 1]]];
    XCTAssertEqualObjects(pendingPairs, expectedPairs);
}

- (void)testMixedRouteDoesNotQueueGapPair
{
    [self.original[3] setGap];
    NSArray<OASWptPt *> *routedPair = @[self.original[0], self.original[1]];
    self.context.roadSegmentData[routedPair] = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.PEDESTRIAN
                                                                                start:routedPair[0] end:routedPair[1]
                                                                               points:routedPair segments:{}];
    NSArray<NSArray<OASWptPt *> *> *pendingPairs = self.context.getPointsToCalculate;
    XCTAssertEqual(pendingPairs.count, 2);
    XCTAssertFalse(([pendingPairs containsObject:@[self.original[3], self.original[4]]]));
    XCTAssertTrue(([pendingPairs containsObject:@[self.original[2], self.original[3]]]));
}

- (void)testUnusedRouteDataDoesNotQueueStraightPairs
{
    NSArray<OASWptPt *> *unusedPair = @[self.original[0], self.original[7]];
    self.context.roadSegmentData[unusedPair] = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.PEDESTRIAN
                                                                                start:unusedPair[0] end:unusedPair[1]
                                                                               points:unusedPair segments:{}];
    XCTAssertEqual(self.context.getPointsToCalculate.count, 0);
}

- (void)testWholeTrackStraightModeUndoRedoRestoresCalculationQueue
{
    [self.original[6] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
    NSArray<OASWptPt *> *routedPair = @[self.original[6], self.original[7]];
    self.context.roadSegmentData[routedPair] = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.PEDESTRIAN
                                                                                start:routedPair[0] end:routedPair[1]
                                                                               points:routedPair segments:{}];
    XCTAssertEqual(self.context.getPointsToCalculate.count, 6);
    [self.bridge applyMode:OAApplicationMode.DEFAULT pointIndex:0 wholeRoute:YES];
    XCTAssertEqual(self.context.getPointsToCalculate.count, 0);
    [self.bridge undo];
    XCTAssertEqual(self.context.getPointsToCalculate.count, 6);
    [self.bridge redo];
    XCTAssertEqual(self.context.getPointsToCalculate.count, 0);
}

- (void)cacheRouteForPair:(NSArray<OASWptPt *> *)pair mode:(OAApplicationMode *)mode
{
    std::vector<std::pair<double, double>> coordinates;
    for (OASWptPt *point in pair)
        coordinates.push_back({point.lat, point.lon});
    auto segment = RoutePlannerFrontEnd::generateStraightLineSegment(mode.getDefaultSpeed, coordinates);
    self.context.roadSegmentData[pair] = [[OARoadSegmentData alloc] initWithAppMode:mode
                                                                          start:pair[0] end:pair[1]
                                                                         points:pair segments:{segment}];
}

- (void)testMixedSegmentExportContainsStraightAndRoutedLegs
{
    NSArray<OASWptPt *> *points = [self.original subarrayWithRange:NSMakeRange(0, 3)];
    [self.context setPoints:points];
    [points[1] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
    [self cacheRouteForPair:@[points[1], points[2]] mode:OAApplicationMode.PEDESTRIAN];
    NSArray<NSArray<OASWptPt *> *> *pendingPairs = self.context.getPointsToCalculate;
    XCTAssertEqualObjects(pendingPairs, (@[@[points[0], points[1]]]));
    for (NSArray<OASWptPt *> *pair in pendingPairs)
        [self cacheRouteForPair:pair mode:OAApplicationMode.DEFAULT];

    OASGpxFile *gpx = [self.context exportGpx:@"mixed-route-test"];
    XCTAssertEqual(gpx.tracks.firstObject.segments.count, 1);
    OASTrkSegment *segment = gpx.tracks.firstObject.segments.firstObject;
    XCTAssertEqual(segment.points.count, 4);
    XCTAssertEqual(segment.routeSegments.count, 2);
    XCTAssertEqualObjects([self latitudes:segment.points], (@[@(points[0].lat), @(points[1].lat), @(points[1].lat), @(points[2].lat)]));
    for (OASWptPt *point in points)
    {
        XCTAssertGreaterThanOrEqual(point.getTrkPtIndex, 0);
        XCTAssertLessThan(point.getTrkPtIndex, segment.points.count);
    }
}

- (void)testIndependentRecordedSegmentPreservesMetadataOnExport
{
    NSArray<OASWptPt *> *points = [self.original subarrayWithRange:NSMakeRange(0, 4)];
    [self.context setPoints:points];
    for (NSInteger routedSegmentIndex = 0; routedSegmentIndex < 2; routedSegmentIndex++)
    {
        [self.context.roadSegmentData removeAllObjects];
        for (OASWptPt *point in points)
            [point removeProfileType];
        [points[1] setGap];
        NSInteger routedStart = routedSegmentIndex * 2;
        NSInteger recordedStart = (1 - routedSegmentIndex) * 2;
        [points[routedStart] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
        points[recordedStart].time = 1700000000000;
        points[recordedStart + 1].time = 1700000060000;
        points[recordedStart].speed = 1.5;
        points[recordedStart + 1].speed = 2.5;
        [self cacheRouteForPair:@[points[routedStart], points[routedStart + 1]] mode:OAApplicationMode.PEDESTRIAN];
        XCTAssertEqual(self.context.getPointsToCalculate.count, 0);

        OASGpxFile *gpx = [self.context exportGpx:@"recorded-segment-test"];
        XCTAssertEqual(gpx.tracks.firstObject.segments.count, 2);
        OASTrkSegment *recordedSegment = gpx.tracks.firstObject.segments[1 - routedSegmentIndex];
        XCTAssertEqual(recordedSegment.points.count, 2);
        XCTAssertEqual(recordedSegment.points.firstObject.time, 1700000000000);
        XCTAssertEqual(recordedSegment.points.lastObject.time, 1700000060000);
        XCTAssertEqualWithAccuracy(recordedSegment.points.firstObject.speed, 1.5, DBL_EPSILON);
        XCTAssertEqualWithAccuracy(recordedSegment.points.lastObject.speed, 2.5, DBL_EPSILON);
        XCTAssertEqualObjects([self latitudes:recordedSegment.points], [self latitudes:[points subarrayWithRange:NSMakeRange(recordedStart, 2)]]);
    }
}

- (void)testStartNewSegmentProfileAndGapShareOneHistoryEntry
{
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    XCTAssertTrue(self.context.getPoints.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    for (NSInteger cycle = 0; cycle < 3; cycle++)
    {
        [self.bridge undo];
        XCTAssertFalse(self.context.getPoints.lastObject.isGap);
        XCTAssertEqual(self.context.appMode, OAApplicationMode.DEFAULT);
        XCTAssertFalse(self.context.commandManager.canUndo);
        [self.bridge redo];
        XCTAssertTrue(self.context.getPoints.lastObject.isGap);
        XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    }
    [self addPointNumber:0];
    [self addPointNumber:1];
    XCTAssertTrue(self.context.getPoints[7].isGap);
    XCTAssertEqualObjects(self.context.getPoints[8].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqualObjects(self.context.getPoints[9].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    [self.bridge undo];
    [self.bridge undo];
    [self.bridge undo];
    XCTAssertFalse(self.context.getPoints.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.DEFAULT);
    [self.bridge redo];
    [self.bridge redo];
    [self.bridge redo];
    XCTAssertTrue(self.context.getPoints[7].isGap);
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
}

- (void)testNewSegmentRejectsAlreadyPendingSegment
{
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    XCTAssertFalse(self.bridge.isAddNewSegmentAllowed);
    [self.bridge startNewSegmentWithMode:OAApplicationMode.CAR];
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self.bridge undo];
    XCTAssertFalse(self.context.getPoints.lastObject.isGap);
    XCTAssertFalse(self.context.commandManager.canUndo);
    XCTAssertTrue(self.bridge.isAddNewSegmentAllowed);
}

- (void)testContinuePendingSegmentPreservesGap
{
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    [self.bridge applyMode:OAApplicationMode.DEFAULT pointIndex:7 wholeRoute:NO];
    XCTAssertTrue(self.context.getPoints.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.DEFAULT);
    [self.bridge undo];
    XCTAssertTrue(self.context.getPoints.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self.bridge redo];
    [self addPointNumber:0];
    XCTAssertTrue(self.context.getPoints[7].isGap);
    XCTAssertFalse(self.context.getPoints.lastObject.hasProfile);
}

- (void)testSingleRouteTypeOnlyChangesSelectedSegment
{
    [self.original[1] setProfileTypeProfileType:OAApplicationMode.BICYCLE.stringKey];
    [self.original[3] setGap];
    [self.original[4] setProfileTypeProfileType:OAApplicationMode.CAR.stringKey];
    [self.context updateSegmentsForSnap];
    [self.bridge applyMode:OAApplicationMode.DEFAULT pointIndexes:@[@0, @1, @2, @3]];
    XCTAssertFalse(self.original[1].hasProfile);
    XCTAssertTrue(self.original[3].isGap);
    XCTAssertEqualObjects(self.original[4].getProfileType, OAApplicationMode.CAR.stringKey);
    [self.bridge undo];
    XCTAssertEqualObjects(self.original[1].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertFalse(self.context.commandManager.canUndo);
    [self.bridge redo];
    XCTAssertFalse(self.original[1].hasProfile);
    XCTAssertTrue(self.original[3].isGap);
}

- (void)testNewSegmentRejectsEmptyAndSinglePointTrack
{
    [self.context clearPoints];
    [self.context updateSegmentsForSnap];
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    XCTAssertFalse(self.context.commandManager.canUndo);
    [self.context addPoint:self.original.firstObject];
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    XCTAssertFalse(self.context.commandManager.canUndo);
    XCTAssertFalse(self.context.getPoints.lastObject.isGap);
}

- (void)testChangingEarlierSegmentPreservesPendingSegmentProfile
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    [self.bridge applyMode:OAApplicationMode.DEFAULT pointIndexes:@[@0, @1, @2, @3]];
    XCTAssertTrue(self.context.getPoints.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self.bridge undo];
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self.bridge redo];
    [self addPointNumber:0];
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
}

- (void)verifyEditingBeforePendingSegmentWithPointIndexes:(NSArray<NSNumber *> *)pointIndexes
{
    for (NSInteger index = 4; index < self.original.count; index++)
        [self.original[index] setProfileTypeProfileType:OAApplicationMode.PEDESTRIAN.stringKey];
    [self.context updateSegmentsForSnap];
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    [self.bridge applyMode:OAApplicationMode.CAR pointIndexes:pointIndexes];
    XCTAssertTrue(self.original.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    for (NSNumber *indexNumber in pointIndexes)
    {
        NSInteger index = indexNumber.integerValue;
        if (index < 7)
            XCTAssertEqualObjects(self.original[index].getProfileType, OAApplicationMode.CAR.stringKey);
    }
    for (NSInteger cycle = 0; cycle < 3; cycle++)
    {
        [self.bridge undo];
        XCTAssertTrue(self.original.lastObject.isGap);
        XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
        for (NSInteger index = 0; index < 4; index++)
            XCTAssertFalse(self.original[index].hasProfile);
        for (NSInteger index = 4; index < 7; index++)
            XCTAssertEqualObjects(self.original[index].getProfileType, OAApplicationMode.PEDESTRIAN.stringKey);
        [self.bridge redo];
        XCTAssertTrue(self.original.lastObject.isGap);
        XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
        XCTAssertEqualObjects(self.original[6].getProfileType, OAApplicationMode.CAR.stringKey);
    }
    [self addPointNumber:0];
    [self addPointNumber:1];
    XCTAssertTrue(self.context.getPoints[7].isGap);
    XCTAssertEqualObjects(self.context.getPoints[8].getProfileType, OAApplicationMode.BICYCLE.stringKey);
    XCTAssertEqualObjects(self.context.getPoints[9].getProfileType, OAApplicationMode.BICYCLE.stringKey);
}

- (void)testChangingLastSectionPreservesPendingSegmentProfile
{
    [self verifyEditingBeforePendingSegmentWithPointIndexes:@[@4, @5, @6, @7]];
    for (NSInteger index = 0; index < 4; index++)
        XCTAssertFalse(self.original[index].hasProfile);
}

- (void)testChangingLastWholeSegmentPreservesPendingSegmentProfile
{
    [self verifyEditingBeforePendingSegmentWithPointIndexes:@[@0, @1, @2, @3, @4, @5, @6, @7]];
}

- (void)testChangingExistingLegPreservesPendingSegmentProfile
{
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    [self.bridge applyMode:OAApplicationMode.CAR pointIndex:5 wholeRoute:NO];
    XCTAssertEqualObjects(self.original[5].getProfileType, OAApplicationMode.CAR.stringKey);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self.bridge undo];
    XCTAssertFalse(self.original[5].hasProfile);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self.bridge redo];
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    [self addPointNumber:0];
    XCTAssertTrue(self.context.getPoints[7].isGap);
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.BICYCLE.stringKey);
}

- (void)testChangingWholeRouteUpdatesPendingSegmentProfile
{
    [self.bridge startNewSegmentWithMode:OAApplicationMode.BICYCLE];
    [self.bridge applyMode:OAApplicationMode.CAR pointIndex:0 wholeRoute:YES];
    XCTAssertTrue(self.original.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.CAR);
    for (NSInteger index = 0; index < 7; index++)
        XCTAssertEqualObjects(self.original[index].getProfileType, OAApplicationMode.CAR.stringKey);
    [self.bridge undo];
    XCTAssertTrue(self.original.lastObject.isGap);
    XCTAssertEqual(self.context.appMode, OAApplicationMode.BICYCLE);
    for (NSInteger index = 0; index < 7; index++)
        XCTAssertFalse(self.original[index].hasProfile);
    [self.bridge redo];
    XCTAssertEqual(self.context.appMode, OAApplicationMode.CAR);
    [self addPointNumber:0];
    XCTAssertTrue(self.context.getPoints[7].isGap);
    XCTAssertEqualObjects(self.context.getPoints.lastObject.getProfileType, OAApplicationMode.CAR.stringKey);
}

- (void)testTrimBeforeRedoMatchesInitialExecution
{
    [self.bridge trimBeforeIndex:4];
    NSArray *expected = [self latitudes:self.context.getAllPoints];
    [self.bridge undo];
    [self assertFinishedPoints:[self latitudes:self.original]];
    [self.bridge redo];
    [self assertFinishedPoints:expected];
}

- (void)testTrimAfterRedoMatchesInitialExecution
{
    [self.bridge trimAfterIndex:3];
    NSArray *expected = [self latitudes:self.context.getAllPoints];
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.bridge undo];
        [self assertFinishedPoints:[self latitudes:self.original]];
        [self.bridge redo];
        [self assertFinishedPoints:expected];
    }
}

- (void)verifyTrimAddHistoryWithCount:(NSInteger)count
{
    [self.bridge trimBeforeIndex:4];
    NSArray *trimmed = [self latitudes:self.context.getAllPoints];
    for (NSInteger i = 0; i < count; i++)
        [self addPointNumber:i];
    NSArray *added = [self latitudes:self.context.getAllPoints];
    for (NSInteger i = 0; i < count + 1; i++)
        [self.bridge undo];
    [self assertFinishedPoints:[self latitudes:self.original]];
    for (NSInteger i = 0; i < count + 1; i++)
        [self.bridge redo];
    [self assertFinishedPoints:added];
    XCTAssertNoThrow([self.bridge undo]);
    if (count == 1)
        [self assertFinishedPoints:trimmed];
}

- (void)testTrimAddRedoThenUndoOnePoint
{
    [self verifyTrimAddHistoryWithCount:1];
}

- (void)testTrimAddRedoThenUndoThreePoints
{
    [self verifyTrimAddHistoryWithCount:3];
}

- (void)testTwoTrimsRepeatedHistoryPreservesSecondSnapshot
{
    [self.bridge trimBeforeIndex:2];
    NSArray *first = [self latitudes:self.context.getAllPoints];
    [self.bridge trimBeforeIndex:2];
    NSArray *second = [self latitudes:self.context.getAllPoints];
    [self.bridge undo];
    [self assertFinishedPoints:first];
    [self.bridge undo];
    [self.bridge redo];
    [self.bridge redo];
    [self.bridge undo];
    [self assertFinishedPoints:first];
    XCTAssertNoThrow([self.bridge redo]);
    [self assertFinishedPoints:second];
}

- (void)testTrimDuringSplitPreservesAllPointsForUndo
{
    [self.context splitSegments:4];
    [self.bridge trimBeforeIndex:2];
    [self.bridge undo];
    XCTAssertEqualObjects([self latitudes:self.context.getAllPoints], [self latitudes:self.original]);
}

- (void)testRoadGeometrySurvivesTrimUndoAndRepeatedCycles
{
    NSArray<OASWptPt *> *pair = @[self.original[0], self.original[1]];
    OARoadSegmentData *data = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                               start:pair[0] end:pair[1] points:pair segments:{}];
    self.context.roadSegmentData[pair] = data;
    [self.bridge trimBeforeIndex:4];
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.bridge undo];
        XCTAssertEqual(self.context.roadSegmentData.count, 1);
        XCTAssertEqualObjects([self latitudes:self.context.roadSegmentData[pair].gpxPoints], [self latitudes:pair]);
        [self.bridge redo];
    }
}

- (void)testClearAllUndoRestoresRoadGeometry
{
    NSArray<OASWptPt *> *pair = @[self.original[0], self.original[1]];
    self.context.roadSegmentData[pair] = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                                          start:pair[0] end:pair[1] points:pair segments:{}];
    [self.bridge clearAllPoints];
    [self.bridge undo];
    XCTAssertNotNil(self.context.roadSegmentData[pair]);
    [self assertFinishedPoints:[self latitudes:self.original]];
}

- (void)testExportAfterRedoTrimContainsRemainingTrack
{
    [self.bridge trimBeforeIndex:4];
    [self.bridge undo];
    [self.bridge redo];
    OASGpxFile *gpx = [self.context exportGpx:@"history-test"];
    XCTAssertNotNil(gpx);
    XCTAssertTrue(gpx.hasTrkPt);
}

- (void)testNewActionAfterUndoClearsRedo
{
    [self addPointNumber:0];
    [self.bridge undo];
    XCTAssertTrue(self.context.commandManager.canRedo);
    [self addPointNumber:1];
    XCTAssertFalse(self.context.commandManager.canRedo);
    [self.bridge undo];
    [self assertFinishedPoints:[self latitudes:self.original]];
}

- (void)testOrdinaryInsertionKeepsSuffixUntilFinished
{
    [self.context splitSegments:3];
    self.context.addPointMode = EOAAddPointModeBefore;
    [self addPointNumber:0];
    [self addPointNumber:1];
    XCTAssertEqual(self.context.getAfterPoints.count, 5);
    [self.bridge cancelPointEdit];
    NSMutableArray *expected = [[self latitudes:[self.original subarrayWithRange:NSMakeRange(0, 3)]] mutableCopy];
    [expected addObjectsFromArray:@[@51, @(51 + 0.001)]];
    [expected addObjectsFromArray:[self latitudes:[self.original subarrayWithRange:NSMakeRange(3, 5)]]];
    [self assertFinishedPoints:expected];
}

- (void)testRendererRemovesLinesAfterJoiningEditingHalves
{
    OAMeasurementToolLayer *renderLayer = [[OAMeasurementToolLayer alloc] init];
    renderLayer.editingCtx = self.context;
    [renderLayer prepareRouteLinesForTesting];
    [self.context splitSegments:4];
    [renderLayer drawRouteSegments];
    XCTAssertEqual(renderLayer.routeLineCountForTesting, 2);
    [self.context splitSegments:8];
    [renderLayer drawRouteSegments];
    XCTAssertEqual(renderLayer.routeLineCountForTesting, 1);
    [self.context clearSegments];
    [renderLayer drawRouteSegments];
    XCTAssertEqual(renderLayer.routeLineCountForTesting, 0);
}

- (void)testDeletingGapEndpointUndoRestoresOnlyOriginalGap
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    [self.bridge deletePointAtIndex:3];
    [self.bridge undo];
    XCTAssertFalse(self.context.getPoints[2].isGap);
    XCTAssertTrue(self.context.getPoints[3].isGap);
    [self assertFinishedPoints:[self latitudes:self.original]];
}

- (void)testDeletingFirstSegmentIsOneUndoStep
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    [self.bridge deleteSegmentWithPointIndexes:@[@0, @1, @2, @3]];
    [self assertFinishedPoints:[self latitudes:[self.original subarrayWithRange:NSMakeRange(4, 4)]]];
    for (OASWptPt *point in self.context.getPoints)
        XCTAssertFalse(point.isGap);
    [self.bridge undo];
    XCTAssertFalse(self.context.commandManager.canUndo);
    [self assertFinishedPoints:[self latitudes:self.original]];
    for (NSInteger index = 0; index < self.original.count; index++)
        XCTAssertEqual(self.context.getPoints[index].isGap, index == 3);
}

- (void)testDeletingLastSegmentIsOneUndoStep
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    [self.bridge deleteSegmentWithPointIndexes:@[@4, @5, @6, @7]];
    [self assertFinishedPoints:[self latitudes:[self.original subarrayWithRange:NSMakeRange(0, 4)]]];
    XCTAssertTrue(self.context.getPoints[3].isGap);
    [self.bridge undo];
    XCTAssertFalse(self.context.commandManager.canUndo);
    [self assertFinishedPoints:[self latitudes:self.original]];
    [self.bridge redo];
    [self assertFinishedPoints:[self latitudes:[self.original subarrayWithRange:NSMakeRange(0, 4)]]];
}

- (void)testSplitDuringInsertionUndoDoesNotLoseSuffix
{
    [self.context splitSegments:4];
    self.context.selectedPointPosition = 1;
    XCTAssertTrue([self.context.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:self.layer after:YES]]);
    [self.context splitSegments:self.context.getAllPoints.count];
    [self.bridge undo];
    XCTAssertEqualObjects([self latitudes:self.context.getAllPoints], [self latitudes:self.original]);
}

- (void)testInvalidTrimDoesNotChangePointsOrHistory
{
    NSArray *expected = [self latitudes:self.context.getAllPoints];
    XCTAssertNoThrow([self.bridge trimBeforeIndex:99]);
    XCTAssertEqualObjects([self latitudes:self.context.getAllPoints], expected);
    XCTAssertFalse(self.context.commandManager.canUndo);
}

- (void)verifyTrimAtIndex:(NSInteger)index before:(BOOL)before
{
    NSArray *expectedPoints = before
        ? [self.original subarrayWithRange:NSMakeRange(index, self.original.count - index)]
        : [self.original subarrayWithRange:NSMakeRange(0, index + 1)];
    if (before)
        [self.bridge trimBeforeIndex:index];
    else
        [self.bridge trimAfterIndex:index];
    [self assertFinishedPoints:[self latitudes:expectedPoints]];
    [self.bridge undo];
    [self assertFinishedPoints:[self latitudes:self.original]];
    [self.bridge redo];
    [self assertFinishedPoints:[self latitudes:expectedPoints]];
}

- (void)testTrimBeforeFirstPointKeepsWholeTrack
{
    [self verifyTrimAtIndex:0 before:YES];
}

- (void)testTrimBeforeLastPointKeepsOnePoint
{
    [self verifyTrimAtIndex:7 before:YES];
}

- (void)testTrimAfterFirstPointKeepsOnePoint
{
    [self verifyTrimAtIndex:0 before:NO];
}

- (void)testTrimAfterLastPointKeepsWholeTrack
{
    [self verifyTrimAtIndex:7 before:NO];
}

- (void)testRejectedTrimPreservesRedoAndChangeCounter
{
    [self addPointNumber:0];
    [self.bridge undo];
    XCTAssertFalse(self.context.hasChanges);
    XCTAssertNoThrow([self.bridge trimAfterIndex:-1]);
    [self assertFinishedPoints:[self latitudes:self.original]];
    XCTAssertFalse(self.context.commandManager.canUndo);
    XCTAssertTrue(self.context.commandManager.canRedo);
    XCTAssertFalse(self.context.hasChanges);
}

- (void)testMapTapDuringMoveDoesNotCreateHistoryEntry
{
    [self.bridge selectPointAtIndex:2];
    OASWptPt *movingPoint = self.context.originalPointToMove;
    [self.bridge onTouch:CLLocationCoordinate2DMake(50.0051, 20.0101) longPress:NO];
    XCTAssertEqual(self.context.getBeforePoints.count, 2);
    XCTAssertEqual(self.context.getAfterPoints.count, 5);
    XCTAssertEqual(self.context.originalPointToMove, movingPoint);
    XCTAssertFalse(self.context.commandManager.canUndo);
    XCTAssertFalse(self.context.hasChanges);
    [self.bridge cancelPointEdit];
    [self assertFinishedPoints:[self latitudes:self.original]];
    [self.bridge undo];
    [self.bridge redo];
    [self assertFinishedPoints:[self latitudes:self.original]];
}

- (void)testMapTapDuringInsertionDoesNotCommitPoint
{
    [self.bridge addPointAfterIndex:2];
    [self.bridge onTouch:CLLocationCoordinate2DMake(50.0051, 20.0101) longPress:NO];
    XCTAssertEqual(self.context.getBeforePoints.count, 3);
    XCTAssertEqual(self.context.getAfterPoints.count, 5);
    XCTAssertFalse(self.context.commandManager.canUndo);
    [self.bridge cancelPointEdit];
    [self assertFinishedPoints:[self latitudes:self.original]];
}

- (void)testMapTapAfterMoveCancelStillAddsPoint
{
    [self.bridge selectPointAtIndex:2];
    [self.bridge cancelPointEdit];
    [self.bridge onTouch:CLLocationCoordinate2DMake(51, 21) longPress:NO];
    XCTAssertEqual(self.context.getPointsCount, 9);
    XCTAssertEqualWithAccuracy(self.context.getPoints.lastObject.lat, 51, DBL_EPSILON);
    XCTAssertTrue(self.context.commandManager.canUndo);
    [self.bridge undo];
    [self assertFinishedPoints:[self latitudes:self.original]];
}

- (void)verifyRoadGeometryHistoryForCommand:(OAMeasurementModeCommand *)command
{
    NSArray<OASWptPt *> *pair = @[self.original[0], self.original[1]];
    OARoadSegmentData *data = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                               start:pair[0] end:pair[1] points:pair segments:{}];
    self.context.roadSegmentData[pair] = data;
    BOOL hadGap = self.original[3].isGap;
    XCTAssertTrue([self.context.commandManager execute:command]);
    for (NSInteger cycle = 0; cycle < 3; cycle++)
    {
        [self.bridge undo];
        XCTAssertEqual(self.context.roadSegmentData.count, 1);
        XCTAssertEqual(self.context.roadSegmentData[pair], data);
        XCTAssertEqualObjects([self latitudes:self.context.roadSegmentData[pair].gpxPoints], [self latitudes:pair]);
        [self assertFinishedPoints:[self latitudes:self.original]];
        XCTAssertEqual(self.context.getPoints[3].isGap, hadGap);
        [self.bridge redo];
        if ([command isKindOfClass:OAJoinPointsCommand.class])
            XCTAssertFalse(self.context.getPoints[3].isGap);
    }
}

- (void)testReverseUndoRestoresRoadGeometryAcrossRepeatedCycles
{
    [self verifyRoadGeometryHistoryForCommand:[[OAReversePointsCommand alloc] initWithLayer:self.layer]];
}

- (void)testJoinUndoRestoresRoadGeometryAcrossRepeatedCycles
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    self.context.selectedPointPosition = 3;
    [self verifyRoadGeometryHistoryForCommand:[[OAJoinPointsCommand alloc] initWithLayer:self.layer]];
}

- (void)testJoinFromNextSegmentUndoRestoresRoadGeometryAcrossRepeatedCycles
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    self.context.selectedPointPosition = 4;
    [self verifyRoadGeometryHistoryForCommand:[[OAJoinPointsCommand alloc] initWithLayer:self.layer]];
}

- (void)testDeleteUndoWithShortenedBeforeHalfDoesNotThrow
{
    [self.bridge deletePointAtIndex:6];
    [self.context splitSegments:2];
    XCTAssertNoThrow([self.bridge undo]);
}

- (void)verifyTrimRejectsIndexInAfterHalf:(BOOL)before
{
    [self.context splitSegments:3];
    self.context.selectedPointPosition = 1;
    if (before)
        [self.bridge trimBeforeIndex:4];
    else
        [self.bridge trimAfterIndex:4];
    XCTAssertEqual(self.context.getBeforePoints.count, 3);
    XCTAssertEqual(self.context.getAfterPoints.count, 5);
    XCTAssertEqual(self.context.selectedPointPosition, 1);
    XCTAssertEqualObjects([self latitudes:self.context.getAllPoints], [self latitudes:self.original]);
    XCTAssertFalse(self.context.commandManager.canUndo);
    XCTAssertFalse(self.context.hasChanges);
}

- (void)testTrimBeforeRejectsIndexInAfterHalf
{
    [self verifyTrimRejectsIndexInAfterHalf:YES];
}

- (void)testTrimAfterRejectsIndexInAfterHalf
{
    [self verifyTrimRejectsIndexInAfterHalf:NO];
}

- (void)testSegmentBoundarySelectionRecognizesBothSegments
{
    [self.original[3] setGap];
    [self.context updateSegmentsForSnap];
    for (NSInteger index = 0; index < self.original.count; index++)
    {
        XCTAssertEqual([self.context isFirstPointSelected:index outer:NO], index == 0 || index == 4);
        XCTAssertEqual([self.context isLastPointSelected:index outer:NO], index == 3 || index == 7);
    }
    XCTAssertFalse([self.context isFirstPointSelected:-1 outer:NO]);
    XCTAssertFalse([self.context isLastPointSelected:8 outer:NO]);
}

@end
