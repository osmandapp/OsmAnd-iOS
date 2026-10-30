//
//  OAObfFileListOrderTest.mm
//  OsmAnd MapsTests
//
//  The order in which the search reads obf files: the live updates of a region right before the
//  region, the newest first, regions by name, and the same order whatever order the files were found in;
//  around a point the regions nearest first, each still right after its live updates.
//

#import <XCTest/XCTest.h>
#import "OAObfFileList.h"

@interface OAObfFileListOrderTest : XCTestCase

@end

@implementation OAObfFileListOrderTest

// Ids as ResourcesManager makes them: the lowercased file name, "_2" dropped except for live updates.
+ (NSArray<NSString *> *)resourceIds
{
    return @[
        @"andorra_europe.obf",
        @"austria_europe.obf",
        @"belgium_europe.wiki.obf",
        @"europe_wikivoyage.travel.obf",
        @"germany_baden-wuerttemberg_stuttgart_europe.obf",
        @"germany_baden-wuerttemberg_stuttgart_europe_25_10_28.live.obf",
        @"germany_berlin_europe.obf",
        @"germany_berlin_europe.wiki.obf",
        @"germany_berlin_europe_25_09_00.live.obf",
        @"germany_berlin_europe_25_10_27.live.obf",
        @"germany_berlin_europe_25_10_28.live.obf",
        @"germany_brandenburg_europe.obf",
        @"germany_brandenburg_europe_25_10_28.live.obf",
        @"netherlands_noord-holland_europe.obf",
        @"ukraine_kyiv_europe.obf",
        @"ukraine_kyiv_europe_25_10_28.live.obf",
        @"world_basemap.obf",
    ];
}

// The listed order, reversed, and shuffles with fixed seeds: getLocalResources is a QHash, so the
// app hands the ids over in no particular order.
+ (NSArray<NSArray<NSString *> *> *)inputOrders
{
    NSArray<NSString *> *ids = [self resourceIds];
    NSMutableArray<NSArray<NSString *> *> *orders = [NSMutableArray arrayWithObjects:ids, ids.reverseObjectEnumerator.allObjects, nil];
    for (uint32_t seed = 1; seed <= 30; seed++)
    {
        NSMutableArray<NSString *> *shuffled = [ids mutableCopy];
        uint32_t state = seed;
        for (NSUInteger i = shuffled.count - 1; i > 0; i--)
        {
            state = state * 1664525u + 1013904223u;
            [shuffled exchangeObjectAtIndex:i withObjectAtIndex:state % (i + 1)];
        }
        [orders addObject:shuffled];
    }
    return orders;
}

+ (BOOL)isLiveUpdate:(NSString *)resourceId
{
    return [resourceId hasSuffix:@".live.obf"];
}

// "germany_berlin_europe_25_10_28.live.obf" updates "germany_berlin_europe.obf".
+ (NSString *)regionOfLiveUpdate:(NSString *)resourceId
{
    NSString *name = [resourceId stringByReplacingOccurrencesOfString:@".live.obf" withString:@""];
    NSRange date = [name rangeOfString:@"_([0-9]+_){2}[0-9]+$" options:NSRegularExpressionSearch];
    return [[name substringToIndex:date.location] stringByAppendingString:@".obf"];
}

- (void)testTheOrderOfTwoFilesIsTransitive
{
    NSArray<NSString *> *ids = [self.class resourceIds];
    NSMutableDictionary<NSString *, NSNumber *> *before = [NSMutableDictionary dictionary];
    for (NSString *a in ids)
    {
        for (NSString *b in ids)
        {
            if (a == b)
                continue;
            NSString *first = [OAObfFileList sortedForSearch:@[a, b]].firstObject;
            XCTAssertEqualObjects(first, ([OAObfFileList sortedForSearch:@[b, a]].firstObject), @"%@ and %@", a, b);
            before[[NSString stringWithFormat:@"%@ %@", a, b]] = @(first == a);
        }
    }

    NSMutableArray<NSString *> *cycles = [NSMutableArray array];
    for (NSString *a in ids)
    {
        for (NSString *b in ids)
        {
            for (NSString *c in ids)
            {
                if (a == b || b == c || a == c)
                    continue;
                if (before[[NSString stringWithFormat:@"%@ %@", a, b]].boolValue
                    && before[[NSString stringWithFormat:@"%@ %@", b, c]].boolValue
                    && before[[NSString stringWithFormat:@"%@ %@", c, a]].boolValue
                    && [a compare:b] == NSOrderedAscending && [a compare:c] == NSOrderedAscending)
                    [cycles addObject:[NSString stringWithFormat:@"%@ < %@ < %@ < %@", a, b, c, a]];
            }
        }
    }
    NSLog(@"OAObfFileListOrderTest: %lu cycles of three\n%@", (unsigned long)cycles.count, [cycles componentsJoinedByString:@"\n"]);
    XCTAssertEqual(cycles.count, 0u);
}

- (void)testTheOrderDoesNotDependOnTheInputOrder
{
    NSMutableOrderedSet<NSArray<NSString *> *> *results = [NSMutableOrderedSet orderedSet];
    for (NSArray<NSString *> *input in [self.class inputOrders])
        [results addObject:[OAObfFileList sortedForSearch:input]];

    for (NSUInteger i = 0; i < results.count; i++)
        NSLog(@"OAObfFileListOrderTest: order %lu of %lu\n%@", (unsigned long)i + 1, (unsigned long)results.count, [results[i] componentsJoinedByString:@"\n"]);
    XCTAssertEqual(results.count, 1u, @"%lu input orders give %lu orders", (unsigned long)[self.class inputOrders].count, (unsigned long)results.count);
}

- (void)testTheLiveUpdatesOfARegionGoRightBeforeTheRegion
{
    for (NSArray<NSString *> *input in [self.class inputOrders])
    {
        NSArray<NSString *> *sorted = [OAObfFileList sortedForSearch:input];
        for (NSUInteger i = 0; i < sorted.count; i++)
        {
            if (![self.class isLiveUpdate:sorted[i]])
                continue;
            NSUInteger next = i + 1;
            while (next < sorted.count && [self.class isLiveUpdate:sorted[next]])
                next++;
            NSString *region = [self.class regionOfLiveUpdate:sorted[i]];
            XCTAssertTrue(next < sorted.count && [sorted[next] isEqualToString:region],
                          @"%@ is followed by %@, not by %@", sorted[i], next < sorted.count ? sorted[next] : @"nothing", region);
        }
    }
}

// The first file to give a poi claims it, so the newest update, which may have removed it, goes first.
- (void)testTheNewestLiveUpdateOfARegionGoesFirst
{
    for (NSArray<NSString *> *input in [self.class inputOrders])
    {
        NSArray<NSString *> *sorted = [OAObfFileList sortedForSearch:input];
        for (NSUInteger i = 0; i + 1 < sorted.count; i++)
        {
            if (![self.class isLiveUpdate:sorted[i]] || ![self.class isLiveUpdate:sorted[i + 1]])
                continue;
            if (![[self.class regionOfLiveUpdate:sorted[i]] isEqualToString:[self.class regionOfLiveUpdate:sorted[i + 1]]])
                continue;
            XCTAssertEqual([sorted[i] compare:sorted[i + 1]], NSOrderedDescending, @"%@ before %@", sorted[i], sorted[i + 1]);
        }
    }
}

- (void)testRegionsGoByName
{
    for (NSArray<NSString *> *input in [self.class inputOrders])
    {
        NSMutableArray<NSString *> *regions = [NSMutableArray array];
        for (NSString *resourceId in [OAObfFileList sortedForSearch:input])
        {
            if (![self.class isLiveUpdate:resourceId])
                [regions addObject:resourceId];
        }
        NSArray<NSString *> *byName = [regions sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
            return [[a stringByReplacingOccurrencesOfString:@".obf" withString:@""] compare:[b stringByReplacingOccurrencesOfString:@".obf" withString:@""]];
        }];
        XCTAssertEqualObjects(regions, byName);
    }
}

// Around a point near Kyiv: the regions with a distance nearest first, the rest as far away as each other.
+ (double)distanceOf:(NSString *)resourceId
{
    NSDictionary<NSString *, NSNumber *> *distances = @{
        @"ukraine_kyiv_europe.obf": @1,
        @"germany_brandenburg_europe.obf": @2,
        @"germany_berlin_europe.obf": @3,
        @"germany_berlin_europe.wiki.obf": @3,
        @"austria_europe.obf": @4,
    };
    return distances[resourceId] ? distances[resourceId].doubleValue : 10000000.0;
}

- (void)testAroundAPointTheNearestRegionsGoFirstEachAfterItsLiveUpdates
{
    NSArray<NSString *> *expected = @[
        @"ukraine_kyiv_europe_25_10_28.live.obf",
        @"ukraine_kyiv_europe.obf",
        @"germany_brandenburg_europe_25_10_28.live.obf",
        @"germany_brandenburg_europe.obf",
        @"germany_berlin_europe_25_10_28.live.obf",
        @"germany_berlin_europe_25_10_27.live.obf",
        @"germany_berlin_europe_25_09_00.live.obf",
        @"germany_berlin_europe.obf",
        @"germany_berlin_europe.wiki.obf",
        @"austria_europe.obf",
        @"andorra_europe.obf",
        @"belgium_europe.wiki.obf",
        @"europe_wikivoyage.travel.obf",
        @"germany_baden-wuerttemberg_stuttgart_europe_25_10_28.live.obf",
        @"germany_baden-wuerttemberg_stuttgart_europe.obf",
        @"netherlands_noord-holland_europe.obf",
        @"world_basemap.obf",
    ];
    for (NSArray<NSString *> *input in [self.class inputOrders])
    {
        NSArray<NSString *> *sorted = [OAObfFileList sortedForSearch:input distance:^double(NSString *resourceId) {
            return [self.class distanceOf:resourceId];
        }];
        XCTAssertEqualObjects(sorted, expected);
    }
}

- (void)testALiveUpdateWithoutItsRegionIsStillReadLast
{
    NSMutableArray<NSString *> *ids = [[self.class resourceIds] mutableCopy];
    [ids removeObject:@"germany_brandenburg_europe.obf"];
    NSArray<NSString *> *sorted = [OAObfFileList sortedForSearch:ids distance:^double(NSString *resourceId) {
        return [self.class distanceOf:resourceId];
    }];
    XCTAssertEqual(sorted.count, ids.count);
    XCTAssertEqualObjects(sorted.lastObject, @"germany_brandenburg_europe_25_10_28.live.obf");
}

@end
