//
//  OAWeatherToolbarHandlers.mm
//  OsmAnd
//
//  Created by Skalii on 17.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherToolbarHandlers.h"
#import "OAMapStyleSettings.h"
#import "OAAppData.h"
#import "OsmAndApp.h"
#import "Localization.h"

#define kTempIndex 0
#define kPressureIndex 1
#define kWindIndex 2
#define kCloudIndex 3
#define kPrecipitationIndex 4
#define kContoursIndex 5

@implementation OAWeatherToolbarLayersHandler
{
    OAMapStyleSettings *_styleSettings;
    OsmAndAppInstance _app;

    NSMutableArray<NSMutableDictionary *> *_data;
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
    _styleSettings = [OAMapStyleSettings sharedInstance];
    _app = [OsmAndApp instance];

    [self updateData];
}

- (void)updateData
{
    NSMutableArray<NSMutableDictionary *> *layersData = [NSMutableArray array];

    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"selected": @(_app.data.weatherTemp)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"selected": @(_app.data.weatherPressure)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"selected": @(_app.data.weatherWind)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"selected": @(_app.data.weatherCloud)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"selected": @(_app.data.weatherPrecip)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"selected": @(_app.data.weatherWindAnimation)
    }]];
    
    _data = layersData;
}

- (BOOL)isAllLayersDisabled
{
    for (NSDictionary *item in _data)
    {
        if ([item[@"selected"] boolValue])
            return NO;
    }
    return YES;
}

@end

@implementation OAWeatherToolbarDatesHandler
{
    NSMutableArray<NSMutableDictionary *> *_data;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self updateData];
    }
    return self;
}

- (void)updateData
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDate *selectedDate = [calendar startOfDayForDate:[OAUtilities getCurrentTimezoneDate:[NSDate date]]];

    NSMutableArray<NSMutableDictionary *> *layersData = [NSMutableArray array];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"title": OALocalizedString(@"today").capitalizedString,
            @"value": selectedDate
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"title": OALocalizedString(@"tomorrow"),
            @"value": [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:selectedDate options:0]
    }]];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = calendar.timeZone;
    [formatter setDateFormat:@"E"];
    
    // Next 5 days (excluding today and tomorrow)
    for (NSInteger i = 2; i <= 6; i++)
    {
       NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:i toDate:selectedDate options:0];
        [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                @"title": [formatter stringFromDate:date],
                @"value": date
        }]];
    }

    _data = layersData;
}

- (NSArray<NSMutableDictionary *> *)getData
{
    return _data;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    if (self.delegate)
        [self.delegate updateData:_data index:index];
}

@end
