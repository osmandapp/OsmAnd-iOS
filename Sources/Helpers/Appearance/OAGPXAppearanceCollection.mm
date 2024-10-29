//
//  OAGPXAppearanceCollection.m
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXAppearanceCollection.h"
#import "OARootViewController.h"
#import "OAEditPointViewController.h"
#import "OAMapStyleSettings.h"
#import "OAOsmAndFormatter.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define kDefaulRedColorName @"red"
#define kDefaulRedColorValue 0xFFFF0000
#define kDefaulFavoriteColorName @"default_favorite"

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
    OAAppSettings *_settings;

    NSMutableArray<OAColorItem *> *_availableColors;
    NSMutableDictionary<NSString *, NSNumber *> *_defaultColorValues;
    NSDictionary<NSString *, NSArray<NSNumber *> *> *_defaultWidthValues;
    OAColorItem *_defaultPointColorItem;
    OAColorItem *_defaultLineColorItem;

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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)onUpdateMapSource:(OAMapViewController *)mapViewController
{
    _defaultColorValues = [NSMutableDictionary dictionaryWithDictionary:[mapViewController getGpxColors]];
    _defaultWidthValues = [mapViewController getGpxWidth];
    _availableWidth = nil;
}

- (void)generateAvailableColors
{
    _availableColors = [NSMutableArray array];
    if (!_defaultColorValues)
        return;

    _defaultLineColorItem = nil;
    NSMutableArray<NSString *> *possibleTrackColorKeys = [NSMutableArray array];
    OAMapStyleParameter *currentTrackColor = [[OAMapStyleSettings sharedInstance] getParameter:CURRENT_TRACK_COLOR_ATTR];
    if (currentTrackColor)
    {
        NSArray<OAMapStyleParameterValue *> *currentTrackColorParameters = currentTrackColor.possibleValuesUnsorted;
        [currentTrackColorParameters enumerateObjectsUsingBlock:^(OAMapStyleParameterValue *parameter, NSUInteger ids, BOOL *stop) {
            if (ids != 0)
                [possibleTrackColorKeys addObject:parameter.name];
        }];
        NSMutableDictionary<NSString *, NSNumber *> *defaultColorValues = [NSMutableDictionary dictionaryWithDictionary:_defaultColorValues];
        [defaultColorValues enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber *_Nonnull obj, BOOL *_Nonnull stop) {
            if (![possibleTrackColorKeys containsObject:key])
            {
                [defaultColorValues removeObjectForKey:key];
            }
            else
            {
                OAColorItem *colorItem = [[OAColorItem alloc] initWithKey:key value:obj.intValue isDefault:YES];
                [_availableColors addObject:colorItem];
                colorItem.sortedPosition = [_availableColors indexOfObject:colorItem];
                [colorItem generateId];
                if ([colorItem.key isEqualToString:kDefaulRedColorName])
                    _defaultLineColorItem = colorItem;
            }
        }];
        _defaultColorValues = defaultColorValues;
        [_availableColors sortUsingComparator:^NSComparisonResult(OAColorItem *obj1, OAColorItem *obj2) {
            return [@([possibleTrackColorKeys indexOfObject:obj1.key]) compare:@([possibleTrackColorKeys indexOfObject:obj2.key])];
        }];
    }

    if (!_defaultLineColorItem)
        [self getDefaultLineColorItem];
    [self getDefaultPointColorItem];
    NSMutableArray<NSString *> *defaultHexColors = [NSMutableArray array];
    for (OAColorItem *defaultColorItem in _availableColors)
    {
        [defaultHexColors addObject:[defaultColorItem getHexColor]];
    }
    [self saveColorsToEndOfLastUsedIfNeeded:defaultHexColors];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    [customTrackColors.copy enumerateObjectsUsingBlock:^(NSString *hexColor, NSUInteger ids, BOOL *stop) {
        if (hexColor.length == 0)
            [customTrackColors removeObject:hexColor];
    }];
    [_settings.customTrackColors set:customTrackColors];

    [self saveColorsToEndOfLastUsedIfNeeded:customTrackColors];
    for (NSString *hexColor in customTrackColors)
    {
        [_availableColors addObject:[[OAColorItem alloc] initWithHexColor:hexColor]];
    }
    [self initSortedPosition];
}

- (void)initSortedPosition
{
    NSArray<NSString *> *customTrackColorsLastUsed = [_settings.customTrackColorsLastUsed get];
    NSMutableDictionary<NSNumber *, NSString *> *sortedPositionWithHexColors = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < customTrackColorsLastUsed.count; i++)
    {
        sortedPositionWithHexColors[@(i)] = customTrackColorsLastUsed[i];
    }

    [_availableColors.copy enumerateObjectsUsingBlock:^(OAColorItem * _Nonnull colorItem, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *hexColor = [colorItem getHexColor];
        NSInteger sortedHexColorIndex = [sortedPositionWithHexColors.allValues indexOfObject:hexColor];
        if (sortedHexColorIndex != NSNotFound)
        {
            NSInteger sortedPosition = sortedPositionWithHexColors.allKeys[sortedHexColorIndex].intValue;
            colorItem.sortedPosition = sortedPosition;
            [colorItem generateId];
            [sortedPositionWithHexColors removeObjectForKey:@(sortedPosition)];
        }
        else
        {
            [_availableColors removeObject:colorItem];
        }
    }];
}

- (void)regenerateSortedPositionAfter:(NSInteger)position increment:(BOOL)increment
{
    for (OAColorItem *item in _availableColors)
    {
        if (item.sortedPosition > position)
        {
            if (increment)
                item.sortedPosition += 1;
            else
                item.sortedPosition -= 1;
            [item generateId];
        }
    }
}

- (void)saveColorsToEndOfLastUsedIfNeeded:(NSArray<NSString *> *)customColors
{
    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    for (NSString *hexColor in customColors)
    {
        NSInteger availableCount = [self getMaxCountOfDuplicates:hexColor];
        NSInteger lastUsedCount = [self getMaxCountOfDuplicatesInLastUsed:hexColor];
        if (lastUsedCount < availableCount
            || (lastUsedCount == 0 && availableCount == 0 && ([hexColor isEqualToString:[[self getDefaultLineColorItem] getHexColor]]
                                                              || [hexColor isEqualToString:[[self getDefaultPointColorItem] getHexColor]])))
            [customTrackColorsLastUsed addObject:hexColor];
    }
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
}

- (BOOL)saveFavoriteColorsIfNeeded:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    BOOL isRegenerated = NO;
    if (favoriteGroups && favoriteGroups.count > 0)
    {
        NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
        NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
        for (OAFavoriteGroup *favoriteGroup in favoriteGroups)
        {
            NSString *groupName = favoriteGroup.name;
            if (!groupName || groupName.length == 0)
                groupName = @"default";
            if ([self saveValueIfNeeded:customTrackColorsLastUsed
                      customTrackColors:customTrackColors
                                  color:favoriteGroup.color])
                isRegenerated = YES;

            for (OAFavoriteItem *favoriteItem in favoriteGroup.points)
            {
                if ([self saveValueIfNeeded:customTrackColorsLastUsed
                          customTrackColors:customTrackColors
                                      color:[favoriteItem getColor]])
                    isRegenerated = YES;
            }
        }
        if (isRegenerated)
        {
            [_settings.customTrackColors set:customTrackColors];
            [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
        }
    }
    return isRegenerated;
}

- (BOOL)saveValueIfNeeded:(NSMutableArray<NSString *> *)customTrackColorsLastUsed
        customTrackColors:(NSMutableArray<NSString *> *)customTrackColors
                    color:(UIColor *)color
{
    OAColorItem *colorItem;
    int colorValue = [color toARGBNumber];
    NSString *hexColor = [color toHexARGBString];
    for (OAColorItem *ci in _availableColors)
    {
        if (ci.value == colorValue)
        {
            colorItem = ci;
            break;
        }
    }

    if (!colorItem)
    {
        colorItem = [[OAColorItem alloc] initWithHexColor:hexColor];
        [_availableColors addObject:colorItem];
        colorItem.sortedPosition = _availableColors.count - 1;
        [colorItem generateId];
    }

    BOOL result = NO;
    if (![customTrackColors containsObject:hexColor])
    {
        [customTrackColors addObject:hexColor];
        result = YES;
    }
    if (![customTrackColorsLastUsed containsObject:hexColor])
    {
        [customTrackColorsLastUsed addObject:hexColor];
        result = YES;
    }

    return result;
}

- (OAColorItem *)getDefaultLineColorItem
{
    if (!_defaultLineColorItem || ![_availableColors containsObject:_defaultLineColorItem])
    {
        _defaultLineColorItem = [[OAColorItem alloc] initWithKey:kDefaulRedColorName value:kDefaulRedColorValue isDefault:YES];
        _defaultLineColorItem.sortedPosition = _availableColors.count;
        [_defaultLineColorItem generateId];
        [_availableColors addObject:_defaultLineColorItem];
        _defaultColorValues[_defaultLineColorItem.key] = @(_defaultLineColorItem.value);
    }
    return _defaultLineColorItem;
}

- (OAColorItem *)getDefaultPointColorItem
{
    if (!_defaultPointColorItem || ![_availableColors containsObject:_defaultPointColorItem])
    {
        _defaultPointColorItem = [[OAColorItem alloc] initWithKey:kDefaulFavoriteColorName value:[[OADefaultFavorite getDefaultColor] toARGBNumber] isDefault:YES];
        _defaultPointColorItem.sortedPosition = _availableColors.count;
        [_defaultPointColorItem generateId];
        [_availableColors addObject:_defaultPointColorItem];
        _defaultColorValues[_defaultPointColorItem.key] = @(_defaultPointColorItem.value);
    }
    return _defaultPointColorItem;
}

- (NSInteger)getMaxCountOfDuplicates:(NSString *)hexColor
{
    NSInteger count = 0;
    for (NSString *hx in [_settings.customTrackColors get])
    {
        if ([hexColor isEqualToString:hx])
            count++;
    }
    for (NSNumber *colorValue in _defaultColorValues.allValues)
    {
        if ([hexColor isEqualToString:[UIColorFromARGB(colorValue.intValue) toHexARGBString]])
            count++;
    }
    return count;
}

- (NSInteger)getMaxCountOfDuplicatesInLastUsed:(NSString *)hexColor
{
    NSInteger count = 0;
    for (NSString *hx in [_settings.customTrackColorsLastUsed get])
    {
        if ([hexColor isEqualToString:hx])
            count++;
    }
    return count;
}

- (void)changeColor:(OAColorItem *)colorItem newColor:(UIColor *)newColor
{
    NSString *newHexColor = [newColor toHexARGBString];
    [colorItem setValueWithNewValue:[newColor toARGBNumber]];
    [colorItem generateId];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    customTrackColors[[_availableColors indexOfObject:colorItem] - _defaultColorValues.count] = newHexColor;
    [_settings.customTrackColors set:customTrackColors];

    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    customTrackColorsLastUsed[colorItem.sortedPosition] = newHexColor;
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
}

- (OAColorItem *)addNewSelectedColor:(UIColor *)newColor
{
    NSString *newHexColor = [newColor toHexARGBString];
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    [customTrackColors addObject:newHexColor];
    [_settings.customTrackColors set:customTrackColors];

    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    [customTrackColorsLastUsed insertObject:newHexColor atIndex:0];
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];

    [self regenerateSortedPositionAfter:-1 increment:YES];
    OAColorItem *colorItem = [[OAColorItem alloc] initWithHexColor:newHexColor];
    [_availableColors insertObject:colorItem atIndex:_defaultColorValues.count];
    colorItem.sortedPosition = 0;
    [colorItem generateId];
    return colorItem;
}

- (OAColorItem *)duplicateColor:(OAColorItem *)colorItem
{
    NSString *hexColor = [colorItem getHexColor];
    NSInteger indexOfColorItem = [_availableColors indexOfObject:colorItem];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    if (colorItem.isDefault)
        [customTrackColors addObject:hexColor];
    else
        [customTrackColors insertObject:hexColor atIndex:indexOfColorItem - _defaultColorValues.count + 1];
    [_settings.customTrackColors set:customTrackColors];

    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    [customTrackColorsLastUsed insertObject:hexColor atIndex:colorItem.sortedPosition + 1];
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];

    OAColorItem *duplicatedColorItem = [[OAColorItem alloc] initWithHexColor:hexColor];
    duplicatedColorItem.sortedPosition = colorItem.sortedPosition + 1;
    [self regenerateSortedPositionAfter:colorItem.sortedPosition increment:YES];
    if (colorItem.isDefault)
        [_availableColors addObject:duplicatedColorItem];
    else
        [_availableColors insertObject:duplicatedColorItem atIndex:indexOfColorItem + 1];
    [duplicatedColorItem generateId];
    return duplicatedColorItem;
}

- (void)deleteColor:(OAColorItem *)colorItem
{
    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    [customTrackColorsLastUsed removeObjectAtIndex:colorItem.sortedPosition];
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    [customTrackColors removeObjectAtIndex:[_availableColors indexOfObject:colorItem] - _defaultColorValues.count];
    [_settings.customTrackColors set:customTrackColors];

    [_availableColors removeObject:colorItem];
    if (_availableColors.count > colorItem.sortedPosition)
        [self regenerateSortedPositionAfter:colorItem.sortedPosition increment:NO];
}

- (void)selectColor:(OAColorItem *)colorItem
{
    if (colorItem)
    {
        NSString *hexColor = [colorItem getHexColor];
        NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
        [customTrackColorsLastUsed removeObjectAtIndex:colorItem.sortedPosition];
        [customTrackColorsLastUsed insertObject:hexColor atIndex:0];
        [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
        [self regenerateSortedPositionAfter:-1 increment:YES];
        [self regenerateSortedPositionAfter:colorItem.sortedPosition increment:NO];
        colorItem.sortedPosition = 0;
        [colorItem generateId];
    }
}

- (NSArray<OAColorItem *> *)getAvailableColorsSortingByKey
{
    return _availableColors;
}

- (NSArray<OAColorItem *> *)getAvailableColorsSortingByLastUsed
{
    return [_availableColors sortedArrayUsingComparator:^NSComparisonResult(OAColorItem *obj1, OAColorItem *obj2) {
        return [@(obj1.sortedPosition) compare:@(obj2.sortedPosition)];
    }];
}

- (OAColorItem *)getColorItemWithValue:(int)value
{
    for (OAColorItem *colorItem in _availableColors)
    {
        if (((int)colorItem.value) == value)
            return colorItem;
    }

    for (OAColorItem *colorItem in _availableColors)
    {
        if (value == 0 && [colorItem.key isEqualToString:kDefaulRedColorName])
            return colorItem;
    }

    [self addNewSelectedColor:UIColorFromARGB(value)];
    return _availableColors.lastObject;
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
