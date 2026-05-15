//
//  OAGPXAppearanceCollection.h
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDatabase.h"
#import "OsmAndSharedWrapper.h"

@class OAFavoriteGroup, OAMapViewController;

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

- (void)onUpdateMapSource:(OAMapViewController *)mapViewController;
- (BOOL)saveFavoriteColorsIfNeeded:(NSArray<OAFavoriteGroup *> *)favoriteGroups;
- (OASPaletteItemSolid *)getDefaultLineColorItem;
- (OASPaletteItemSolid *)getDefaultPointColorItem;

- (OASPaletteItemSolid *)changeColor:(OASPaletteItemSolid *)colorItem newColor:(UIColor *)newColor;
- (OASPaletteItemSolid *)addNewSelectedColor:(UIColor *)newColor;
- (OASPaletteItemSolid *)duplicateColor:(OASPaletteItemSolid *)colorItem;
- (void)deleteColor:(OASPaletteItemSolid *)colorItem;
- (void)selectColor:(OASPaletteItemSolid *)colorItem;
- (NSArray<OASPaletteItemSolid *> *)getAvailableColorsSortingByLastUsed;
- (OASPaletteItemSolid *)getColorItemWithValue:(int)defaultValue;
- (NSInteger)indexOfColorItem:(OASPaletteItemSolid *)colorItem items:(NSArray<OASPaletteItemSolid *> *)items;
- (BOOL)isSameColorItem:(OASPaletteItemSolid *)firstItem secondItem:(OASPaletteItemSolid *)secondItem;
- (BOOL)isSameColorValue:(OASPaletteItemSolid *)firstItem secondItem:(OASPaletteItemSolid *)secondItem;

- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth;
- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value;

- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals;
- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGpxSplitType)type;

@end
