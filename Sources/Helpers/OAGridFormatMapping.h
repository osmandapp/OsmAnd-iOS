//
//  OAGridFormatMapping.h
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#ifndef OAGridFormatMapping_h
#define OAGridFormatMapping_h

#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/MapRendererTypes.h>

inline OsmAnd::GridConfiguration::Projection OACoreProjectionForGridFormat(GridFormat format)
{
    switch (format)
    {
        case GridFormatUtm:
            return OsmAnd::GridConfiguration::Projection::UTM;
        case GridFormatMgrs:
            return OsmAnd::GridConfiguration::Projection::MGRS;
        case GridFormatDms:
        case GridFormatDm:
        case GridFormatDigital:
        default:
            return OsmAnd::GridConfiguration::Projection::WGS84;
    }
}

inline OsmAnd::GridConfiguration::Format OACoreFormatForGridFormat(GridFormat format)
{
    switch (format)
    {
        case GridFormatDms:
            return OsmAnd::GridConfiguration::Format::DMS;
        case GridFormatDm:
            return OsmAnd::GridConfiguration::Format::DM;
        case GridFormatDigital:
        case GridFormatUtm:
        case GridFormatMgrs:
        default:
            return OsmAnd::GridConfiguration::Format::Decimal;
    }
}

#endif /* OAGridFormatMapping_h */
