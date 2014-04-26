//
//  OAAppData.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapCrossSessionState.h"
#import "OAMapSource.h"

@interface OAAppData : NSObject <NSCoding>

@property OAMapSource* lastMapSource;
@property(readonly) OAObservable* lastMapSourceChangeObservable;

- (OAMapSource*)lastMapSourceByResourceName:(NSString*)resourceName;

@property(readonly) OAMapCrossSessionState* mapLastViewedState;

+ (OAAppData*)defaults;

@end
