//
//  OAMapSourcePresetValues.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/26/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

@class OAMapSourcePreset;

@interface OAMapSourcePresetValues : NSObject <NSCoding>

- (id)initWithOwner:(OAMapSourcePreset*)owner;

@property OAMapSourcePreset* owner;

- (NSUInteger)count;
- (void)setValue:(NSString *)value forKey:(NSString *)key;
- (NSString*)valueOfKey:(NSString *)key;
- (BOOL)removeValueOfKey:(NSString *)key;

- (void)enumerateValuesUsingBlock:(void (^)(NSString* key, NSString* value, BOOL *stop))block;

@property(readonly) OAObservable* changeObservable;

@end
