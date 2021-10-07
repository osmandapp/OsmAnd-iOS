//
//  OAGPXAppearanceCollection.m
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXAppearanceCollection.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAGPXDatabase.h"
#import "OAMapStyleSettings.h"

@implementation OAGPXTrackAppearance : NSObject

@end

@implementation OAGPXTrackColor

- (instancetype)initWithKey:(NSString *)key value:(NSInteger)value
{
    self = [super init];
    if (self)
    {
        self.key = key;
        self.title = OALocalizedString(key);
        self.colorValue = value;
        self.color = UIColorFromARGB(value);
    }
    return self;
}

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
                                   value:[NSString stringWithFormat:@"%i", kDefaultWidthMultiplier]];
}

- (BOOL)isCustom
{
    return !self.key || self.key.length == 0;
}

@end

@implementation OAGPXAppearanceCollection
{
    OAMapViewController *_mapViewController;

    NSArray<OAGPXTrackColor *> *_availableColors;
    NSArray<OAGPXTrackWidth *> *_availableWidth;
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
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
}

- (NSArray<OAGPXTrackColor *> *)getAvailableColors
{
    if (_availableColors && [_availableColors count] > 0)
        return _availableColors;

    NSMutableArray<NSString *> *possibleTrackColorKeys = [NSMutableArray new];
    OAMapStyleParameter *currentTrackColor = [[OAMapStyleSettings sharedInstance] getParameter:CURRENT_TRACK_COLOR_ATTR];

    if (currentTrackColor)
    {
        NSArray<OAMapStyleParameterValue *> *currentTrackColorParameters = currentTrackColor.possibleValuesUnsorted;
        [currentTrackColorParameters enumerateObjectsUsingBlock:^(OAMapStyleParameterValue *parameter, NSUInteger ids, BOOL *stop) {
            if (ids != 0)
                [possibleTrackColorKeys addObject:parameter.name];
        }];

        NSMutableArray<OAGPXTrackColor *> *result = [NSMutableArray new];
        NSDictionary<NSString *, NSNumber *> *possibleValues = [_mapViewController getGpxColors];
        [possibleValues enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber *_Nonnull obj, BOOL *_Nonnull stop) {
            if ([possibleTrackColorKeys containsObject:key])
                [result addObject:[[OAGPXTrackColor alloc] initWithKey:key value:obj.integerValue]];
        }];
        _availableColors = [result sortedArrayUsingComparator:^NSComparisonResult(OAGPXTrackColor *obj1, OAGPXTrackColor *obj2) {
            return [@([possibleTrackColorKeys indexOfObject:obj1.key]) compare:@([possibleTrackColorKeys indexOfObject:obj2.key])];
        }];
    }
    else
    {
        _availableColors = [NSArray array];
    }

    return _availableColors;
}

- (OAGPXTrackColor *)getColorForValue:(NSInteger)value
{
    if (!_availableColors || [_availableColors count] == 0)
        [self getAvailableColors];

    for (OAGPXTrackColor *color in _availableColors)
    {
        if (value == 0 && [color.key isEqualToString:@"red"])
            return color;
        else if (color.colorValue == value)
            return color;
    }
    return [[OAGPXTrackColor alloc] initWithKey:@"" value:(value == 0 ? kDefaultTrackColor : value)];
}

- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth
{
    if (_availableWidth && [_availableWidth count] > 0)
        return _availableWidth;

    NSMutableArray<NSString *> *possibleTrackWidthKeys = [NSMutableArray new];
    OAMapStyleParameter *currentTrackWidth = [[OAMapStyleSettings sharedInstance] getParameter:CURRENT_TRACK_WIDTH_ATTR];

    if (currentTrackWidth)
    {
        NSArray<OAMapStyleParameterValue *> *currentTrackWidthParameters = currentTrackWidth.possibleValuesUnsorted;
        [currentTrackWidthParameters enumerateObjectsUsingBlock:^(OAMapStyleParameterValue *parameter, NSUInteger ids, BOOL *stop) {
            if (ids != 0)
                [possibleTrackWidthKeys addObject:parameter.name];
        }];

        NSMutableArray<OAGPXTrackWidth *> *result = [NSMutableArray new];
        NSDictionary<NSString *, NSArray<NSNumber *> *> *possibleValues = [_mapViewController getGpxWidth];
        [possibleValues enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSArray<NSNumber *> *_Nonnull obj, BOOL *_Nonnull stop) {
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

@end
