#pragma once

#include <OsmAndCore/Utilities.h>
#include <QVector>
#include <algorithm>
#include <cstdint>

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
}
