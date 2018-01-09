//
//  OACurrentPositionHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Data/Road.h>

@class OAMapRendererView;

@interface OARoadResultMatcher : NSObject

typedef BOOL(^OARoadResultMatcherPublish)(const std::shared_ptr<const OsmAnd::Road> road);
@property (nonatomic) OARoadResultMatcherPublish publishFunction;

typedef BOOL(^OARoadResultMatcherIsCancelled)();
@property (nonatomic) OARoadResultMatcherIsCancelled cancelledFunction;

/**
 * @param name
 * @return true if result should be added to final list
 */
- (BOOL) publish:(const std::shared_ptr<const OsmAnd::Road>&)object;

/**
 * @returns true to stop processing
 */
- (BOOL) isCancelled;

- (instancetype)initWithPublishFunc:(OARoadResultMatcherPublish)pFunction cancelledFunc:(OARoadResultMatcherIsCancelled)cFunction;

@end

@interface OACurrentPositionHelper : NSObject

+ (OACurrentPositionHelper *)instance;

+ (double) getOrthogonalDistance:(std::shared_ptr<const OsmAnd::Road>) r loc:(CLLocation *)loc;
- (std::shared_ptr<const OsmAnd::Road>) getLastKnownRouteSegment:(CLLocation *)loc;
- (void) getRouteSegment:(CLLocation *)loc matcher:(OARoadResultMatcher *)matcher;

- (void) clearCacheNotInTiles:(OAMapRendererView *)mapRendererView;

@end
