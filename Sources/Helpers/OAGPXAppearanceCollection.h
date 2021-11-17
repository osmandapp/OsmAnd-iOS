//
//  OAGPXAppearanceCollection.h
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDatabase.h"

@interface OAGPXTrackAppearance : NSObject

@property (nonatomic) NSString *key;
@property (nonatomic) NSString *title;

@end

@interface OAGPXTrackColor : OAGPXTrackAppearance

@property (nonatomic) UIColor *color;
@property (nonatomic) NSInteger colorValue;

- (instancetype)initWithKey:(NSString *)key value:(NSInteger)value;

@end

@interface OAGPXTrackWidth : OAGPXTrackAppearance

@property (nonatomic) NSString *icon;
@property (nonatomic) NSArray<NSArray<NSNumber *> *> *allValues;
@property (nonatomic) NSString *customValue;

- (instancetype)initWithKey:(NSString *)key value:(NSObject *)value;
+ (instancetype)getDefault;

- (BOOL)isCustom;

+ (NSInteger)getCustomTrackWidthMin;
+ (NSInteger)getCustomTrackWidthMax;

@end

@interface OAGPXTrackSplitInterval : OAGPXTrackAppearance

@property (nonatomic) EOAGpxSplitType type;
@property (nonatomic) NSArray<NSString *> *titles;
@property (nonatomic) NSArray<NSNumber *> *values;
@property (nonatomic) NSString *customValue;

- (instancetype)initWithType:(EOAGpxSplitType)type;
+ (instancetype)getDefault;

- (BOOL)isCustom;

@end

@interface OAGPXAppearanceCollection : NSObject

- (NSArray<OAGPXTrackColor *> *)getAvailableColors;
- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth;
- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals;

- (OAGPXTrackColor *)getColorForValue:(NSInteger)value;
- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value;
- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGpxSplitType)type;

@end
