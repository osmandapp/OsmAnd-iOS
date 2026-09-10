#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import <OsmAndShared/OsmAndShared.h>
#import "OAApplicationMode.h"
#import "OAGpxData.h"
#import "OAMapActions.h"
#import "OAMeasurementEditingContext.h"
#import "OAPlanRouteEditingBridge.h"
#import "OARoutingHelper.h"

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
+ (BOOL)shouldNavigateDirectlyToPointWithPointCount:(NSInteger)pointCount;
+ (BOOL)shouldRequestApproximationBeforeNavigationWithPointCount:(NSInteger)pointCount
                                                        hasRoute:(BOOL)hasRoute
                                             approximationNeeded:(BOOL)approximationNeeded;
- (nullable OASGpxFile *)navigationGpxWithEditingContext:(OAMeasurementEditingContext *)context
                                               trackName:(NSString *)trackName;
- (void)performNavigationWithGpx:(OASGpxFile *)gpx
                  editingContext:(OAMeasurementEditingContext *)context
                   routingHelper:(OARoutingHelper *)routingHelper
                      mapActions:(OAMapActions *)mapActions
                 followTrackMode:(BOOL)followTrackMode
                  sourceFilePath:(nullable NSString *)sourceFilePath;
+ (EOAPlanRouteNavigationResult)attachNavigationPreflightResultWithContext:(BOOL)hasContext
                                                                  hasRoute:(BOOL)hasRoute
                                                                hasChanges:(BOOL)hasChanges;

@end

@interface OAPlanRouteTestRoutingHelper : NSObject

@end

@implementation OAPlanRouteTestRoutingHelper

- (BOOL)isFollowingMode
{
    return NO;
}

@end

@interface OAPlanRouteTestMapActions : NSObject

@property (nonatomic) OAApplicationMode *capturedAppMode;

@end

@implementation OAPlanRouteTestMapActions

- (void)stopNavigationWithoutConfirm
{
}

- (void)enterRoutePlanningModeGivenGpx:(OASGpxFile *)gpxFile
                               appMode:(OAApplicationMode *)appMode
                                  path:(NSString *)path
                                  from:(CLLocation *)from
                              fromName:(OAPointDescription *)fromName
        useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault
                            showDialog:(BOOL)showDialog
{
    self.capturedAppMode = appMode;
}

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

- (void)testGenericNavigationPassesNilForDefaultEditingMode
{
    OAPlanRouteEditingBridge *bridge = [[OAPlanRouteEditingBridge alloc] init];
    OAMeasurementEditingContext *context = [[OAMeasurementEditingContext alloc] init];
    context.appMode = OAApplicationMode.DEFAULT;
    OAPlanRouteTestRoutingHelper *routingHelper = [[OAPlanRouteTestRoutingHelper alloc] init];
    OAPlanRouteTestMapActions *mapActions = [[OAPlanRouteTestMapActions alloc] init];

    [bridge performNavigationWithGpx:[[OASGpxFile alloc] initWithAuthor:@"test"]
                       editingContext:context
                        routingHelper:(OARoutingHelper *)routingHelper
                           mapActions:(OAMapActions *)mapActions
                      followTrackMode:NO
                       sourceFilePath:nil];

    XCTAssertNil(mapActions.capturedAppMode);
}

- (void)testGenericNavigationPreservesExplicitEditingMode
{
    OAPlanRouteEditingBridge *bridge = [[OAPlanRouteEditingBridge alloc] init];
    OAMeasurementEditingContext *context = [[OAMeasurementEditingContext alloc] init];
    context.appMode = OAApplicationMode.BICYCLE;
    OAPlanRouteTestRoutingHelper *routingHelper = [[OAPlanRouteTestRoutingHelper alloc] init];
    OAPlanRouteTestMapActions *mapActions = [[OAPlanRouteTestMapActions alloc] init];

    [bridge performNavigationWithGpx:[[OASGpxFile alloc] initWithAuthor:@"test"]
                       editingContext:context
                        routingHelper:(OARoutingHelper *)routingHelper
                           mapActions:(OAMapActions *)mapActions
                      followTrackMode:NO
                       sourceFilePath:nil];

    XCTAssertEqual(mapActions.capturedAppMode, OAApplicationMode.BICYCLE);
}

- (void)testGenericNavigationUsesDirectDestinationOnlyForOnePoint
{
    XCTAssertFalse([OAPlanRouteEditingBridge shouldNavigateDirectlyToPointWithPointCount:0]);
    XCTAssertTrue([OAPlanRouteEditingBridge shouldNavigateDirectlyToPointWithPointCount:1]);
    XCTAssertFalse([OAPlanRouteEditingBridge shouldNavigateDirectlyToPointWithPointCount:2]);
}

- (void)testGenericNavigationRequestsApproximationBeforeExport
{
    XCTAssertTrue([OAPlanRouteEditingBridge shouldRequestApproximationBeforeNavigationWithPointCount:928
                                                                                              hasRoute:NO
                                                                                   approximationNeeded:YES]);
    XCTAssertFalse([OAPlanRouteEditingBridge shouldRequestApproximationBeforeNavigationWithPointCount:928
                                                                                               hasRoute:YES
                                                                                    approximationNeeded:YES]);
    XCTAssertFalse([OAPlanRouteEditingBridge shouldRequestApproximationBeforeNavigationWithPointCount:928
                                                                                               hasRoute:NO
                                                                                    approximationNeeded:NO]);
    XCTAssertFalse([OAPlanRouteEditingBridge shouldRequestApproximationBeforeNavigationWithPointCount:1
                                                                                               hasRoute:NO
                                                                                    approximationNeeded:YES]);
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
