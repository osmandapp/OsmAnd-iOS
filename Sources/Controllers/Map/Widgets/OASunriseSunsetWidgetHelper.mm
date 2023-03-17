//
//  OASunriseSunsetWidgetHelper.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 14.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunriseSunsetWidgetHelper.h"
#import "OAMapLayers.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "SunriseSunset.h"

@implementation OASunriseSunsetWidgetHelper

+ (NSArray<NSString *> *) getNextSunriseSunset:(BOOL)isSunrise
{
    NSDate *actualTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *sunriseSunsetDate;
    NSDate *nextSunriseSunsetDate;
    NSString *time;
    NSString *nextTime;
    NSString *day;
    NSString *nextDay;
    SunriseSunset *sunriseSunset = [self createSunriseSunset:actualTime forNextDay:NO];
    SunriseSunset *nextSunriseSunset = [self createSunriseSunset:actualTime forNextDay:YES];
    
    if (isSunrise)
    {
        time = [self getFormattedTime:[sunriseSunset getSunrise]];
        day = [self getFormattedDay:[sunriseSunset getSunrise]];
        nextTime = [self getFormattedTime:[nextSunriseSunset getSunrise]];
        nextDay = [self getFormattedDay:[nextSunriseSunset getSunrise]];
    }
    else
    {
        time = [self getFormattedTime:[sunriseSunset getSunset]];
        day = [self getFormattedDay:[sunriseSunset getSunset]];
        nextTime = [self getFormattedTime:[nextSunriseSunset getSunset]];
        nextDay = [self getFormattedDay:[nextSunriseSunset getSunset]];
    }
    if ([actualTime compare:sunriseSunsetDate] == NSOrderedDescending)
        return @[nextTime, nextDay];
    else
        return @[time, day];
}

+ (NSString *) getFormattedTime:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) getFormattedDay:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EE"];;
    return [dateFormatter stringFromDate:date];
}

+ (NSArray<NSString *> *) getTimeLeftUntilSunriseSunset:(BOOL)isSunrise
{
    NSDate *actualTime = [NSDate date];
    NSDate *date;
    NSDate *nextDate;
    NSString *timeLeft;
    NSString *subText;
    SunriseSunset *sunriseSunset = [self createSunriseSunset:actualTime forNextDay:NO];
    SunriseSunset *nextSunriseSunset = [self createSunriseSunset:actualTime forNextDay:YES];
    
    date = isSunrise ? [sunriseSunset getSunrise] : [sunriseSunset getSunset];
    nextDate = isSunrise ? [nextSunriseSunset getSunrise] : [nextSunriseSunset getSunset];
    
    if ([actualTime compare:date] == NSOrderedDescending)
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:actualTime toDate:nextDate options:0];
        timeLeft = [NSString stringWithFormat:@"%ld:%ld", [components hour], [components minute]];
        subText = [components hour] > 0 ? OALocalizedString(@"int_hour") : OALocalizedString(@"int_min");
    }
    else
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:actualTime toDate:date options:0];
        timeLeft = [NSString stringWithFormat:@"%ld:%ld", [components hour], [components minute]];
        subText = [components hour] > 0 ? OALocalizedString(@"int_hour") : OALocalizedString(@"int_min");
    }
    return @[timeLeft, subText];
}

+ (SunriseSunset *) createSunriseSunset:(NSDate *)date forNextDay:(BOOL)nextDay
{
    CLLocation *location = OsmAndApp.instance.locationServices.lastKnownLocation;
    double longitude = location.coordinate.longitude;
    SunriseSunset *sunriseSunset = [[SunriseSunset alloc] initWithLatitude:location.coordinate.latitude longitude:longitude < 0 ? 360 + longitude : longitude dateInputIn:date tzIn:[NSTimeZone localTimeZone] forNextDay:nextDay];
    return sunriseSunset;
}

@end
