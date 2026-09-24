//
//  OAGridFormatMappingBridge.mm
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAGridFormatMappingBridge.h"
#import "OAGridFormatMapping.h"

static const int32_t kEpsgTransverseMercator = 9807;
static const int32_t kEpsgObliqueStereographic = 9809;
static const int32_t kEpsgHotineObliqueMercatorV2 = 9815;

static const float kOlcGridGranularity = 3.0f;
static const float kMlsGridGranularity = 6.0f;

static const int32_t kOlcGridMaxZoom = 18;

@implementation OAGridFormatMappingBridge

+ (int32_t)projectionRawForGridFormatRaw:(int32_t)gridFormatRaw
{
    return (int32_t) OACoreProjectionForGridFormat((GridFormat) gridFormatRaw);
}

+ (int32_t)formatRawForGridFormatRaw:(int32_t)gridFormatRaw
{
    return (int32_t) OACoreFormatForGridFormat((GridFormat) gridFormatRaw);
}

+ (int32_t)decimalFormatRaw
{
    return (int32_t) OsmAnd::GridConfiguration::Format::Decimal;
}

+ (NSNumber *)projectionRawForEpsgMethodCode:(int32_t)methodCode
{
    switch (methodCode)
    {
        case kEpsgTransverseMercator:
            return @((int32_t) OsmAnd::GridConfiguration::Projection::TM);
        case kEpsgObliqueStereographic:
            return @((int32_t) OsmAnd::GridConfiguration::Projection::OSTEREO);
        case kEpsgHotineObliqueMercatorV2:
            return @((int32_t) OsmAnd::GridConfiguration::Projection::HOMV2);
        default:
            return nil;
    }
}

+ (NSNumber *)granularityForProjectionRaw:(int32_t)projectionRaw
{
    switch (OACoreProjectionForRaw(projectionRaw))
    {
        case OsmAnd::GridConfiguration::Projection::OLC:
            return @(kOlcGridGranularity);
        case OsmAnd::GridConfiguration::Projection::MLS:
            return @(kMlsGridGranularity);
        default:
            return nil;
    }
}

+ (NSNumber *)maxZoomForProjectionRaw:(int32_t)projectionRaw
{
    if (OACoreProjectionForRaw(projectionRaw) == OsmAnd::GridConfiguration::Projection::OLC)
        return @(kOlcGridMaxZoom);
    return nil;
}

@end
