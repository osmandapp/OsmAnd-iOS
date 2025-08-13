//
//  OAWeatherTimeSegmentedSlider.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 13/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAWeatherTimeSegmentedSlider.h"
#import "OAWeatherHelper.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapLayers.h"
#import "OAWeatherToolbarHandlers.h"

static const double kForecastStepDuration = 2.5; // 2.5 minutes step
static const int kForecastStepsPerHour = 60.0 / kForecastStepDuration; // 24 steps in hour
static const int kForecastWholeDayMarksCount = 24 * kForecastStepsPerHour + 1; // 577 steps in slider

@implementation OAWeatherTimeSegmentedSlider
{
    NSCalendar *_currentTimezoneCalendar;
    NSArray<NSDate *> *_timeValues;
}

+ (int) getForecastStepsPerHour
{
    return kForecastStepsPerHour;
}

- (void) commonInit
{
    _currentTimezoneCalendar = NSCalendar.autoupdatingCurrentCalendar;
    _currentTimezoneCalendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    self.stepsAmountWithoutDrawMark = kForecastWholeDayMarksCount;
    [self clearTouchEventsUpInsideUpOutside];
    [self setUsingExtraThumbInset:YES];
}

- (void) updateTimeValues:(NSDate *)date
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    NSDate *startOfDay = [calendar startOfDayForDate:date];
    
    NSMutableArray<NSDate *> *timeValues = [NSMutableArray array];
    
    [timeValues addObject:startOfDay];
    
    NSInteger hourSteps = 9 + (9 - 1) * 2;
    
    for (NSInteger hour = 1; hour < hourSteps; hour++)
    {
        NSDate *nextHourDate = [calendar dateByAddingUnit:NSCalendarUnitHour
                                                    value:hour
                                                   toDate:startOfDay
                                                  options:0];
        [timeValues addObject:nextHourDate];
    }
    
    NSInteger inHourStepsCount = kForecastStepsPerHour;
    NSMutableArray<NSDate *> *timeValuesTotal = [NSMutableArray array];
    
    for (NSInteger index = 0; index <= timeValues.count - 1; index++)
    {
        NSDate *data = timeValues[index];
        [timeValuesTotal addObject:data];
        if (index <= timeValues.count - 2)
        {
            for (NSInteger step = 1; step < inHourStepsCount; step++)
            {
                // 0.0  2.5  5.0  7.5  10.0  12.5  15.0 - clear minutes from slider
                // 0.0  3.0  5.0  8.0  10.0  13.0  15.0 - rounded minutes
                NSInteger minutes = round(step * kForecastStepDuration);
            
                NSDate *nextStepDate = [calendar dateByAddingUnit:NSCalendarUnitMinute
                                                            value:minutes
                                                           toDate:data
                                                          options:0];
                
                [timeValuesTotal addObject:nextStepDate];
            }
        }
        
    }
    // [21:00, 21:03, 21:05, 21:08, 21:10, 21:13  ...  23:58, 00:00 ...  20:58, 21:00]
    _timeValues = timeValuesTotal;
}


- (NSArray<NSDate *> *) getTimeValues
{
    return _timeValues;
}

- (NSInteger)getTimeValuesCount
{
    return _timeValues.count;
}

- (NSDate *)getSelectedDate
{
    return _timeValues[[self getIndexForOptionStepsAmountWithoutDrawMark]];
}

- (NSInteger) getSelectedTimeIndex:(NSDate *)date
{
    NSDate *roundedDate = [OAWeatherHelper roundForecastTimeToHour:date];
    return [_currentTimezoneCalendar components:NSCalendarUnitHour fromDate:roundedDate].hour;
}

- (NSDate *) getSelectedGMTDate
{
    return [OARootViewController instance].mapPanel.mapViewController.mapLayers.weatherDate;
}

- (NSInteger) getSelectedDateIndex
{
    NSInteger day = [_currentTimezoneCalendar components:NSCalendarUnitDay fromDate:[self getSelectedGMTDate]].day;
    NSArray<NSDictionary *> *datesData = [_datesHandler getData];
    for (NSInteger i = 0; i < datesData.count; i++)
    {
        NSDate *itemDate = datesData[i][@"value"];
        NSInteger itemDay = [_currentTimezoneCalendar components:NSCalendarUnitDay fromDate:itemDate].day;
        if (day == itemDay)
            return i;
    }

    return 0;
}

- (void) setCurrentMark:(NSInteger)index
{
    NSDate *date = [OAUtilities getCurrentTimezoneDate:[NSDate date]];
    NSInteger minimumForCurrentMark = [_currentTimezoneCalendar startOfDayForDate:date].timeIntervalSince1970;
    NSInteger currentValue = date.timeIntervalSince1970;
    self.currentMarkX = index == 0 ? (currentValue - minimumForCurrentMark) : -1;
    date = [_currentTimezoneCalendar startOfDayForDate:date];
    date = [_currentTimezoneCalendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
    self.maximumForCurrentMark = [_currentTimezoneCalendar startOfDayForDate:date].timeIntervalSince1970 - minimumForCurrentMark;
}

- (NSString *) getSelectingMarkTitleTextAtIndex:(NSInteger)index
{
    if (index < 0 || index >= kForecastWholeDayMarksCount - 1)
    {
        return @"00:00";
    }
    NSInteger hours = index / kForecastStepsPerHour;
    NSInteger minutes = round((index % kForecastStepsPerHour) * kForecastStepDuration); // 0, 3, 5, 8, 10, 13, 15 ...

    NSString *hourString = [NSString stringWithFormat:@"%02ld", (long)hours];
    NSString *minuteString = [NSString stringWithFormat:@"%02ld", minutes];

    return [NSString stringWithFormat:@"%@:%@", hourString, minuteString];
}

@end
