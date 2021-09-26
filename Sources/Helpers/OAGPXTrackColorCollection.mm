//
//  OAGPXTrackColorCollection.m
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXTrackColorCollection.h"
#import "Localization.h"
#import "OAGPXDatabase.h"
#import "OAMapViewController.h"

@implementation OAGPXTrackColor

-(instancetype)initWithName:(NSString *)name colorValue:(NSInteger)colorValue
{
    self = [super init];
    if (self) {
        self.name = OALocalizedString(name);
        self.colorValue = colorValue;
        self.color = UIColorFromARGB(colorValue);
    }
    return self;
}

@end

@implementation OAGPXTrackColorCollection
{
    OAMapViewController *_mapViewController;
    
    NSArray<OAGPXTrackColor *> *_availableColors;
}

-(instancetype)initWithMapViewController:(OAMapViewController *)mapViewController
{
    self = [super init];
    if (self) {
        _mapViewController = mapViewController;
    }
    return self;
}

-(NSArray<OAGPXTrackColor *> *) getAvailableGPXColors
{
    if (_availableColors && [_availableColors count] > 0)
        return _availableColors;
    
    NSMutableArray<OAGPXTrackColor *> *result = [NSMutableArray new];
    NSDictionary<NSString *, NSNumber *> *possibleValues = [_mapViewController getGpxColors];
    [possibleValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        [result addObject:[[OAGPXTrackColor alloc] initWithName:key colorValue:obj.integerValue]];
    }];
    _availableColors = [result sortedArrayUsingComparator:^NSComparisonResult(OAGPXTrackColor *first, OAGPXTrackColor *second) {
        return [first.name caseInsensitiveCompare:second.name];
    }];
    return _availableColors;
}

-(OAGPXTrackColor *) getColorForValue:(NSInteger)value
{
    if (!_availableColors || [_availableColors count] == 0)
        [self getAvailableGPXColors];
    
    for (OAGPXTrackColor *color in _availableColors) {
        if (value == 0 && [color.name isEqualToString:@"red"])
            return color;
        else if (color.colorValue == value)
            return color;
    }
    return [[OAGPXTrackColor alloc] initWithName:@"" colorValue:(value == 0 ? kDefaultTrackColor : value)];
}

@end
