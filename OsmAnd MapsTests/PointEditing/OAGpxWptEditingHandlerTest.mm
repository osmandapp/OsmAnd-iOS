#import <XCTest/XCTest.h>
#import "OAGpxWptEditingHandler.h"
#import "OADefaultFavorite.h"
#import "OsmAndSharedWrapper.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAGpxWptEditingHandlerTest : XCTestCase

@end

@implementation OAGpxWptEditingHandlerTest

- (OAGpxWptEditingHandler *)handlerWithFile:(OASGpxFile *)file
{
    OAGpxWptEditingHandler *handler = [[OAGpxWptEditingHandler alloc] init];
    [handler setValue:file forKey:@"gpxDocument"];
    return handler;
}

- (OASWptPt *)pointWithCategory:(NSString *)category color:(UIColor *)color
{
    OASWptPt *point = [[OASWptPt alloc] init];
    point.category = category;
    [point setColorColor:[[OASInt alloc] initWithInt:color ? [color toARGBNumber] : 0]];
    return point;
}

- (void)assertGroup:(NSString *)name color:(UIColor *)color handler:(OAGpxWptEditingHandler *)handler
{
    NSString *expectedColor = color.toHexARGBString;
    XCTAssertEqualObjects([handler getGroupsWithColors][name], expectedColor);
    NSUInteger matchingGroups = 0;
    for (NSDictionary<NSString *, NSString *> *group in [handler getGroups])
    {
        if ([group[@"category"] isEqualToString:name])
        {
            matchingGroups++;
            XCTAssertEqualObjects(group[@"color"], expectedColor);
        }
    }
    XCTAssertEqual(matchingGroups, 1);
}

- (void)testEmptyTrackDefaultGroupUsesPointColor
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [self assertGroup:@""
               color:[OADefaultFavorite getDefaultColor]
             handler:[self handlerWithFile:file]];
}

- (void)testPendingGroupColorIsAvailableByName
{
    OAGpxWptEditingHandler *handler = [self handlerWithFile:[[OASGpxFile alloc] initWithAuthor:@"test"]];
    OASGpxUtilitiesPointsGroup *group = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"New group" iconName:nil backgroundType:nil color:UIColor.blueColor.toARGBNumber hidden:NO];
    [handler setValue:[NSMutableArray arrayWithObject:group] forKey:@"pendingGroups"];
    [self assertGroup:@"New group" color:UIColor.blueColor handler:handler];
    XCTAssertNil([handler getGroupsWithColors][@"title"]);
    XCTAssertNil([handler getGroupsWithColors][@"color"]);
}

- (void)testGroupMetadataOverridesIndividualPointColorWithoutMutatingPoint
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OASWptPt *point = [self pointWithCategory:@"Group" color:UIColor.redColor];
    [file addPointPoint:point];
    file.pointsGroups[@"Group"].color = [UIColor.greenColor toARGBNumber];
    [self assertGroup:@"Group" color:UIColor.greenColor handler:[self handlerWithFile:file]];
    XCTAssertEqual([point getColor], [UIColor.redColor toARGBNumber]);
    XCTAssertEqual(file.getPointsList.count, 1);
}

- (void)testEmptyGroupUsesMetadataAndPreservesVisibility
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    file.pointsGroups[@"Empty"] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"Empty" iconName:@"" backgroundType:@"" color:[UIColor.blueColor toARGBNumber] hidden:YES];
    OAGpxWptEditingHandler *handler = [self handlerWithFile:file];
    [self assertGroup:@"Empty" color:UIColor.blueColor handler:handler];
    for (NSDictionary<NSString *, NSString *> *group in [handler getGroups])
    {
        if ([group[@"title"] isEqualToString:@"Empty"])
        {
            XCTAssertEqualObjects(group[@"count"], @"0");
            XCTAssertEqualObjects(group[@"hidden"], @"true");
        }
    }
}

- (void)testGroupWithoutMetadataPreservesLegacyPointColor
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [file addPointPoint:[self pointWithCategory:@"Legacy" color:UIColor.blueColor]];
    [file.pointsGroups removeAllObjects];
    [self assertGroup:@"Legacy" color:UIColor.blueColor handler:[self handlerWithFile:file]];
}

- (void)testMissingColorFallsBackButExplicitRedIsPreserved
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [file addPointPoint:[self pointWithCategory:@"No color" color:nil]];
    [file addPointPoint:[self pointWithCategory:@"Red" color:UIColor.redColor]];
    OAGpxWptEditingHandler *handler = [self handlerWithFile:file];
    [self assertGroup:@"No color" color:[OADefaultFavorite getDefaultColor] handler:handler];
    [self assertGroup:@"Red" color:UIColor.redColor handler:handler];
    XCTAssertNil([handler getGroupsWithColors][@"Unknown"]);
}

- (void)testDefaultGroupUsesMetadataWithUnnamedPoints
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [file addPointPoint:[self pointWithCategory:@"" color:UIColor.redColor]];
    file.pointsGroups[@""].color = [UIColor.blueColor toARGBNumber];
    [self assertGroup:@"" color:UIColor.blueColor handler:[self handlerWithFile:file]];
}


- (void)testDefaultAndNamedWaypointsHaveSeparateKeys
{
    NSString *name = OALocalizedString(@"shared_string_waypoints");
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    file.pointsGroups[@""] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"" iconName:@"" backgroundType:@"" color:UIColor.blueColor.toARGBNumber hidden:NO];
    file.pointsGroups[name] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:name iconName:@"" backgroundType:@"" color:UIColor.greenColor.toARGBNumber hidden:NO];
    OAGpxWptEditingHandler *handler = [self handlerWithFile:file];
    [self assertGroup:@"" color:UIColor.blueColor handler:handler];
    [self assertGroup:name color:UIColor.greenColor handler:handler];
    XCTAssertEqual([handler getGroupsWithColors].count, 2);
}

- (void)testReturnedCollectionsAndGroupRecordsAreImmutable
{
    OAGpxWptEditingHandler *handler = [self handlerWithFile:[[OASGpxFile alloc] initWithAuthor:@"test"]];
    OASGpxUtilitiesPointsGroup *group = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"New group" iconName:nil backgroundType:nil color:UIColor.blueColor.toARGBNumber hidden:NO];
    [handler setValue:[NSMutableArray arrayWithObject:group] forKey:@"pendingGroups"];
    NSArray *groups = [handler getGroups];
    XCTAssertFalse([groups isKindOfClass:NSMutableArray.class]);
    for (NSDictionary *group in groups)
        XCTAssertFalse([group isKindOfClass:NSMutableDictionary.class]);
    XCTAssertFalse([[handler getGroupsWithColors] isKindOfClass:NSMutableDictionary.class]);
}
@end
