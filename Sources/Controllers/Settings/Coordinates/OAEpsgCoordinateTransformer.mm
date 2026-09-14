//
//  OAEpsgCoordinateTransformer.m
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAEpsgCoordinateTransformer.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapRendererTypes.h>
#include <OsmAndCore/QtExtensions.h>
#include <QString>

#include <memory>
#include <unordered_map>

@implementation OAEpsgPoint
@end

@implementation OAEpsgCoordinateTransformer
{
    std::unordered_map<int, std::unique_ptr<OsmAnd::CoordinateTransformer>> _transformers;
    NSLock *_lock;
}

+ (instancetype)sharedInstance
{
    static OAEpsgCoordinateTransformer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OAEpsgCoordinateTransformer alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
        _lock = [[NSLock alloc] init];
    return self;
}

- (OsmAnd::CoordinateTransformer *)transformerForCode:(int)code
{
    if (code <= 0)
        return nullptr;

    [_lock lock];
    auto it = _transformers.find(code);
    if (it != _transformers.end())
    {
        auto *existing = it->second.get();
        [_lock unlock];
        return existing;
    }

    NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/proj"];
    auto created = std::make_unique<OsmAnd::CoordinateTransformer>(QString::fromNSString(path), code);
    auto *ptr = created.get();
    _transformers[code] = std::move(created);
    [_lock unlock];
    return ptr;
}

- (OAEpsgPoint *)fromLonLatWithCode:(NSInteger)epsgCode lon:(double)lon lat:(double)lat
{
    auto *transformer = [self transformerForCode:(int)epsgCode];
    if (!transformer)
        return nil;

    OsmAnd::PointD point(lon, lat);
    if (!transformer->fromLonLat(point))
        return nil;

    OAEpsgPoint *result = [OAEpsgPoint new];
    result.easting = point.x;
    result.northing = point.y;
    return result;
}

- (CLLocation *)toLonLatWithCode:(NSInteger)epsgCode easting:(double)easting northing:(double)northing
{
    auto *transformer = [self transformerForCode:(int)epsgCode];
    if (!transformer)
        return nil;

    OsmAnd::PointD point(easting, northing);
    if (!transformer->toLonLat(point))
        return nil;

    return [[CLLocation alloc] initWithLatitude:point.y longitude:point.x];
}

@end
