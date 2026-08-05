//
//  OAPOIMapLayerData.m
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 05.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPOIMapLayerData.h"
#import "OAPOI.h"
#import "OAPOIUIFilter.h"
#import "OAResultMatcher.h"

#include <OsmAndCore/Utilities.h>
#include <vector>
#include <cmath>

@implementation OAPOIMapLayerData
{
    OAPOIUIFilter *_filter;
    NSArray<OAPOI *> *_results;
    NSArray<OAPOI *> *_displayedResults;
    uint64_t _generation;
    dispatch_queue_t _queryQueue;

    BOOL _hasExtendedCache;
    double _extTop;
    double _extLeft;
    double _extBottom;
    double _extRight;
    int _extZoom;
}

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _filter = filter;
        _generation = 0;
        _hasExtendedCache = NO;
        _queryQueue = dispatch_queue_create("com.osmand.poi.mapLayerData", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (OAPOIUIFilter *)filter { return _filter; }
- (NSArray<OAPOI *> *)results { return _results; }
- (NSArray<OAPOI *> *)displayedResults { return _displayedResults; }

- (void)clear
{
    _generation++;
    _results = nil;
    _displayedResults = nil;
    _hasExtendedCache = NO;
}

- (BOOL)extendedCacheContainsTop:(double)top
                            left:(double)left
                          bottom:(double)bottom
                           right:(double)right
                            zoom:(int)zoom
{
    if (!_hasExtendedCache)
        return NO;
    if (std::abs(zoom - _extZoom) > kPoiMapLayerZoomThreshold)
        return NO;

    return top <= _extTop
        && bottom >= _extBottom
        && left >= _extLeft
        && right <= _extRight;
}

- (BOOL)coversTop:(double)top
             left:(double)left
           bottom:(double)bottom
            right:(double)right
             zoom:(int)zoom
{
    return [self extendedCacheContainsTop:top left:left bottom:bottom right:right zoom:zoom];
}

- (void)queryNewDataTop:(double)top
                   left:(double)left
                 bottom:(double)bottom
                  right:(double)right
                   zoom:(int)zoom
                matcher:(OAResultMatcher<OAPOI *> *)matcher
             completion:(void (^)(NSArray<OAPOI *> *))completion
{
    if (!_filter || zoom < kPoiMapLayerStartZoom)
    {
        _results = @[];
        _displayedResults = @[];
        _hasExtendedCache = NO;
        if (completion)
            completion(_displayedResults);
        return;
    }

    if ([self extendedCacheContainsTop:top left:left bottom:bottom right:right zoom:zoom])
    {
        if (completion)
            completion(_displayedResults ?: @[]);
        return;
    }

    const double latPad = (top - bottom) * 0.5;
    const double lonPad = (right - left) * 0.5;
    const double extTop = MIN(90.0, top + latPad);
    const double extBottom = MAX(-90.0, bottom - latPad);
    const double extLeft = MAX(-180.0, left - lonPad);
    const double extRight = MIN(180.0, right + lonPad);

    const uint64_t gen = ++_generation;
    OAPOIUIFilter *filter = _filter;
    void (^completionCopy)(NSArray<OAPOI *> *) = [completion copy];

    dispatch_async(_queryQueue, ^{
        OAResultMatcher<OAPOI *> *cancelMatcher =
            [[OAResultMatcher<OAPOI *> alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {
                if (matcher)
                    return [matcher publish:*object];
                return YES;
            } cancelledFunc:^BOOL{
                if (gen != self->_generation)
                    return YES;
                return matcher && [matcher isCancelled];
            }];

        NSArray<OAPOI *> *amenities = [filter searchAmenities:extTop
                                                         left:extLeft
                                                       bottom:extBottom
                                                        right:extRight
                                                         zoom:zoom
                                                      matcher:cancelMatcher
                                                 filterUnique:NO];

        if (gen != self->_generation)
            return;

        NSArray<OAPOI *> *displayed = [OAPOIMapLayerData collectDisplayedPoints:amenities
                                                                           top:extTop
                                                                          left:extLeft
                                                                        bottom:extBottom
                                                                         right:extRight
                                                                          zoom:zoom];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (gen != self->_generation)
                return;
            self->_results = amenities ?: @[];
            self->_displayedResults = displayed ?: @[];
            self->_extTop = extTop;
            self->_extLeft = extLeft;
            self->_extBottom = extBottom;
            self->_extRight = extRight;
            self->_extZoom = zoom;
            self->_hasExtendedCache = YES;
            if (completionCopy)
                completionCopy(self->_displayedResults);
        });
    });
}

+ (NSArray<OAPOI *> *)collectDisplayedPoints:(NSArray<OAPOI *> *)amenities
                                         top:(double)top
                                        left:(double)left
                                      bottom:(double)bottom
                                       right:(double)right
                                        zoom:(int)zoom
{
    if (amenities.count == 0 || zoom < kPoiMapLayerStartZoom)
        return @[];

    const int minTileX = (int)OsmAnd::Utilities::getTileNumberX((float)zoom, left);
    const int maxTileX = (int)OsmAnd::Utilities::getTileNumberX((float)zoom, right);
    const int minTileY = (int)OsmAnd::Utilities::getTileNumberY((float)zoom, top);
    const int maxTileY = (int)OsmAnd::Utilities::getTileNumberY((float)zoom, bottom);
    const int width = maxTileX - minTileX + 1;
    const int height = maxTileY - minTileY + 1;
    if (width <= 0 || height <= 0)
        return @[];

    std::vector<int> tileCounts((size_t)width * (size_t)height, 0);
    NSMutableArray<OAPOI *> *displayed = [NSMutableArray array];
    NSMutableSet<NSValue *> *added = [NSMutableSet set];

    for (OAPOI *poi in amenities)
    {
        const int tileX = (int)OsmAnd::Utilities::getTileNumberX((float)zoom, poi.longitude);
        const int tileY = (int)OsmAnd::Utilities::getTileNumberY((float)zoom, poi.latitude);
        if (tileX < minTileX || tileX > maxTileX || tileY < minTileY || tileY > maxTileY)
            continue;

        const int index = (tileX - minTileX) + (tileY - minTileY) * width;
        if (tileCounts[(size_t)index] >= kPoiTilePointsLimit)
            continue;

        NSValue *key = [NSValue valueWithPointer:(__bridge const void *)poi];
        if ([added containsObject:key])
            continue;

        tileCounts[(size_t)index]++;
        [added addObject:key];
        [displayed addObject:poi];
    }
    return displayed;
}

@end
