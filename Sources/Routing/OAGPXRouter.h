//
//  OAGPXRouter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObservable.h"
#import "OAMapStyleSettings.h"

@class OAGPXRouteDocument;
@class OAGPX;

@interface OAGPXRouter : NSObject

@property (nonatomic, readonly) OAGPX *gpx;
@property (nonatomic, readonly) OAGPXRouteDocument *routeDoc;

@property (readonly) OAObservable* locationUpdatedObservable;
@property (readonly) OAObservable* routeDefinedObservable;
@property (readonly) OAObservable* routeCanceledObservable;
@property (readonly) OAObservable* routeChangedObservable;

+ (OAGPXRouter *)sharedInstance;

- (void)setRouteWithGpx:(OAGPX *)gpx;
- (void)cancelRoute;
- (void)saveRoute;
- (void)saveRouteIfModified;

- (NSTimeInterval)getRouteDuration;
- (NSTimeInterval)getRouteDuration:(OAMapVariantType)mapVariantType;

- (void)updateDistanceAndDirection:(BOOL)forceUpdate;
- (void)refreshDestinations;

@end
