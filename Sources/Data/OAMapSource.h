//
//  OAMapSource.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapSourcePresetsCollection.h"

typedef NS_ENUM(NSInteger, OAMapSourceType)
{
    OAMapSourceTypeOffline,
    OAMapSourceTypeOnline
};

@class OAMapSourcesCollection;

@interface OAMapSource : NSObject <NSCoding>

- (id)initWithLocalizedNameKey:(NSString*)localizedNameKey
                       andType:(OAMapSourceType)type
           andTypedReferenceId:(NSString*)typedReferenceId;

- (void)registerAs:(NSUUID*)uniqueId
                in:(OAMapSourcesCollection*)owner;

@property(readonly) OAObservable* changeObservable;

@property(readonly) NSUUID* uniqueId;

@property(copy) NSString* name;
@property(readonly) OAObservable* nameChangeObservable;

@property(readonly, copy) NSString* localizedNameKey;
@property(readonly) OAMapSourceType type;
@property(readonly, copy) NSString* typedReferenceId;

@property(readonly) OAMapSourcePresetsCollection* presets;
@property(readonly) OAObservable* anyPresetChangeObservable;

@property NSUUID* activePresetId;
@property(readonly) OAObservable* activePresetIdChangeObservable;

@end
