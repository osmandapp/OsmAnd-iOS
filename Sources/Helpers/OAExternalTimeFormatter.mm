//
//  OAExternalTimeFormatter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAExternalTimeFormatter.h"

static NSLocale *_usingLocale;

@implementation OAExternalTimeFormatter

+ (std::function<std::string (int, int, bool)> ) getExternalTimeFormatterCallback
{
    return formattingCallback;
}

std::string formattingCallback (int hours, int minutes, bool appendAmPM) {
    return [OAExternalTimeFormatter formatTime:hours minutes:minutes appendAmPM:appendAmPM].UTF8String;
}

+ (NSString *) formatTime:(int)hours minutes:(int)minutes appendAmPM:(BOOL)appendAmPM
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    components.hour = hours;
    components.minute = minutes;
    date = [calendar dateFromComponents:components];
    
    if (appendAmPM)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:_usingLocale];
        [formatter setDateStyle:NSDateFormatterNoStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        return [formatter stringFromDate:date];
    }
    else
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setLocale:_usingLocale];
        [formatter setDateFormat:@"h:mm"];
        return [formatter stringFromDate:date];
    }
}


+ (std::function<std::vector<std::vector<std::string>> (std::string)> ) getExternalLocalisationUpdatingCallback
{
    return localisationUpdatingCallback;
}

std::vector<std::vector<std::string>> localisationUpdatingCallback (std::string locale) {
    NSString* preparedLocale = [NSString stringWithUTF8String:locale.c_str()];
    return [OAExternalTimeFormatter updateLocalisations:preparedLocale];
}

+ (std::vector<std::vector<std::string>>) updateLocalisations:(NSString *)locale
{
    _usingLocale = [NSLocale currentLocale];
    if (locale && locale.length > 0)
    {
        NSLocale *loadedLocale = [NSLocale localeWithLocaleIdentifier:locale];
        if (loadedLocale)
            _usingLocale = loadedLocale;
    }
    
    std::vector<std::string> weekdays = [self getLocalizedWeekdays];
    std::vector<std::string> months = [self getLocalizedMonths];
    std::string isAmpmOnLeft = [self isCurrentRegionWithAmpmOnLeft] ? "true" : "false";
    std::vector<std::vector<std::string>> updatedSettings = std::vector<std::vector<std::string>>{weekdays, weekdays, std::vector<std::string>{isAmpmOnLeft}};
    
    return updatedSettings;
}

+ (BOOL) isCurrentRegionWith12HourTimeFormat
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setLocale:_usingLocale];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *fullFormattedTimeString = [formatter stringFromDate:currentDate];
    
    [formatter setDateFormat:@"a"];
    NSString *ampmString = [formatter stringFromDate:currentDate];
    
    return [fullFormattedTimeString containsString:ampmString];
}

+ (BOOL) isCurrentRegionWithAmpmOnLeft
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setLocale:_usingLocale];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *fullFormattedTimeString = [formatter stringFromDate:currentDate];
    
    [formatter setDateFormat:@"a"];
    NSString *ampmString = [formatter stringFromDate:currentDate];
    
    return [fullFormattedTimeString hasPrefix:ampmString];
}

+ (std::vector<std::string>) getLocalizedWeekdays
{
    std::vector<std::string> weekdays;
    for (int i = 1; i <= 7; i++)
    {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitWeekOfMonth) fromDate:date];
        components.weekday = i;
        date = [calendar dateFromComponents:components];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setLocale:_usingLocale];
        [formatter setDateFormat:@"EEE"];
        NSString *localizedWeek = [formatter stringFromDate:date];
        weekdays.push_back(localizedWeek.UTF8String);
    }
    return weekdays;
}

+ (std::vector<std::string>) getLocalizedMonths
{
    std::vector<std::string> months;
    for (int i = 1; i <= 12; i++)
    {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitMonth) fromDate:date];
        components.month = i;
        date = [calendar dateFromComponents:components];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setLocale:_usingLocale];
        [formatter setDateFormat:@"MMM"];
        NSString *localizedMonth = [formatter stringFromDate:date];
        months.push_back(localizedMonth.UTF8String);
    }
    return months;
}

+ (void) setLocale:(NSString *)regionId
{
    _usingLocale = [NSLocale currentLocale];
    if (regionId && regionId.length > 0)
    {
        NSLocale *loadedLocale = [NSLocale localeWithLocaleIdentifier:regionId];
        if (loadedLocale)
            _usingLocale = loadedLocale;
    }
}

@end
