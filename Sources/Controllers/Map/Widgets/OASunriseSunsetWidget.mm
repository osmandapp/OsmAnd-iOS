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
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"

@implementation OASunriseSunsetWidget
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASunriseSunsetWidgetState *_state;
    NSArray<NSString *> *_items;
    OsmAnd::PointI _cachedTarget31;
    OsmAnd::LatLon _cachedCenterLatLon;
}

- (instancetype)initWithState:(OASunriseSunsetWidgetState *)state
                      appMode:(OAApplicationMode *)appMode
                 widgetParams:(NSDictionary *)widgetParams
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _state = state;
        self.widgetType = [state getWidgetType];
        [self configurePrefsWithId:state.customId appMode:appMode widgetParams:widgetParams];
        
        __weak OASunriseSunsetWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        
        [self setText:@"-" subtext:@""];
        [self setIcon:[_state getWidgetIconName]];
    }
    return self;
}

- (BOOL) updateInfo
{
    [self updateCachedLocation];
    if ([self isShowTimeLeft])
    {
        NSTimeInterval leftTime = [self getTimeLeft];
        NSString *left = [self formatTimeLeft:leftTime];
        _items = [left componentsSeparatedByString:@" "];
    }
    else
    {
        NSTimeInterval nextTime = [self getNextTime];
        NSString *next = [self formatNextTime:nextTime];
        _items = [next componentsSeparatedByString:@" "];
    }
    if (_items.count > 1)
        [self setText:_items.firstObject subtext:_items.lastObject];
    else
        [self setText:_items.firstObject subtext:nil];
    
    [self setContentTitle:[self getWidgetName]];
    
    if (OAWidgetType.sunPosition == self.widgetType)
    {
        [self setIcon:[_state getWidgetIconName]];
    }
  
    return YES;
}

- (void) onWidgetClicked
{
    if ([self isShowTimeLeft])
        [[self getPreference] set:EOASunriseSunsetNext];
    else
        [[self getPreference] set:EOASunriseSunsetTimeLeft];
    [self updateInfo];
}

- (BOOL) isShowTimeLeft
{
    return [[self getPreference] get] == EOASunriseSunsetTimeLeft;
}

- (OACommonInteger *) getPreference
{
    return [_state getPreference];
}

- (OAWidgetState *)getWidgetState
{
    return _state;
}

- (OATableDataModel *)getSettingsData:(OAApplicationMode *)appMode
{
    OAWidgetType *type = [_state getWidgetType];
    
    OATableDataModel *data = [[OATableDataModel alloc] init];
    OATableSectionData *section = [data createNewSection];
    section.headerText = OALocalizedString(@"shared_string_settings");
    SunPositionMode sunPositionMode = (SunPositionMode)[[_state getSunPositionPreference] get:appMode];

    if (type == OAWidgetType.sunPosition)
    {
        OATableRowData *row = section.createNewRow;
        row.cellType = OAValueTableViewCell.getCellIdentifier;
        row.key = @"value_pref";
        row.title = OALocalizedString(@"shared_string_mode");
        row.descr = OALocalizedString(@"shared_string_mode");
        [row setObj:_state.getSunPositionPreference forKey:@"pref"];
        
        [row setObj:[self getTitleForSunPositionMode:sunPositionMode] forKey:@"value"];
        [row setObj:self.getPossibleFormatValues forKey:@"possible_values"];
    }
    
    OATableRowData *row = section.createNewRow;
    row.cellType = OAValueTableViewCell.getCellIdentifier;
    row.key = @"value_pref";
    NSString *title = OALocalizedString(type == OAWidgetType.sunPosition ? @"shared_string_format" : @"recording_context_menu_show");

    row.title = title;
    row.descr = title;

    [row setObj:_state.getPreference forKey:@"pref"];
    [row setObj:[self getTitle:(EOASunriseSunsetMode)[_state.getPreference get:appMode] sunPositionMode:sunPositionMode] forKey:@"value"];
    [row setObj:self.getPossibleValues forKey:@"possible_values"];
   
    return data;
}

- (NSArray<OATableRowData *> *)getPossibleFormatValues
{
    NSMutableArray<OATableRowData *> *res = [NSMutableArray array];
    
    NSDictionary *dict = @{
        @(SunPositionModeSunPositionMode):OALocalizedString(@"shared_string_next_event"),
        @(SunPositionModeSunsetMode):OALocalizedString(@"map_widget_sunset"),
        @(SunPositionModeSunriseMode):OALocalizedString(@"map_widget_sunrise")
    };
    
    for (NSNumber *key in dict)
    {
        OATableRowData *row = [[OATableRowData alloc] init];
        row.cellType = OASimpleTableViewCell.getCellIdentifier;
        [row setObj:key forKey:@"value"];
        row.title = dict[key];
        [res addObject:row];
    }
    
    return res;
}

- (NSArray<OATableRowData *> *) getPossibleValues
{
    NSMutableArray<OATableRowData *> *res = [NSMutableArray array];
    SunPositionMode sunPositionMode = (SunPositionMode)[[_state getSunPositionPreference] get];

    OATableRowData *row = [[OATableRowData alloc] init];
    row.cellType = OASimpleTableViewCell.getCellIdentifier;
    [row setObj:@(EOASunriseSunsetTimeLeft) forKey:@"value"];
    row.title = [self getTitle:EOASunriseSunsetTimeLeft sunPositionMode:sunPositionMode];
    row.descr = [self getDescription:EOASunriseSunsetTimeLeft];
    [res addObject:row];

    row = [[OATableRowData alloc] init];
    row.cellType = OASimpleTableViewCell.getCellIdentifier;
    [row setObj:@(EOASunriseSunsetNext) forKey:@"value"];
    row.title = [self getTitle:EOASunriseSunsetNext sunPositionMode:sunPositionMode];
    row.descr = [self getDescription:EOASunriseSunsetNext];
    [res addObject:row];

    return res;
}

- (NSString *)getWidgetName {
    SunPositionMode sunPositionMode = (SunPositionMode)[[_state getSunPositionPreference] get];
    
    NSString *sunsetStringId = OALocalizedString(@"map_widget_sunset");
    NSString *sunriseStringId = OALocalizedString(@"map_widget_sunrise");
    NSMutableString *result = [NSMutableString string];
    
    if (OAWidgetType.sunset == self.widgetType || (OAWidgetType.sunPosition == self.widgetType && sunPositionMode == SunPositionModeSunsetMode)) {
        [result appendString:sunsetStringId];
    } else if (OAWidgetType.sunPosition == self.widgetType && sunPositionMode == SunPositionModeSunPositionMode) {
        [result appendString:_state.lastIsDayTime ? sunsetStringId : sunriseStringId];
    } else {
        [result appendString:sunriseStringId];
    }
    
    EOASunriseSunsetMode sunriseSunsetMode = (EOASunriseSunsetMode)[[self getPreference] get];
    if (sunriseSunsetMode == EOASunriseSunsetNext)
    {
        [result appendFormat:@", %@", OALocalizedString(@"shared_string_next")];
    }
    else if (sunriseSunsetMode == EOASunriseSunsetTimeLeft)
    {
        [result appendFormat:@", %@", OALocalizedString(@"map_widget_sunrise_sunset_time_left")];
    }
    
    return result;
}

- (NSString *)getTitleForSunPositionMode:(SunPositionMode)mode {
    switch (mode)
    {
        case SunPositionModeSunPositionMode:
            return OALocalizedString(@"shared_string_next_event");
        case SunPositionModeSunsetMode:
            return OALocalizedString(@"map_widget_sunset");
        case SunPositionModeSunriseMode:
            return OALocalizedString(@"map_widget_sunrise");
    }
}

- (NSString *)getTitle:(EOASunriseSunsetMode)ssm sunPositionMode:(SunPositionMode)sunPositionMode
{
    switch (ssm)
    {
        case EOASunriseSunsetTimeLeft:
            return OALocalizedString(@"map_widget_sunrise_sunset_time_left");
        case EOASunriseSunsetNext:
            return [self getNextEventString:sunPositionMode];
        default:
            return @"";
    }
}

- (NSString *)getNextEventString:(SunPositionMode)sunPositionMode {
    OAWidgetType *type = [_state getWidgetType];
    NSString *eventString = @"";
    
    if (OAWidgetType.sunPosition == type)
    {
        switch (sunPositionMode)
        {
            case SunPositionModeSunriseMode:
                eventString = @"map_widget_next_sunrise";
                break;
            case SunPositionModeSunsetMode:
                eventString = @"map_widget_next_sunset";
                break;
            default:
                eventString = @"shared_string_next_event";
                break;
        }
    }
    else
    {
        eventString = OAWidgetType.sunrise == type ? @"map_widget_next_sunrise" : @"map_widget_next_sunset";
    }

    return OALocalizedString(eventString);
}

- (NSString *)getDescription:(EOASunriseSunsetMode)ssm
{
    switch (ssm)
    {
        case EOASunriseSunsetTimeLeft:
        {
            NSTimeInterval leftTime = [self getTimeLeft];
            return [self formatTimeLeft:leftTime];
        }
        case EOASunriseSunsetNext:
        {
            NSTimeInterval nextTime = [self getNextTime];
            return [self formatNextTime:nextTime];
        }
        default:
            return @"";
    }
}

- (NSTimeInterval)getTimeLeft
{
    NSTimeInterval nextTime = [self getNextTime];
    return nextTime > 0 ? abs(nextTime - NSDate.date.timeIntervalSince1970) : -1;
}

- (NSTimeInterval)getNextTime
{
    NSDate *now = [NSDate date];
    SunriseSunset *sunriseSunset = [self createSunriseSunset:now];
    
    NSDate *sunrise = [sunriseSunset getSunrise];
    NSDate *sunset = [sunriseSunset getSunset];
    NSDate *nextTimeDate;
    SunPositionMode sunPositionMode = (SunPositionMode)[[_state getSunPositionPreference] get];
    OAWidgetType *type = [_state getWidgetType];
    if (OAWidgetType.sunset == type || (OAWidgetType.sunPosition == type && sunPositionMode == SunPositionModeSunsetMode))
    {
        nextTimeDate = sunset;
    }
    else if (OAWidgetType.sunPosition == type && sunPositionMode == SunPositionModeSunPositionMode)
    {
        _state.lastIsDayTime = [sunriseSunset isDaytime];
        nextTimeDate = _state.lastIsDayTime ? sunset : sunrise;
    }
    else
    {
        nextTimeDate = sunrise;
    }
    
    if (nextTimeDate)
    {
        if ([nextTimeDate compare:now] == NSOrderedAscending)
        {
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 1;

            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            nextTimeDate = [theCalendar dateByAddingComponents:dayComponent toDate:nextTimeDate options:0];
        }
        return nextTimeDate.timeIntervalSince1970;
    }
    return 0;
}

- (SunriseSunset *) createSunriseSunset:(NSDate *)date
{
    double longitude = _cachedCenterLatLon.longitude;
    SunriseSunset *sunriseSunset = [[SunriseSunset alloc] initWithLatitude:_cachedCenterLatLon.latitude longitude:longitude < 0 ? 360 + longitude : longitude dateInputIn:date tzIn:[NSTimeZone localTimeZone]];
    return sunriseSunset;
}

- (NSString *) formatTimeLeft:(NSTimeInterval)timeLeft
{
    return [self getFormattedTime:timeLeft];
}

- (NSString*) getFormattedTime:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    NSString *unitStr = OALocalizedString(@"int_hour");
    if (hours > 0)
        [time appendFormat:@"%02d:", hours];
    [time appendFormat:@"%02d", minutes];
    if (hours == 0)
    {
        [time appendFormat:@":%02d", seconds];
        unitStr = OALocalizedString(@"short_min");
    }
    [time appendFormat:@" %@", unitStr];
    
    return time;
}

- (NSString *) formatNextTime:(NSTimeInterval)nextTime
{
    NSDate *nextDate = [NSDate dateWithTimeIntervalSince1970:nextTime];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm EE"];
    return [dateFormatter stringFromDate:nextDate];
}

- (void) updateCachedLocation
{
    OsmAnd::PointI currentTarget31 = [OARootViewController instance].mapPanel.mapViewController.mapView.target31;
    if (_cachedTarget31 != currentTarget31)
    {
        _cachedTarget31 = currentTarget31;
        OsmAnd::LatLon newCenterLocation = OsmAnd::Utilities::convert31ToLatLon(_cachedTarget31);
        if (![self isLocationsEqual:_cachedCenterLatLon with:newCenterLocation])
            _cachedCenterLatLon = newCenterLocation;
    }
}

- (BOOL) isLocationsEqual:(OsmAnd::LatLon)firstLocation with:(OsmAnd::LatLon)secondLocation
{
    return fabs(firstLocation.longitude - secondLocation.longitude) <= 0.0001;
}

@end
