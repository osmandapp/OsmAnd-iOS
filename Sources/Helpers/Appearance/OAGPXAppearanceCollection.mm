//
//  OAGPXAppearanceCollection.m
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXAppearanceCollection.h"
#import "OAMapStyleSettings.h"
#import "OAOsmAndFormatter.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGPXTrackAppearance

@end

@implementation OAGPXTrackWidth

- (instancetype)initWithKey:(NSString *)key value:(NSObject *)value
{
    self = [super init];
    if (self)
    {
        BOOL isCustom = !key || key.length == 0;
        self.key = key;
        self.title = OALocalizedString(!isCustom ? [NSString stringWithFormat:@"rendering_value_%@_name", key] : @"shared_string_custom");
        self.icon = !isCustom ? [NSString stringWithFormat:@"ic_custom_track_line_%@", key] : @"ic_custom_slider";
        self.customValue = !isCustom ? @"-1" : (NSString *) value;
        if ([value isKindOfClass:[NSArray class]])
        {
            NSArray *newValue = (NSArray *) value;
            if (newValue.count > 0 && ![newValue[0] isKindOfClass:[NSArray class]])
                value = @[newValue];
        }
        self.allValues = !isCustom ? (NSArray *) value : [NSArray array];
    }
    return self;
}

+ (instancetype)getDefault
{
    return [[OAGPXTrackWidth alloc] initWithKey:@""
                                          value:[NSString stringWithFormat:@"%li", [self.class getCustomTrackWidthMin]]];
}

- (BOOL)isCustom
{
    return !self.key || self.key.length == 0;
}

+ (NSInteger)getCustomTrackWidthMin
{
    return 1;
}

+ (NSInteger)getCustomTrackWidthMax
{
    return 24;
}

@end

@implementation OAGPXTrackSplitInterval

- (instancetype)initWithType:(EOAGpxSplitType)type
{
    self = [super init];
    if (self)
    {
        NSString *key = [OAGPXDatabase splitTypeNameByValue:type];
        self.key = key;
        self.title = OALocalizedString([NSString stringWithFormat:@"shared_string_%@", type == EOAGpxSplitTypeNone ? @"none" : key]);
        self.type = type;

        switch (type)
        {
            case EOAGpxSplitTypeTime:
            {
                [self generateTimeOptionSplit];
                break;
            }
            case EOAGpxSplitTypeDistance:
            {
                [self generateDistanceOptionSplit];
                break;
            }
            default:
            {
                self.titles = [NSArray array];
                self.values = [NSArray array];
                break;
            }
        }

        self.customValue = type != EOAGpxSplitTypeNone ? _titles.firstObject : @"0";
    }
    return self;
}

+ (instancetype)getDefault
{
    return [[OAGPXTrackSplitInterval alloc] initWithType:EOAGpxSplitTypeNone];
}

- (BOOL)isCustom
{
    return self.type != EOAGpxSplitTypeNone;
}

- (void)generateDistanceOptionSplit
{
    NSArray<NSNumber *> *customValues = @[
        @30, // 50 feet, 20 yards, 20 m
        @60, // 100 feet, 50 yards, 50 m
        @150, // 200 feet, 100 yards, 100 m
        @300, // 500 feet, 200 yards, 200 m
        @600, // 1000 feet, 500 yards, 500 m
        @1500, // 2000 feet, 1000 yards, 1 km
        @3000, // 1 mi, 2 km
        @6000, // 2 mi, 5 km
        @15000 // 5 mi, 10 k
    ];

    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];

    for (NSNumber *customValue in customValues)
    {
        [titles addObject:[OAOsmAndFormatter getFormattedDistanceInterval:customValue.intValue withParams:[OsmAndFormatterParams noTrailingZeros]]];
        [values addObject:@([OAOsmAndFormatter calculateRoundedDist:customValue.intValue])];
    }
    self.titles = titles;
    self.values = values;
}

- (void)generateTimeOptionSplit
{
    NSArray<NSNumber *> *customValues = @[
        @15,
        @30,
        @60,
        @120,
        @150,
        @300,
        @600,
        @900,
        @1800
    ];

    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];

    for (NSNumber *customValue in customValues)
    {
        [titles addObject:[OAOsmAndFormatter getFormattedTimeInterval:customValue.intValue]];
        [values addObject:customValue];
    }
    self.titles = titles;
    self.values = values;
}

@end

@implementation OAGPXAppearanceCollection
{
    NSDictionary<NSString *, NSArray<NSNumber *> *> *_defaultWidthValues;
    NSArray<OAGPXTrackWidth *> *_availableWidth;
    NSArray<OAGPXTrackSplitInterval *> *_availableSplitInterval;
}

+ (OAGPXAppearanceCollection *)sharedInstance
{
    static OAGPXAppearanceCollection *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAGPXAppearanceCollection alloc] init];
    });
    return _sharedInstance;
}

- (void)onUpdateMapSource:(OAMapViewController *)mapViewController
{
    _defaultWidthValues = [mapViewController getGpxWidth];
    _availableWidth = nil;
}

- (OASPaletteSolidCollection *)getSolidPalette
{
    return (OASPaletteSolidCollection *)[[OsmAndApp instance].paletteRepository getPaletteId:[OASPaletteConstants shared].DEFAULT_SOLID_PALETTE_ID];
}

- (NSArray<OASPaletteItemSolid *> *)solidItemsWithSortMode:(OASPaletteSortMode *)sortMode
{
    NSMutableArray<OASPaletteItemSolid *> *result = [NSMutableArray array];
    NSArray<id<OASPaletteItem>> *items = [[OsmAndApp instance].paletteRepository getPaletteItemsPaletteId:[OASPaletteConstants shared].DEFAULT_SOLID_PALETTE_ID sortMode:sortMode];
    for (id item in items)
    {
        if ([item isKindOfClass:OASPaletteItemSolid.class])
            [result addObject:(OASPaletteItemSolid *)item];
    }

    return result;
}

- (OASPaletteItemSolid *)findColorItemWithValue:(int)value
{
    for (OASPaletteItemSolid *colorItem in [self solidItemsWithSortMode:OASPaletteSortMode.originalOrder])
    {
        if (colorItem.colorInt == value)
            return colorItem;
    }

    return nil;
}

- (BOOL)saveFavoriteColorsIfNeeded:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    BOOL isRegenerated = NO;
    for (OAFavoriteGroup *favoriteGroup in favoriteGroups)
    {
        if ([self saveValueIfNeeded:favoriteGroup.color])
            isRegenerated = YES;

        for (OAFavoriteItem *favoriteItem in favoriteGroup.points)
        {
            if ([self saveValueIfNeeded:[favoriteItem getColor]])
                isRegenerated = YES;
        }
    }

    return isRegenerated;
}

- (BOOL)saveValueIfNeeded:(UIColor *)color
{
    if (!color || [self findColorItemWithValue:[color toARGBNumber]])
        return NO;

    return [self addNewSelectedColor:color] != nil;
}

- (OASPaletteItemSolid *)defaultLineColorItem
{
    return [self findColorItemWithValue:(int)kDefaultTrackColor] ?: [self addNewSelectedColor:UIColorFromARGB((int)kDefaultTrackColor)];
}

- (OASPaletteItemSolid *)defaultPointColorItem
{
    int colorValue = [[OADefaultFavorite getDefaultColor] toARGBNumber];
    return [self findColorItemWithValue:colorValue] ?: [self addNewSelectedColor:UIColorFromARGB(colorValue)];
}

- (OASPaletteItemSolid *)changeColor:(OASPaletteItemSolid *)colorItem newColor:(UIColor *)newColor
{
    if (!colorItem || !newColor)
        return nil;

    OASPaletteItemSolid *newItem = [[OASPaletteUtils shared] updateSolidColorOriginalItem:colorItem newColorInt:(int32_t)[newColor toARGBNumber]];
    [[OsmAndApp instance].paletteRepository updatePaletteItemItem:newItem];
    return newItem;
}

- (OASPaletteItemSolid *)addNewSelectedColor:(UIColor *)newColor
{
    OASPaletteSolidCollection *palette = [self getSolidPalette];
    if (!palette || !newColor)
        return nil;

    OASPaletteItemSolid *colorItem = [[OASPaletteUtils shared] createSolidColorPalette:palette colorInt:(int32_t)[newColor toARGBNumber] markAsUsed:NO];
    [[OsmAndApp instance].paletteRepository addPaletteItemPaletteId:palette.id newItem:colorItem];
    return colorItem;
}

- (OASPaletteItemSolid *)duplicateColor:(OASPaletteItemSolid *)colorItem
{
    if (!colorItem)
        return nil;

    OASPaletteRepository *repository = [OsmAndApp instance].paletteRepository;
    OASPaletteSolidCollection *palette = (OASPaletteSolidCollection *)[repository getPaletteId:colorItem.source.paletteId];
    if (!palette)
        return nil;

    OASPaletteItemSolid *duplicatedColorItem = [[OASPaletteUtils shared] createSolidDuplicatePalette:palette originalItemId:colorItem.id markAsUsed:NO];
    if (duplicatedColorItem)
        [repository insertPaletteItemAfterPaletteId:palette.id anchorId:colorItem.id newItem:duplicatedColorItem];

    return duplicatedColorItem;
}

- (void)deleteColor:(OASPaletteItemSolid *)colorItem
{
    if (colorItem)
        [[OsmAndApp instance].paletteRepository removePaletteItemPaletteId:colorItem.source.paletteId itemId:colorItem.id];
}

- (void)selectColor:(OASPaletteItemSolid *)colorItem
{
    if (colorItem)
        [[OsmAndApp instance].paletteRepository markPaletteItemAsUsedPaletteId:colorItem.source.paletteId itemId:colorItem.id];
}

- (NSArray<OASPaletteItemSolid *> *)getAvailableColorsSortingByLastUsed
{
    return [self solidItemsWithSortMode:OASPaletteSortMode.lastUsedTime];
}

- (OASPaletteItemSolid *)getColorItemWithValue:(int)value
{
    OASPaletteItemSolid *colorItem = [self findColorItemWithValue:value];
    if (colorItem)
        return colorItem;

    return value == 0 ? [self defaultLineColorItem] : [self addNewSelectedColor:UIColorFromARGB(value)];
}

- (NSInteger)indexOfColorItem:(OASPaletteItemSolid *)colorItem items:(NSArray<OASPaletteItemSolid *> *)items
{
    if (!colorItem)
        return NSNotFound;

    for (NSInteger i = 0; i < items.count; i++)
    {
        if ([self isSameColorItem:items[i] secondItem:colorItem])
            return i;
    }

    return NSNotFound;
}

- (BOOL)isSameColorItem:(OASPaletteItemSolid *)firstItem secondItem:(OASPaletteItemSolid *)secondItem
{
    return firstItem == secondItem || (firstItem && secondItem && [firstItem.id isEqualToString:secondItem.id]);
}

- (BOOL)isSameColorValue:(OASPaletteItemSolid *)firstItem secondItem:(OASPaletteItemSolid *)secondItem
{
    return firstItem == secondItem || (firstItem && secondItem && firstItem.colorInt == secondItem.colorInt);
}

- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth
{
    if (_availableWidth && [_availableWidth count] > 0)
        return _availableWidth;

    NSMutableArray<NSString *> *possibleTrackWidthKeys = [NSMutableArray new];
    OAMapStyleParameter *currentTrackWidth = [[OAMapStyleSettings sharedInstance] getParameter:CURRENT_TRACK_WIDTH_ATTR];
    if (currentTrackWidth && _defaultWidthValues)
    {
        NSArray<OAMapStyleParameterValue *> *currentTrackWidthParameters = currentTrackWidth.possibleValuesUnsorted;
        [currentTrackWidthParameters enumerateObjectsUsingBlock:^(OAMapStyleParameterValue *parameter, NSUInteger ids, BOOL *stop) {
            if (ids != 0)
                [possibleTrackWidthKeys addObject:parameter.name];
        }];

        NSMutableArray<OAGPXTrackWidth *> *result = [NSMutableArray new];
        [_defaultWidthValues enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSArray<NSNumber *> *_Nonnull obj, BOOL *_Nonnull stop) {
            NSString *originalKey = [key substringToIndex:[key indexOf:@"_"]];
            if ([possibleTrackWidthKeys containsObject:originalKey]) {
                OAGPXTrackWidth *existWidth = _availableWidth ? [self getWidthForValue:originalKey] : nil;
                if (existWidth) {
                    NSMutableArray *existValues = [existWidth.allValues mutableCopy];
                    [existValues addObject:obj];
                    existWidth.allValues = existValues;
                } else {
                    [result addObject:[[OAGPXTrackWidth alloc] initWithKey:originalKey value:obj]];
                    _availableWidth = result;
                }
            }
        }];

        [result addObject:[OAGPXTrackWidth getDefault]];

        _availableWidth = [result sortedArrayUsingComparator:^NSComparisonResult(OAGPXTrackWidth *obj1, OAGPXTrackWidth *obj2) {
            return [@([possibleTrackWidthKeys indexOfObject:obj1.key]) compare:@([possibleTrackWidthKeys indexOfObject:obj2.key])];
        }];
    }
    else
    {
        _availableWidth = [NSArray array];
    }

    return _availableWidth;
}

- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value
{
    if (!_availableWidth || [_availableWidth count] == 0)
        [self getAvailableWidth];

    for (OAGPXTrackWidth *width in _availableWidth)
    {
        if (value.intValue > 0 && [width isCustom])
        {
            width.customValue = value;
            return width;
        }
        else if ([width.key isEqualToString:value])
        {
            return width;
        }
    }

    return nil;
}

- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals
{
    if (_availableSplitInterval && [_availableSplitInterval count] > 0)
        return _availableSplitInterval;

    _availableSplitInterval = @[
        [OAGPXTrackSplitInterval getDefault],
        [[OAGPXTrackSplitInterval alloc] initWithType:EOAGpxSplitTypeTime],
        [[OAGPXTrackSplitInterval alloc] initWithType:EOAGpxSplitTypeDistance]
    ];

    return _availableSplitInterval;
}

- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGpxSplitType)type
{
    if (!_availableSplitInterval || [_availableSplitInterval count] == 0)
        [self getAvailableSplitIntervals];

    for (OAGPXTrackSplitInterval *splitInterval in _availableSplitInterval)
    {
        if (splitInterval.type == type)
            return splitInterval;
    }

    return [OAGPXTrackSplitInterval getDefault];
}

@end
