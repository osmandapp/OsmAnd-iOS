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

@implementation OAPOIMapLayerData
{
    OAPOIUIFilter *_filter;
    NSArray<OAPOI *> *_results;
    NSArray<OAPOI *> *_displayedResults;
    uint64_t _generation;
}

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _filter = filter;
        _generation = 0;
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
        if (completion)
            completion(_displayedResults);
        return;
    }

    const uint64_t gen = ++_generation;
    OAPOIUIFilter *filter = _filter;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray<OAPOI *> *amenities = [filter searchAmenities:top
                                                         left:left
                                                       bottom:bottom
                                                        right:right
                                                         zoom:zoom
                                                      matcher:matcher
                                                 filterUnique:NO];

        NSArray<OAPOI *> *displayed = [OAPOIMapLayerData collectDisplayedPoints:amenities
                                                                           top:top
                                                                          left:left
                                                                        bottom:bottom
                                                                         right:right
                                                                          zoom:zoom];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (gen != self->_generation)
                return;
            self->_results = amenities ?: @[];
            self->_displayedResults = displayed ?: @[];
            if (completion)
                completion(self->_displayedResults);
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
