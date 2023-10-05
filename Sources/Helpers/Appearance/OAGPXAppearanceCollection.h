//
//  OAGPXAppearanceCollection.h
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDatabase.h"

@class OAColorItem, OAFavoriteGroup;

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
- (BOOL)saveFavoriteColorsIfNeeded:(NSArray<OAFavoriteGroup *> *)favoriteGroups;
- (OAColorItem *)getDefaultLineColorItem;
- (OAColorItem *)getDefaultPointColorItem;

- (void)changeColor:(OAColorItem *)colorItem newColor:(UIColor *)newColor;
- (OAColorItem *)addNewSelectedColor:(UIColor *)newColor;
- (void)duplicateColor:(OAColorItem *)colorItem;
- (void)deleteColor:(OAColorItem *)colorItem;
- (void)selectColor:(OAColorItem *)colorItem;
- (NSArray<OAColorItem *> *)getAvailableColorsSortingByKey;
- (NSArray<OAColorItem *> *)getAvailableColorsSortingByLastUsed;
- (OAColorItem *)getColorItemWithValue:(int)defaultValue;

- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth;
- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value;

- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals;
- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGpxSplitType)type;

@end
