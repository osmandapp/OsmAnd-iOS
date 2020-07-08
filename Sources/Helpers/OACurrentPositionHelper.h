//
//  OACurrentPositionHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <binaryRead.h>

@class OAMapRendererView;
@class OAApplicationMode;

@interface OARoadResultMatcher : NSObject

typedef BOOL(^OARoadResultMatcherPublish)(const std::shared_ptr<RouteDataObject> road);
@property (nonatomic) OARoadResultMatcherPublish publishFunction;

typedef BOOL(^OARoadResultMatcherIsCancelled)();
@property (nonatomic) OARoadResultMatcherIsCancelled cancelledFunction;

/**
 * @param name
 * @return true if result should be added to final list
 */
- (BOOL) publish:(const std::shared_ptr<RouteDataObject>)object;

/**
 * @returns true to stop processing
 */
- (BOOL) isCancelled;

- (instancetype)initWithPublishFunc:(OARoadResultMatcherPublish)pFunction cancelledFunc:(OARoadResultMatcherIsCancelled)cFunction;

@end

@interface OACurrentPositionHelper : NSObject

+ (OACurrentPositionHelper *)instance;

+ (double) getOrthogonalDistance:(std::shared_ptr<RouteDataObject>) r loc:(CLLocation *)loc;
- (std::shared_ptr<RouteDataObject>) getLastKnownRouteSegment:(CLLocation *)loc;
- (void) getRouteSegment:(CLLocation *)loc appMode:(OAApplicationMode *)appMode matcher:(OARoadResultMatcher *)matcher;

@end
