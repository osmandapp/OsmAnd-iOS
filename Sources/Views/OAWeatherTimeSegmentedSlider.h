//
//  OAWeatherTimeSegmentedSlider.h
//  OsmAnd
//
//  Created by Max Kojin on 13/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASegmentedSlider.h"

static const double kForecastStepDuration = 2.5; // 2.5 minutes step
static const int kForecastStepsPerHour = 60.0 / kForecastStepDuration; // 24 steps in hour
static const int kForecastWholeDayMarksCount = 24 * kForecastStepsPerHour + 1; // 577 steps in slider

@class OAWeatherToolbarDatesHandler;


@interface OAWeatherTimeSegmentedSlider : OASegmentedSlider

@property (nonatomic) OAWeatherToolbarDatesHandler *datesHandler;

- (void) commonInit;

- (void) updateTimeValues:(NSDate *)date;

- (NSArray<NSDate *> *) getTimeValues;
- (NSInteger) getTimeValuesCount;
- (NSDate *) getSelectedDate;

- (NSInteger) getSelectedTimeIndex:(NSDate *)date;
- (void) setCurrentMark:(NSInteger)index;

@end
