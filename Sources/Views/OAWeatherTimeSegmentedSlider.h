//
//  OAWeatherTimeSegmentedSlider.h
//  OsmAnd
//
//  Created by Max Kojin on 13/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASegmentedSlider.h"

@class OAWeatherToolbarDatesHandler;


@interface OAWeatherTimeSegmentedSlider : OASegmentedSlider

@property (nonatomic) OAWeatherToolbarDatesHandler *datesHandler;

+ (int) getForecastStepsPerHour;

- (void) commonInit;

- (void) updateTimeValues:(NSDate *)date;

- (NSArray<NSDate *> *) getTimeValues;
- (NSInteger) getTimeValuesCount;
- (NSDate *) getSelectedDate;

- (NSInteger) getSelectedTimeIndex:(NSDate *)date;
- (void) setCurrentMark:(NSInteger)index;

@end
