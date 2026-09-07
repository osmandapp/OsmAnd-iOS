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

@end
