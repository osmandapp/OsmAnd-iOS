//
//  OAExternalTimeFormatter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAExternalTimeFormatter.h"

@implementation OAExternalTimeFormatter

+ (std::function<std::string (int, int, bool)> ) getExternalTimeFormatterCallback
{
    return formattingCallback;
}

std::string formattingCallback (int hours, int minutes, bool appendAmPM) {
    return [OAExternalTimeFormatter formatTime:hours minutes:minutes appendAmPM:appendAmPM].UTF8String;
}

+ (NSString *) formatTime:(int)hours minutes:(int)minutes  appendAmPM:(BOOL)appendAmPM
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    components.hour = hours;
    components.minute = minutes;
    date = [calendar dateFromComponents:components];
    
    if (appendAmPM)
    {
        return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"h:mm"];
        return [formatter stringFromDate:date];
    }
}

+ (BOOL) isCurrentRegionWithAmpmOnLeft
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setLocale:[NSLocale currentLocale]];
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
    for (int i = 0; i < 7; i++)
    {
        weekdays.push_back([self.class getTranslatesWeekday:i].UTF8String);
    }
    return weekdays;
}

+ (std::vector<std::string>) getLocalizedMonths
{
    std::vector<std::string> months;
    for (int i = 0; i < 12; i++)
    {
        months.push_back([self.class getTranslatesMonth:i].UTF8String);
    }
    return months;
}

+ (NSString *) getTranslatesWeekday:(int)number
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    components.weekday = number;
    date = [calendar dateFromComponents:components];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"EEE"];
    return [formatter stringFromDate:date];
}

+ (NSString *) getTranslatesMonth:(int)number
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    components.month = number;
    date = [calendar dateFromComponents:components];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MMM"];
    return [formatter stringFromDate:date];
}

@end
