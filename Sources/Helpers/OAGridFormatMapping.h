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
        case GridFormatOlc:
            return OsmAnd::GridConfiguration::Projection::OLC;
        case GridFormatMaidenhead:
            return OsmAnd::GridConfiguration::Projection::MLS;
        case GridFormatSwissGrid:
        case GridFormatSwissGridPlus:
            return OsmAnd::GridConfiguration::Projection::HOMV2;
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
        case GridFormatOlc:
        case GridFormatMgrs:
        case GridFormatSwissGrid:
        case GridFormatSwissGridPlus:
        case GridFormatMaidenhead:
        default:
            return OsmAnd::GridConfiguration::Format::Decimal;
    }
}

inline OsmAnd::GridConfiguration::Projection OACoreProjectionForRaw(int32_t projectionRaw)
{
    switch (projectionRaw)
    {
        case (int32_t) OsmAnd::GridConfiguration::Projection::OLC:
            return OsmAnd::GridConfiguration::Projection::OLC;
        case (int32_t) OsmAnd::GridConfiguration::Projection::MLS:
            return OsmAnd::GridConfiguration::Projection::MLS;
        case (int32_t) OsmAnd::GridConfiguration::Projection::HOMV2:
            return OsmAnd::GridConfiguration::Projection::HOMV2;
        case (int32_t) OsmAnd::GridConfiguration::Projection::OSTEREO:
            return OsmAnd::GridConfiguration::Projection::OSTEREO;
        case (int32_t) OsmAnd::GridConfiguration::Projection::TM:
            return OsmAnd::GridConfiguration::Projection::TM;
        case (int32_t) OsmAnd::GridConfiguration::Projection::UTM:
            return OsmAnd::GridConfiguration::Projection::UTM;
        case (int32_t) OsmAnd::GridConfiguration::Projection::MGRS:
            return OsmAnd::GridConfiguration::Projection::MGRS;
        case (int32_t) OsmAnd::GridConfiguration::Projection::Mercator:
            return OsmAnd::GridConfiguration::Projection::Mercator;
        case (int32_t) OsmAnd::GridConfiguration::Projection::WGS84:
        default:
            return OsmAnd::GridConfiguration::Projection::WGS84;
    }
}

inline OsmAnd::GridConfiguration::Format OACoreFormatForRaw(int32_t formatRaw)
{
    switch (formatRaw)
    {
        case (int32_t) OsmAnd::GridConfiguration::Format::DMS:
            return OsmAnd::GridConfiguration::Format::DMS;
        case (int32_t) OsmAnd::GridConfiguration::Format::DM:
            return OsmAnd::GridConfiguration::Format::DM;
        case (int32_t) OsmAnd::GridConfiguration::Format::Decimal:
        default:
            return OsmAnd::GridConfiguration::Format::Decimal;
    }
}

#endif /* OAGridFormatMapping_h */
