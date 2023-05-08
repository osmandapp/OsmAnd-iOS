//
//  OAGPXAppearanceCollection.h
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDatabase.h"

@class OAColorItem;

@interface OAGPXTrackAppearance : NSObject

@property (nonatomic) NSString *key;
@property (nonatomic) NSString *title;

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

+ (OAGPXAppearanceCollection *)sharedInstance;

- (void)generateAvailableColors;
- (void)changeColor:(OAColorItem *)colorItem newColor:(UIColor *)newColor;
- (void)addNewSelectedColor:(UIColor *)newColor;
- (void)duplicateColor:(OAColorItem *)colorItem;
- (void)deleteColor:(OAColorItem *)colorItem;
- (void)selectColor:(OAColorItem *)colorItem toGpxFilePath:(NSString *)gpxFilePath;
- (NSArray<OAColorItem *> *)getAvailableColorsSortingByKey;
- (NSArray<OAColorItem *> *)getAvailableColorsSortingByLastUsed;
- (void)removeGpxFilePath:(NSString *)gpxFilePath;
- (OAColorItem *)getColorForGpxFilePath:(NSString *)gpxFilePath defaultValue:(NSInteger)defaultValue;

- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth;
- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value;

- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals;
- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGpxSplitType)type;

@end
