//
//  OAAppData.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapSourcesCollection.h"
#import "OAMapCrossSessionState.h"

@interface OAAppData : NSObject <NSCoding>

@property NSUUID* activeMapSourceId;
@property(readonly) OAObservable* activeMapSourceIdChangeObservable;

@property(readonly) OAMapSourcesCollection* mapSources;

@property(readonly) OAMapCrossSessionState* mapLastViewedState;

@end
