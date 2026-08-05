//
//  OAPOIMapLayerData.h
//  OsmAnd
//
//  Created by Vitaliy Sova on 05.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAResultMatcher.h"

@class OAPOI;
@class OAPOIUIFilter;

NS_ASSUME_NONNULL_BEGIN

static const int kPoiMapLayerStartZoom = 5;
static const int kPoiTilePointsLimit = 25;
static const int kPoiMapLayerZoomThreshold = 0;

@interface OAPOIMapLayerData : NSObject

@property (nonatomic, readonly) OAPOIUIFilter *filter;
@property (nonatomic, readonly, nullable) NSArray<OAPOI *> *results;
@property (nonatomic, readonly, nullable) NSArray<OAPOI *> *displayedResults;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFilter:(OAPOIUIFilter *)filter NS_DESIGNATED_INITIALIZER;

- (void)clear;

- (BOOL)coversTop:(double)top
             left:(double)left
           bottom:(double)bottom
            right:(double)right
             zoom:(int)zoom;

- (void)queryNewDataTop:(double)top
                   left:(double)left
                 bottom:(double)bottom
                  right:(double)right
                   zoom:(int)zoom
                matcher:(OAResultMatcher<OAPOI *> * _Nullable)matcher
             completion:(void (^)(NSArray<OAPOI *> *displayedResults))completion;

+ (NSArray<OAPOI *> *)collectDisplayedPoints:(NSArray<OAPOI *> *)amenities
                                         top:(double)top
                                        left:(double)left
                                      bottom:(double)bottom
                                       right:(double)right
                                        zoom:(int)zoom;

@end

NS_ASSUME_NONNULL_END
