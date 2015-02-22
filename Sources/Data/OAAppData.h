//
//  OAAppData.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapViewState.h"
#import "OAMapSource.h"
#import "OAMapLayersConfiguration.h"

@interface OAAppData : NSObject <NSCoding>

@property OAMapSource* lastMapSource;
@property(readonly) OAObservable* lastMapSourceChangeObservable;
- (OAMapSource*)lastMapSourceByResourceId:(NSString*)resourceId;

@property(readonly) OAMapViewState* mapLastViewedState;

@property(readonly) OAMapLayersConfiguration* mapLayersConfiguration;

+ (OAAppData*)defaults;

@end
