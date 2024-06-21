//
//  OAWeatherToolbarHandlers.mm
//  OsmAnd
//
//  Created by Skalii on 17.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherToolbarHandlers.h"
#import "OAMapStyleSettings.h"
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
        @"img": @"ic_custom_thermometer",
        @"selected": @(_app.data.weatherTemp)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"img": @"ic_custom_air_pressure",
        @"selected": @(_app.data.weatherPressure)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"img": @"ic_custom_wind",
        @"selected": @(_app.data.weatherWind)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"img": @"ic_custom_clouds",
        @"selected": @(_app.data.weatherCloud)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"img": @"ic_custom_precipitation",
        @"selected": @(_app.data.weatherPrecip)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
        @"img": @"ic_custom_contour_lines",
        @"selected": @([_styleSettings isAnyWeatherContourLinesEnabled] || _app.data.contourName.length > 0)
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

- (NSArray *)getData
{
    return _data;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    if (index == kTempIndex)
    {
        BOOL selected = !_app.data.weatherTemp;
        _data[kTempIndex][@"selected"] = @(selected);
        _app.data.weatherTemp = selected;
    }
    else if (index == kPressureIndex)
    {
        BOOL selected = !_app.data.weatherPressure;
        _data[kPressureIndex][@"selected"] = @(selected);
        _app.data.weatherPressure = selected;
    }
    else if (index == kWindIndex)
    {
        BOOL selected = !_app.data.weatherWind;
        _data[kWindIndex][@"selected"] = @(selected);
        _app.data.weatherWind = selected;
    }
    else if (index == kCloudIndex)
    {
        BOOL selected = !_app.data.weatherCloud;
        _data[kCloudIndex][@"selected"] = @(selected);
        _app.data.weatherCloud = selected;
    }
    else if (index == kPrecipitationIndex)
    {
        BOOL selected = !_app.data.weatherPrecip;
        _data[kPrecipitationIndex][@"selected"] = @(selected);
        _app.data.weatherPrecip = selected;
    }
    else if (index == kContoursIndex)
    {
        NSString *contourName = _app.data.contourName;
        BOOL selected = [_styleSettings isAnyWeatherContourLinesEnabled] || contourName.length > 0;
        _data[kContoursIndex][@"selected"] = @(!selected);
        NSString *lastUsedParameterName;
        if (selected)
        {
            if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_TEMP_CONTOUR_LINES_ATTR] || [contourName isEqualToString:WEATHER_TEMP_CONTOUR_LINES_ATTR])
                lastUsedParameterName = WEATHER_TEMP_CONTOUR_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRESSURE_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_PRESSURE_CONTOURS_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_CLOUD_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_CLOUD_CONTOURS_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_WIND_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_WIND_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_WIND_CONTOURS_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR;

            _app.data.contourName = @"";
            _app.data.contourNameLastUsed = lastUsedParameterName;
            [_styleSettings setWeatherContourLinesEnabled:NO
                                    weatherContourLinesAttr:lastUsedParameterName];
        }
        else
        {
            lastUsedParameterName = _app.data.contourNameLastUsed;
            if (lastUsedParameterName.length == 0)
                lastUsedParameterName = WEATHER_TEMP_CONTOUR_LINES_ATTR;
            _app.data.contourName = lastUsedParameterName;
            [_styleSettings setWeatherContourLinesEnabled:YES
                                  weatherContourLinesAttr:lastUsedParameterName];
        }
    }
    
    if (self.delegate)
        [self.delegate updateData:_data type:EOAWeatherToolbarLayers index:-1];
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
        [self.delegate updateData:_data type:EOAWeatherToolbarDates index:index];
}

@end
