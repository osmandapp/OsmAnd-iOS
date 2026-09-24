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

@interface OAMeasurementToolLayer (HistoryTesting)
- (void)drawRouteSegments;
@end

@interface OAPlanRouteEditingBridge (HistoryTouchTesting)
- (void)onTouch:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress;
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
@end

@implementation OAPlanRouteHistoryBridge
- (OAMeasurementToolLayer *)layer { return self.testLayer; }
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

- (void)testContinueWithDifferentProfilePreservesExistingLegs
{
    OAWptPtPair *pair = [OAWptPtPair pairWithFirst:self.original[0] second:self.original[1]];
    OARoadSegmentData *geometry = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                                   start:pair.first end:pair.second points:@[pair.first, pair.second] segments:@[]];
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
    OAWptPtPair *pair = [OAWptPtPair pairWithFirst:self.original[0] second:self.original[1]];
    OARoadSegmentData *data = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                               start:pair.first end:pair.second points:@[pair.first, pair.second] segments:@[]];
    self.context.roadSegmentData[pair] = data;
    [self.bridge trimBeforeIndex:4];
    for (NSInteger i = 0; i < 3; i++)
    {
        [self.bridge undo];
        XCTAssertEqual(self.context.roadSegmentData.count, 1);
        XCTAssertEqualObjects([self latitudes:self.context.roadSegmentData[pair].gpxPoints], ([self latitudes:@[pair.first, pair.second]]));
        [self.bridge redo];
    }
}

- (void)testClearAllUndoRestoresRoadGeometry
{
    OAWptPtPair *pair = [OAWptPtPair pairWithFirst:self.original[0] second:self.original[1]];
    self.context.roadSegmentData[pair] = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                                          start:pair.first end:pair.second points:@[pair.first, pair.second] segments:@[]];
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
    OAWptPtPair *pair = [OAWptPtPair pairWithFirst:self.original[0] second:self.original[1]];
    OARoadSegmentData *data = [[OARoadSegmentData alloc] initWithAppMode:OAApplicationMode.DEFAULT
                                                               start:pair.first end:pair.second points:@[pair.first, pair.second] segments:@[]];
    self.context.roadSegmentData[pair] = data;
    BOOL hadGap = self.original[3].isGap;
    XCTAssertTrue([self.context.commandManager execute:command]);
    for (NSInteger cycle = 0; cycle < 3; cycle++)
    {
        [self.bridge undo];
        XCTAssertEqual(self.context.roadSegmentData.count, 1);
        XCTAssertEqual(self.context.roadSegmentData[pair], data);
        XCTAssertEqualObjects([self latitudes:self.context.roadSegmentData[pair].gpxPoints], ([self latitudes:@[pair.first, pair.second]]));
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
