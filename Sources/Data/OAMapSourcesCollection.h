//
//  OAMapSourcesCollection.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapSource.h"

@class OAAppData;

@interface OAMapSourcesCollection : NSObject <NSCoding>

- (id)initWithOwner:(OAAppData*)owner;
@property OAAppData* owner;

- (NSUInteger)count;
- (NSUInteger)indexOfMapSourceWithId:(NSUUID*)mapSourceId;
- (NSUUID*)idOfMapSourceAtIndex:(NSUInteger)index;
- (OAMapSource*)mapSourceWithId:(NSUUID*)mapSourceId;
- (OAMapSource*)mapSourceAtIndex:(NSUInteger)index;
- (NSUUID*)registerAndAddMapSource:(OAMapSource*)mapSource;
- (BOOL)removeMapSourceWithId:(NSUUID*)mapSourceId;
- (void)removeMapSourceAtIndex:(NSUInteger)index;

- (void)enumerateMapSourcesUsingBlock:(void (^)(OAMapSource* mapSource, BOOL *stop))block;

@property(readonly) OAObservable* collectionChangeObservable;

@end
