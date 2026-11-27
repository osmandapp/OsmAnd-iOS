#import <XCTest/XCTest.h>
#include "OARasterTileCoordinates.h"

namespace
{
    OsmAnd::AreaI visibleTile(int zoom, int x, int y)
    {
        const int64_t unit = int64_t(1) << (31 - zoom);
        const int64_t half = int64_t(1) << 30;
        return OsmAnd::AreaI(y * unit + unit / 4 - half, x * unit + unit / 4 - half,
            y * unit + 3 * unit / 4 - half, x * unit + 3 * unit / 4 - half);
    }

    using Tiles = QMap<OsmAnd::ZoomLevel, QSet<OsmAnd::TileId>>;

    Tiles resolve(const OsmAnd::AreaI& area, const Tiles& cached, int minZoom = 10,
        int maxZoom = 18, int maxShift = 5, int underShift = 2, int detail = 0)
    {
        return OARasterTileCoordinates::updateTiles(area, 17, minZoom, maxZoom, maxShift, underShift, detail,
            [&](OsmAnd::TileId id, OsmAnd::ZoomLevel zoom) { return cached.value(zoom).contains(id); });
    }
}

@interface OARasterTileUpdateTests : XCTestCase
@end

@implementation OARasterTileUpdateTests

- (void)testExactImagePreservesCachedParentsAndChildren
{
    const auto tile = OsmAnd::TileId::fromXY(100, 200);
    const Tiles cache = {{OsmAnd::ZoomLevel17, {tile}},
        {OsmAnd::ZoomLevel16, {OsmAnd::TileId::fromXY(50, 100)}},
        {OsmAnd::ZoomLevel18, {OsmAnd::TileId::fromXY(200, 400)}}};
    const auto result = resolve(visibleTile(17, 100, 200), cache);
    XCTAssertEqual(result.size(), 1);
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel17).contains(tile));
}

- (void)testMissingExactImageSelectsNearestParent
{
    const auto parent = OsmAnd::TileId::fromXY(50, 100);
    const Tiles cache = {{OsmAnd::ZoomLevel16, {parent}},
        {OsmAnd::ZoomLevel15, {OsmAnd::TileId::fromXY(25, 50)}}};
    const auto result = resolve(visibleTile(17, 100, 200), cache);
    XCTAssertEqual(result.size(), 2);
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel16).contains(parent));
    XCTAssertFalse(result.contains(OsmAnd::ZoomLevel15));
}

- (void)testMissingTwoLevelsSelectsSecondParent
{
    const auto parent = OsmAnd::TileId::fromXY(25, 50);
    const auto result = resolve(visibleTile(17, 100, 200), {{OsmAnd::ZoomLevel15, {parent}}});
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel15).contains(parent));
    XCTAssertFalse(result.contains(OsmAnd::ZoomLevel16));
}

- (void)testMoreDetailedFallbackWinsAtEqualDistance
{
    const auto child = OsmAnd::TileId::fromXY(200, 400);
    const auto result = resolve(visibleTile(17, 100, 200),
        {{OsmAnd::ZoomLevel18, {child}}, {OsmAnd::ZoomLevel16, {OsmAnd::TileId::fromXY(50, 100)}}});
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel18).contains(child));
    XCTAssertFalse(result.contains(OsmAnd::ZoomLevel16));
}

- (void)testProviderShiftLimitPreservesTooDistantParents
{
    const auto result = resolve(visibleTile(17, 100, 200),
        {{OsmAnd::ZoomLevel15, {OsmAnd::TileId::fromXY(25, 50)}}}, 10, 18, 1);
    XCTAssertEqual(result.size(), 1);
    XCTAssertTrue(result.contains(OsmAnd::ZoomLevel17));
}

- (void)testSourceMaximumSelectsScaledTiles
{
    const auto parent = OsmAnd::TileId::fromXY(50, 100);
    const auto result = resolve(visibleTile(17, 100, 200), {{OsmAnd::ZoomLevel16, {parent}}}, 10, 16);
    XCTAssertEqual(result.size(), 1);
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel16).contains(parent));
}

- (void)testNoImagesStillInvalidatesExactNegativeCache
{
    const auto result = resolve(visibleTile(17, 100, 200), {});
    XCTAssertEqual(result.size(), 1);
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel17).contains(OsmAnd::TileId::fromXY(100, 200)));
}

- (void)testNeighboringParentsRemainOutsideSelection
{
    const auto selected = OsmAnd::TileId::fromXY(50, 100);
    const auto neighbor = OsmAnd::TileId::fromXY(51, 100);
    const auto result = resolve(visibleTile(17, 100, 200), {{OsmAnd::ZoomLevel16, {selected, neighbor}}});
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel16).contains(selected));
    XCTAssertFalse(result.value(OsmAnd::ZoomLevel16).contains(neighbor));
}

- (void)testMixedFallbackLevelsAreResolvedPerVisibleTile
{
    auto area = visibleTile(17, 100, 200);
    area.enlargeToInclude(visibleTile(17, 103, 200).bottomRight);
    const auto first = OsmAnd::TileId::fromXY(50, 100);
    const auto second = OsmAnd::TileId::fromXY(25, 50);
    const auto result = resolve(area, {{OsmAnd::ZoomLevel16, {first}}, {OsmAnd::ZoomLevel15, {second}}});
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel16).contains(first));
    XCTAssertTrue(result.value(OsmAnd::ZoomLevel15).contains(second));
}

- (void)testAntimeridianKeepsOnlyEdgeParents
{
    const int64_t half = int64_t(1) << 30;
    const int64_t unit = int64_t(1) << (31 - 17);
    const OsmAnd::AreaI area(200 * unit - half, int64_t(1) * half - unit / 4,
        201 * unit - half - 1, int64_t(1) * half + unit / 4);
    const auto west = OsmAnd::TileId::fromXY(0, 100);
    const auto east = OsmAnd::TileId::fromXY(65535, 100);
    const auto middle = OsmAnd::TileId::fromXY(32768, 100);
    const auto result = resolve(area, {{OsmAnd::ZoomLevel16, {west, east, middle}}});
    XCTAssertEqual(result.value(OsmAnd::ZoomLevel16).size(), 2);
    XCTAssertFalse(result.value(OsmAnd::ZoomLevel16).contains(middle));
}

- (void)testDetailLevelPrefersCompleteChildrenOverExactImage
{
    const auto tile = OsmAnd::TileId::fromXY(100, 200);
    const auto children = OsmAnd::Utilities::getTileIdsUnderscaledByZoomShift(tile, 1);
    const Tiles cache = {{OsmAnd::ZoomLevel17, {tile}},
        {OsmAnd::ZoomLevel18, QSet<OsmAnd::TileId>(children.begin(), children.end())}};
    const auto result = resolve(visibleTile(17, 100, 200), cache, 10, 18, 5, 2, 1);
    XCTAssertTrue(result.contains(OsmAnd::ZoomLevel18));
}

- (void)testPartialDetailFallsBackToExactImage
{
    const auto tile = OsmAnd::TileId::fromXY(100, 200);
    const auto result = resolve(visibleTile(17, 100, 200),
        {{OsmAnd::ZoomLevel17, {tile}}, {OsmAnd::ZoomLevel18, {OsmAnd::TileId::fromXY(200, 400)}}}, 10, 18, 5, 2, 1);
    XCTAssertFalse(result.contains(OsmAnd::ZoomLevel18));
}

@end
