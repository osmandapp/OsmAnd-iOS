//
//  OAMapSourcePresetsCollection.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/20/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapSourcePreset.h"

@class OAMapSource;

@interface OAMapSourcePresetsCollection : NSObject <NSCoding>

- (id)initWithOwner:(OAMapSource*)owner;
- (void)setOwner:(OAMapSource*)owner;

- (NSUInteger)count;
- (NSUInteger)indexOfPresetWithId:(NSUUID*)presetId;
- (NSUUID*)idOfPresetAtIndex:(NSUInteger)index;
- (OAMapSourcePreset*)presetWithId:(NSUUID*)presetId;
- (OAMapSourcePreset*)presetAtIndex:(NSUInteger)index;
- (NSUUID*)registerAndAddPreset:(OAMapSourcePreset*)preset;
- (BOOL)removePresetWithId:(NSUUID*)mapSourceId;
- (void)removePresetAtIndex:(NSUInteger)index;

@property(readonly) OAObservable* collectionChangeObservable;

@end
