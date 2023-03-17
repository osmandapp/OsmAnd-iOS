//
//  OASunriseSunsetWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunriseSunsetWidget.h"
#import "Localization.h"
#import "SunriseSunset.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OsmAndAppImpl.h"

@implementation OASunriseSunsetWidget
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASunriseSunsetWidgetState *_state;
    NSArray<NSString *> *_items;
}

- (instancetype) initWithState:(OASunriseSunsetWidgetState *)state
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _state = state;
        
        __weak OASunriseSunsetWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        
        [self setText:@"-" subtext:@""];
        if ([_state isSunriseMode])
            [self setIcons:@"widget_sunrise_day" widgetNightIcon:@"widget_sunrise_night"];
        else
            [self setIcons:@"widget_sunset_day" widgetNightIcon:@"widget_sunset_night"];
    }
    return self;
}

- (BOOL) updateInfo
{
    if ([_settings.sunriseMode get] == EOASunriseSunsetTimeLeft)
        _items = [self.class getTimeLeftUntilSunriseSunset:[_state isSunriseMode]];
    else
        _items = [self.class getNextSunriseSunset:[_state isSunriseMode]];
    [self setText:_items.firstObject subtext:_items.lastObject];

    return YES;
}

- (void) onWidgetClicked
{
    if ([_settings.sunriseMode get] != EOASunriseSunsetTimeLeft)
        [_settings.sunriseMode set:EOASunriseSunsetTimeLeft];
    
    else
        [_settings.sunriseMode set:EOASunriseSunsetNext];
    [self updateInfo];
}




+ (NSString *) getDescription:(EOASunriseSunsetMode)ssm isSunrise:(BOOL)isSunrise
{
    switch (ssm)
    {
        case EOASunriseSunsetHide:
            return OALocalizedString(@"");
        case EOASunriseSunsetTimeLeft:
        {
            NSArray <NSString *> *values = [self.class getTimeLeftUntilSunriseSunset:isSunrise];
            return [NSString stringWithFormat:@"%@ %@", values.firstObject, values.lastObject];
        }
        case EOASunriseSunsetNext:
        {
            NSArray <NSString *> *values = [self.class getNextSunriseSunset:isSunrise];
            return [NSString stringWithFormat:@"%@ %@", values.firstObject, values.lastObject];
        }
        default:
            return @"";
    }
}

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
