#pragma once

#include <OsmAndCore/Utilities.h>
#include <QVector>
#include <QMap>
#include <QSet>
#include <algorithm>
#include <cstdint>
#include <functional>

namespace OARasterTileCoordinates
{
    inline OsmAnd::PointD rowAndOffset(int y, int zoom, int tileSize)
    {
        const auto latitude = OsmAnd::Utilities::getLatitudeFromTile(zoom, y);
        return OsmAnd::Utilities::getTileEllipsoidNumberAndOffsetY(zoom, latitude, tileSize);
    }

    inline QVector<OsmAnd::AreaI> tileAreas(const OsmAnd::AreaI& shiftedArea, int zoom, bool ellipsoid, int tileSize)
    {
        if (zoom < OsmAnd::MinZoomLevel || zoom > OsmAnd::MaxZoomLevel)
            return {};

        const int64_t world = int64_t(1) << 31;
        const int64_t halfWorld = world / 2;
        const int64_t tileSize31 = int64_t(1) << (31 - zoom);
        const int64_t tileCount = int64_t(1) << zoom;
        const int64_t left31 = int64_t(shiftedArea.left()) + halfWorld;
        const int64_t right31 = int64_t(shiftedArea.right()) + halfWorld;
        const int64_t top31 = std::max(int64_t(0), int64_t(shiftedArea.top()) + halfWorld);
        const int64_t bottom31 = std::min(world - 1, int64_t(shiftedArea.bottom()) + halfWorld);
        if (left31 > right31 || top31 > bottom31)
            return {};

        int top = top31 / tileSize31;
        int bottom = bottom31 / tileSize31;
        if (ellipsoid)
        {
            const auto first = rowAndOffset(top, zoom, tileSize);
            const auto last = rowAndOffset(bottom, zoom, tileSize);
            top = first.x;
            bottom = int(last.x) + (last.y > 0 ? 1 : 0);
        }
        top = std::max(0, top);
        bottom = std::min(tileCount - 1, int64_t(bottom));
        if (top > bottom)
            return {};

        if (right31 - left31 >= world - 1)
            return {OsmAnd::AreaI(top, 0, bottom, tileCount - 1)};

        const auto normalizedLeft = (left31 % world + world) % world;
        const auto normalizedRight = (right31 % world + world) % world;
        const int left = normalizedLeft / tileSize31;
        const int right = normalizedRight / tileSize31;
        if (normalizedLeft <= normalizedRight)
            return {OsmAnd::AreaI(top, left, bottom, right)};
        if (left <= right)
            return {OsmAnd::AreaI(top, 0, bottom, tileCount - 1)};
        return {OsmAnd::AreaI(top, left, bottom, tileCount - 1), OsmAnd::AreaI(top, 0, bottom, right)};
    }

    inline QMap<OsmAnd::ZoomLevel, QSet<OsmAnd::TileId>> updateTiles(
        const OsmAnd::AreaI& visibleArea, int zoom, int minZoom, int maxZoom,
        int maxZoomShift, int maxUnderZoomShift, int zoomOffset,
        const std::function<bool(OsmAnd::TileId, OsmAnd::ZoomLevel)>& hasImage)
    {
        QMap<OsmAnd::ZoomLevel, QSet<OsmAnd::TileId>> result;
        if (zoom < 0 || zoom > 31 || minZoom > maxZoom
            || zoom - maxZoom > maxZoomShift || minZoom - zoom > maxUnderZoomShift)
            return result;

        auto include = [&](OsmAnd::TileId tile, int level) {
            for (const auto& area : tileAreas(visibleArea, level, false, 256))
            {
                if (tile.x >= area.left() && tile.x <= area.right()
                    && tile.y >= area.top() && tile.y <= area.bottom())
                {
                    result[static_cast<OsmAnd::ZoomLevel>(level)].insert(tile);
                    break;
                }
            }
        };
        auto children = [&](OsmAnd::TileId tile, int level, bool requireAll) {
            if (level < minZoom || level > maxZoom || level > 31)
                return false;
            const auto ids = OsmAnd::Utilities::getTileIdsUnderscaledByZoomShift(tile, level - zoom);
            bool any = false;
            bool all = true;
            for (const auto& id : ids)
            {
                const bool present = hasImage(id, static_cast<OsmAnd::ZoomLevel>(level));
                any |= present;
                all &= present;
            }
            if (!(requireAll ? all : any))
                return false;
            for (const auto& id : ids)
                include(id, level);
            return true;
        };

        for (const auto& area : tileAreas(visibleArea, zoom, false, 256))
        {
            for (int64_t x = area.left(); x <= area.right(); x++)
            {
                for (int64_t y = area.top(); y <= area.bottom(); y++)
                {
                    const auto tile = OsmAnd::TileId::fromXY(static_cast<int32_t>(x), static_cast<int32_t>(y));
                    bool found = false;
                    for (int level = std::min(31, zoom + std::min(zoomOffset, maxUnderZoomShift)); level > zoom; level--)
                    {
                        if (children(tile, level, true))
                        {
                            found = true;
                            break;
                        }
                    }
                    if (zoom >= minZoom && zoom <= maxZoom)
                    {
                        include(tile, zoom);
                        found |= hasImage(tile, static_cast<OsmAnd::ZoomLevel>(zoom));
                    }
                    if (found)
                        continue;
                    for (int shift = 1; shift <= maxZoomShift; shift++)
                    {
                        if (shift <= maxUnderZoomShift && children(tile, zoom + shift, false))
                            break;
                        const int level = zoom - shift;
                        if (level < minZoom || level > maxZoom || level < 0)
                            continue;
                        const auto parent = OsmAnd::Utilities::getTileIdOverscaledByZoomShift(tile, shift);
                        if (hasImage(parent, static_cast<OsmAnd::ZoomLevel>(level)))
                        {
                            include(parent, level);
                            break;
                        }
                    }
                }
            }
        }
        return result;
    }
}
