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
        sunriseSunsetDate = [sunriseSunset getSunrise];
        [dateFormatter setDateFormat:@"HH:mm"];
        time = [dateFormatter stringFromDate:sunriseSunsetDate];
        [dateFormatter setDateFormat:@"EE"];
        day = [dateFormatter stringFromDate:sunriseSunsetDate];
        
        nextSunriseSunsetDate = [nextSunriseSunset getSunrise];
        [dateFormatter setDateFormat:@"HH:mm"];
        nextTime = [dateFormatter stringFromDate:nextSunriseSunsetDate];
        [dateFormatter setDateFormat:@"EE"];
        nextDay = [dateFormatter stringFromDate:nextSunriseSunsetDate];
    }
    else
    {
        sunriseSunsetDate = [sunriseSunset getSunset];
        [dateFormatter setDateFormat:@"HH:mm"];
        time = [dateFormatter stringFromDate:sunriseSunsetDate];
        [dateFormatter setDateFormat:@"EE"];
        day = [dateFormatter stringFromDate:sunriseSunsetDate];
        
        nextSunriseSunsetDate = [nextSunriseSunset getSunset];
        [dateFormatter setDateFormat:@"HH:mm"];
        nextTime = [dateFormatter stringFromDate:nextSunriseSunsetDate];
        [dateFormatter setDateFormat:@"EE"];
        nextDay = [dateFormatter stringFromDate:nextSunriseSunsetDate];
    }
    if ([actualTime compare:sunriseSunsetDate] == NSOrderedDescending)
        return @[nextTime, nextDay];
    else
        return @[time, day];
}

+ (NSArray<NSString *> *) getTimeLeftUntilSunriseSunset:(BOOL)isSunrise
{
    NSDate *actualTime = [NSDate date];
    NSDate *sunriseSunsetDate;
    NSDate *nextSunriseSunsetDate;
    NSString *timeLeft;
    NSString *subText;
    SunriseSunset *sunriseSunset = [self createSunriseSunset:actualTime forNextDay:NO];
    SunriseSunset *nextSunriseSunset = [self createSunriseSunset:actualTime forNextDay:YES];
    
    if (isSunrise)
    {
        sunriseSunsetDate = [sunriseSunset getSunrise];
        nextSunriseSunsetDate = [nextSunriseSunset getSunrise];
    }
    else
    {
        sunriseSunsetDate = [sunriseSunset getSunset];
        nextSunriseSunsetDate = [nextSunriseSunset getSunset];
    }
    if ([actualTime compare:sunriseSunsetDate] == NSOrderedDescending)
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:actualTime toDate:nextSunriseSunsetDate options:0];
        timeLeft = [NSString stringWithFormat:@"%ld:%ld", [components hour], [components minute]];
        subText = [components hour] > 0 ? OALocalizedString(@"int_hour") : OALocalizedString(@"int_min");
    }
    else
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:actualTime toDate:sunriseSunsetDate options:0];
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
