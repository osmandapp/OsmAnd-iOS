//
//  OAOpeningHoursParser.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAOpeningHoursRule;

@interface OAOpeningHoursParser : NSObject

@property (nonatomic, readonly) NSString *openingHours;

- (instancetype)initWithOpeningHours:(NSString *) openingHours;

- (BOOL) isOpenedForTime:(NSDate *) time;
+ (int) getDayIndex:(int) i;
+ (void) runTest;

@end


/**
 * This class contains the entire OpeningHours schema and
 * offers methods to check directly weather something is open
 *
 * @author sander
 */
@interface OAOpeningHours : NSObject

- (instancetype)initWithRules:(NSArray *) rules;
- (instancetype)init;

- (void) addRule:(id<OAOpeningHoursRule>) r;
- (NSArray *) getRules;
- (BOOL) isOpenedForTime:(NSDate *) date;
- (NSString *) getCurrentRuleTime:(NSDate *) date;
- (NSString *) toString;
- (NSString *) toStringNoMonths;
- (NSString *) toLocalStringNoMonths;

@end


/**
 * Interface to represent a single rule
 * <p/>
 * A rule consist out of
 * - a collection of days/dates
 * - a time range
 */
@protocol OAOpeningHoursRule <NSObject>

@required
/**
 * Check if, for this rule, the feature is opened for time "date"
 *
 * @param date           the time to check
 * @param checkPrevious only check for overflowing times (after midnight) or don't check for it
 * @return true if the feature is open
 */
- (BOOL) isOpenedForTime:(NSDate *) date checkPrevious:(BOOL) checkPrevious;

/**
 * Check if the previous day before "date" is part of this rule
 *
 * @param date; the time to check
 * @return true if the previous day is part of the rule
 */
- (BOOL) containsPreviousDay:(NSDate *) date;

/**
 * Check if the day of "date" is part of this rule
 *
 * @param date the time to check
 * @return true if the day is part of the rule
 */
- (BOOL) containsDay:(NSDate *) date;

/**
 * Check if the month of "date" is part of this rule
 *
 * @param date the time to check
 * @return true if the month is part of the rule
 */
- (BOOL) containsMonth:(NSDate *) date;


- (NSString *) toRuleString:(BOOL) avoidMonths;

- (NSString *) toLocalRuleString;

- (NSString *) toString;

@end

/**
 * implementation of the basic OpeningHoursRule
 * <p/>
 * This implementation only supports month, day of weeks and numeral times, or the value "off"
 */
@interface OABasicOpeningHourRule : NSObject <OAOpeningHoursRule>

/**
 * return an array representing the days of the rule
 *
 * @return the days of the rule
 */
- (NSMutableArray *) getDays;

/**
 * return an array representing the months of the rule
 *
 * @return the months of the rule
 */
- (NSMutableArray *) getMonths;

- (BOOL) appliesToPublicHolidays;
- (BOOL) appliesToSchoolHolidays;
- (void) setPublicHolidays:(BOOL) value;
- (void) setSchoolHolidays:(BOOL) value;

/**
 * set a single start time, erase all previously added start times
 *
 * @param s startTime to set
 */
- (void) setStartTime:(int) s;

/**
 * set a single end time, erase all previously added end times
 *
 * @param e endTime to set
 */
- (void) setEndTime:(int) e;

/**
 * Set single start time. If position exceeds index of last item by one
 * then new value will be added.
 * If value is between 0 and last index, then value in the position p will be overwritten
 * with new one.
 * Else exception will be thrown.
 *
 * @param s        - value
 * @param position - position to add
 */
- (void) setStartTime:(int) s position:(int) position;

/**
 * Set single end time. If position exceeds index of last item by one
 * then new value will be added.
 * If value is between 0 and last index, then value in the position p will be overwritten
 * with new one.
 * Else exception will be thrown.
 *
 * @param s        - value
 * @param position - position to add
 */
- (void) setEndTime:(int) s position:(int) position;

/**
 * get a single start time
 *
 * @return a single start time
 */
- (int) getStartTime;

/**
 * get a single start time in position
 *
 * @param position position to get value from
 * @return a single start time
 */
- (int) getStartTime:(int) position;

/**
 * get a single end time
 *
 * @return a single end time
 */
- (int) getEndTime;

/**
 * get a single end time in position
 *
 * @param position position to get value from
 * @return a single end time
 */
- (int) getEndTime:(int) position;

/**
 * get all start times as independent list
 *
 * @return all start times
 */
- (NSArray *) getStartTimes;

/**
 * get all end times as independent list
 *
 * @return all end times
 */
- (NSArray *) getEndTimes;

/**
 * Check if the weekday of time "date" is part of this rule
 *
 * @param date the time to check
 * @return true if this day is part of the rule
 */
- (BOOL) containsDay:(NSDate *) date;

/**
 * Check if the previous weekday of time "date" is part of this rule
 *
 * @param date the time to check
 * @return true if the previous day is part of the rule
 */
- (BOOL) containsPreviousDay:(NSDate *) date;

/**
 * Check if the month of "date" is part of this rule
 *
 * @param date the time to check
 * @return true if the month is part of the rule
 */
- (BOOL) containsMonth:(NSDate *) date;

/**
 * Check if this rule says the feature is open at time "date"
 *
 * @param date the time to check
 * @return false in all other cases, also if only day is wrong
 */
- (BOOL) isOpenedForTime:(NSDate *) date  checkPrevious:(BOOL) checkPrevious;

- (NSString *) toRuleString:(BOOL) avoidMonths;

- (NSString *) toLocalRuleString;

- (NSString *) toString;

- (void) appendDaysString:(NSMutableString *) builder;

- (void) appendDaysString:(NSMutableString *) builder daysNames:(NSArray *) daysNames;

/**
 * Add a time range (startTime-endTime) to this rule
 *
 * @param startTime startTime to add
 * @param endTime   endTime to add
 */
- (void) addTimeRange:(int) startTime endTime:(int) endTime;

- (int) timesSize;

- (void) deleteTimeRange:(int) position;


@end

@interface OAUnparseableRule : NSObject <OAOpeningHoursRule>

- (instancetype)initWithRuleString:(NSString *) ruleString;

- (BOOL) isOpenedForTime:(NSDate *) date  checkPrevious:(BOOL) checkPrevious;

- (BOOL) containsPreviousDay:(NSDate *) date;

- (BOOL) containsDay:(NSDate *) date;

- (BOOL) containsMonth:(NSDate *) date;

- (NSString *) toRuleString:(BOOL) avoidMonths;

- (NSString *) toLocalRuleString;

- (NSString *) toString;

@end

