#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import <OsmAndShared/OsmAndShared.h>
#import "OAApplicationMode.h"
#import "OAGpxData.h"
#import "OAMeasurementEditingContext.h"
#import "OAPlanRouteEditingBridge.h"

static OASWptPt *createPoint(double latitude, double longitude)
{
    OASWptPt *point = [[OASWptPt alloc] init];
    point.lat = latitude;
    point.lon = longitude;
    return point;
}

@interface OAPlanRouteEditingBridge (Testing)

+ (OAMeasurementEditingContext *)editingContextForGpxFile:(OASGpxFile *)gpxFile
                                          applicationMode:(OAApplicationMode *)applicationMode
                                          selectedSegment:(NSInteger)selectedSegment;
+ (nullable NSString *)navigationFilePathForExportedGpx:(OASGpxFile *)gpxFile
                                          sourceFilePath:(nullable NSString *)sourceFilePath;
+ (BOOL)canApplyAttachedTrackWithRoute:(BOOL)hasRoute changes:(BOOL)hasChanges;
+ (EOAPlanRouteNavigationResult)genericNavigationPreflightResultWithContext:(BOOL)hasContext;
- (nullable OASGpxFile *)navigationGpxWithEditingContext:(OAMeasurementEditingContext *)context
                                               trackName:(NSString *)trackName;
+ (EOAPlanRouteNavigationResult)attachNavigationPreflightResultWithContext:(BOOL)hasContext
                                                                  hasRoute:(BOOL)hasRoute
                                                                hasChanges:(BOOL)hasChanges;

@end

@interface OAPlanRouteEditingBridgeTest : XCTestCase

@end

@implementation OAPlanRouteEditingBridgeTest

- (void)testInMemoryGpxWithoutPathLoadsSelectedSegmentWithNavigationMode
{
    OASGpxFile *gpxFile = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OASTrack *track = [[OASTrack alloc] init];
    OASTrkSegment *firstSegment = [[OASTrkSegment alloc] init];
    firstSegment.points = [NSMutableArray arrayWithObjects:createPoint(1, 2), createPoint(2, 3), nil];
    OASTrkSegment *secondSegment = [[OASTrkSegment alloc] init];
    secondSegment.points = [NSMutableArray arrayWithObjects:createPoint(3, 4), createPoint(4, 5), nil];
    track.segments = [NSMutableArray arrayWithObjects:firstSegment, secondSegment, nil];
    gpxFile.tracks = [NSMutableArray arrayWithObject:track];

    OAApplicationMode *applicationMode = OAApplicationMode.BICYCLE;
    OAMeasurementEditingContext *context = [OAPlanRouteEditingBridge editingContextForGpxFile:gpxFile
                                                                              applicationMode:applicationMode
                                                                              selectedSegment:1];
    [context addPoints];

    XCTAssertEqual(gpxFile.path.length, 0);
    XCTAssertEqual(context.gpxData.gpxFile, gpxFile);
    XCTAssertEqual(context.appMode, applicationMode);
    XCTAssertEqual(context.selectedSegment, 1);
    XCTAssertEqual(context.getPoints.count, 2);
    XCTAssertEqualWithAccuracy(context.getPoints.firstObject.lat, 3, DBL_EPSILON);
    XCTAssertEqualWithAccuracy(context.getPoints.lastObject.lon, 5, DBL_EPSILON);
}

- (void)testRoutePointProfileOverridesNavigationMode
{
    OASGpxFile *gpxFile = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OASWptPt *firstPoint = createPoint(1, 2);
    OASWptPt *lastPoint = createPoint(2, 3);
    [lastPoint setProfileTypeProfileType:OAApplicationMode.CAR.stringKey];
    [gpxFile addRoutePointsPoints:@[firstPoint, lastPoint] addRoute:YES];

    OAMeasurementEditingContext *context = [OAPlanRouteEditingBridge editingContextForGpxFile:gpxFile
                                                                              applicationMode:OAApplicationMode.BICYCLE
                                                                              selectedSegment:-1];

    XCTAssertEqual(context.appMode, OAApplicationMode.CAR);
}

- (void)testSourceFilePathOverridesPathlessExportForNavigation
{
    OASGpxFile *exportedGpx = [[OASGpxFile alloc] initWithAuthor:@"test"];
    NSString *sourceFilePath = @"/Documents/GPX/twisty-route.gpx";

    NSString *navigationFilePath = [OAPlanRouteEditingBridge navigationFilePathForExportedGpx:exportedGpx
                                                                               sourceFilePath:sourceFilePath];

    XCTAssertEqualObjects(navigationFilePath, sourceFilePath);
    XCTAssertEqual(exportedGpx.path.length, 0);
}

- (void)testPathlessExportWithoutSourceFilePathKeepsNavigationPathEmpty
{
    OASGpxFile *exportedGpx = [[OASGpxFile alloc] initWithAuthor:@"test"];

    NSString *navigationFilePath = [OAPlanRouteEditingBridge navigationFilePathForExportedGpx:exportedGpx
                                                                               sourceFilePath:nil];

    XCTAssertNil(navigationFilePath);
}

- (void)testAttachApplyRequiresRouteOrChanges
{
    XCTAssertFalse([OAPlanRouteEditingBridge canApplyAttachedTrackWithRoute:NO changes:NO]);
    XCTAssertTrue([OAPlanRouteEditingBridge canApplyAttachedTrackWithRoute:YES changes:NO]);
    XCTAssertTrue([OAPlanRouteEditingBridge canApplyAttachedTrackWithRoute:NO changes:YES]);
    XCTAssertTrue([OAPlanRouteEditingBridge canApplyAttachedTrackWithRoute:YES changes:YES]);
}

- (void)testGenericNavigationAllowsUnchangedPlainTrack
{
    OASGpxFile *gpxFile = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OASTrack *track = [[OASTrack alloc] init];
    OASTrkSegment *segment = [[OASTrkSegment alloc] init];
    segment.points = [NSMutableArray arrayWithObjects:createPoint(1, 2), createPoint(2, 3), nil];
    track.segments = [NSMutableArray arrayWithObject:segment];
    gpxFile.tracks = [NSMutableArray arrayWithObject:track];

    OAMeasurementEditingContext *context = [OAPlanRouteEditingBridge editingContextForGpxFile:gpxFile
                                                                              applicationMode:OAApplicationMode.CAR
                                                                              selectedSegment:-1];
    [context addPoints];
    EOAPlanRouteNavigationResult result =
        [OAPlanRouteEditingBridge genericNavigationPreflightResultWithContext:context != nil];
    OASGpxFile *navigationGpx = [[[OAPlanRouteEditingBridge alloc] init] navigationGpxWithEditingContext:context
                                                                                           trackName:@"plain-track"];

    XCTAssertFalse(context.hasRoute);
    XCTAssertFalse(context.hasChanges);
    XCTAssertEqual(result, EOAPlanRouteNavigationResultSuccess);
    XCTAssertNotNil(navigationGpx);
    XCTAssertEqual(navigationGpx.path.length, 0);
}

- (void)testAttachApplyPreflightReportsFailureReason
{
    EOAPlanRouteNavigationResult invalidContext =
        [OAPlanRouteEditingBridge attachNavigationPreflightResultWithContext:NO
                                                                    hasRoute:NO
                                                                  hasChanges:NO];
    EOAPlanRouteNavigationResult missingApproximation =
        [OAPlanRouteEditingBridge attachNavigationPreflightResultWithContext:YES
                                                                    hasRoute:NO
                                                                  hasChanges:NO];
    EOAPlanRouteNavigationResult success =
        [OAPlanRouteEditingBridge attachNavigationPreflightResultWithContext:YES
                                                                    hasRoute:YES
                                                                  hasChanges:NO];

    XCTAssertEqual(invalidContext, EOAPlanRouteNavigationResultInvalidContext);
    XCTAssertEqual(missingApproximation, EOAPlanRouteNavigationResultMissingApproximationResult);
    XCTAssertEqual(success, EOAPlanRouteNavigationResultSuccess);
}

@end
