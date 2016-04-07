//
//  OAOpeningHoursParser.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAOpeningHoursParser.h"
#import "OAUtilities.h"

@implementation OAOpeningHoursParser
{
    OAOpeningHours *_hours;
}

static NSArray<NSString *> *daysStr;
static NSArray<NSString *> *localDaysStr;
static NSArray<NSString *> *monthsStr;
static NSArray<NSString *> *localMothsStr;

/**
 * Default values for sunrise and sunset. Might be computed afterwards, not final.
 */
static NSString *sunrise = @"07:00";
static NSString *sunset = @"21:00";

/**
 * Hour of when you would expect a day to be ended.
 * This is to be used when no end hour is known (like pubs that open at a certain time,
 * but close at a variable time, depending on the number of clients).
 * OsmAnd needs to show a value, so there is some arbitrary default value chosen.
 */
static NSString *endOfDay = @"24:00";

+ (void)initialize
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        
        monthsStr = @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"];
        daysStr = @[@"", @"Su", @"Mo", @"Tu", @"We", @"Th", @"Fr", @"Sa"];
        
        NSCalendar *cal = [NSCalendar currentCalendar];
        localMothsStr = [cal shortMonthSymbols];
        localDaysStr = [OAOpeningHoursParser getTwoLettersStringArray:[cal shortWeekdaySymbols]];
        
    });
}

- (instancetype)initWithOpeningHours:(NSString *) openingHours
{
    self = [super init];
    if (self)
    {
        _openingHours = [openingHours copy];
        _hours = [OAOpeningHoursParser parseOpenedHours:_openingHours];
    }
    return self;
}

- (BOOL) isOpenedForTime:(NSDate *) time
{
    if (_hours)
    {
        return [_hours isOpenedForTime:time];
    }
    else
    {
        return NO;
    }
}

+ (NSArray *) getTwoLettersStringArray:(NSArray *) strings
{
    NSMutableArray *newStrings = [NSMutableArray arrayWithCapacity:strings.count];
    for (NSString *s in strings)
    {
        if (s)
        {
            if (s.length > 2)
            {
                [newStrings addObject:[s substringToIndex:2]];
            }
            else
            {
                [newStrings addObject:s];
            }
        }
    }
    return [[NSArray alloc] initWithArray:newStrings];
}

+ (int) getDayIndex:(int) i
{
    switch (i)
    {
        case 0: return 2;
        case 1: return 3;
        case 2: return 4;
        case 3: return 5;
        case 4: return 6;
        case 5: return 7;
        case 6: return 1;
        default: return -1;
    }
}

+ (void) formatTime:(int) h t:(int) t b:(NSMutableString *) b
{
    if (h < 10)
    {
        [b appendString:@"0"];
    }
    [b appendString:@(h).stringValue];
    [b appendString:@":"];
    if (t < 10)
    {
        [b appendString:@"0"];
    }
    [b appendString:@(t).stringValue];
}

/**
 * Parse an opening_hours string from OSM to an OpeningHours object which can be used to check
 *
 * @param r the string to parse
 * @return BasicRule if the String is successfully parsed and UnparseableRule otherwise
 */
+ (id<OAOpeningHoursRule>) parseRule:(NSString *) r
{
    // replace words "sunrise" and "sunset" by real hours
    r = [r lowercaseString];
    NSArray<NSString *> *daysStr = [NSArray arrayWithObjects:@"mo", @"tu", @"we", @"th", @"fr", @"sa", @"su", nil];
    NSArray<NSString *> *monthsStr = [NSArray arrayWithObjects:@"jan", @"feb", @"mar", @"apr", @"may", @"jun", @"jul", @"aug", @"sep", @"oct", @"nov", @"dec", nil];
    NSString *sunrise = @"07:00";
    NSString *sunset = @"21:00";
    NSString *endOfDay = @"24:00";
    
    NSString *localRuleString = [r stringByReplacingOccurrencesOfString:@"sunset" withString:sunset];
    localRuleString = [localRuleString stringByReplacingOccurrencesOfString:@"sunrise" withString:sunrise];
    localRuleString = [localRuleString stringByReplacingOccurrencesOfString:@"\\+" withString:[NSString stringWithFormat:@"-%@", endOfDay]];
    
    int startDay = -1;
    int previousDay = -1;
    int startMonth = -1;
    int previousMonth = -1;
    int k = 0; // Position in opening_hours string
    
    OABasicOpeningHourRule *basic = [[OABasicOpeningHourRule alloc] init];
    NSMutableArray *days = [basic getDays];
    NSMutableArray *months = [basic getMonths];
    // check 24/7
    if ([@"24/7" isEqualToString:localRuleString])
    {
        for (int i = 0; i < days.count; i++)
        {
            [days replaceObjectAtIndex:i withObject:@YES];
        }
        for (int i = 0; i < months.count; i++)
        {
            [months replaceObjectAtIndex:i withObject:@YES];
        }
        [basic addTimeRange:0 endTime:24 * 60];
        return basic;
    }
    
    for (; k < localRuleString.length; k++)
    {
        char ch = [localRuleString characterAtIndex:k];
        if (isdigit(ch))
        {
            // time starts
            break;
        }
        if ((k + 2 < localRuleString.length)
            && [[localRuleString substringWithRange:NSMakeRange(k, 3)] isEqualToString:@"off"])
        {
            // value "off" is found
            break;
        }
        if (isblank(ch) || ch == ',')
        {
        }
        else if (ch == '-')
        {
            if (previousDay != -1)
            {
                startDay = previousDay;
            }
            else if (previousMonth != -1)
            {
                startMonth = previousMonth;
            }
            else
            {
                return [[OAUnparseableRule alloc] initWithRuleString:r];
            }
        }
        else if (k < r.length - 1)
        {
            int i = 0;
            for (NSString *s in daysStr)
            {
                if ([s characterAtIndex:0] == ch && [s characterAtIndex:1] == [r characterAtIndex:k + 1])
                {
                    break;
                }
                i++;
            }
            if (i < daysStr.count)
            {
                if (startDay != -1)
                {
                    for (int j = startDay; j <= i; j++)
                    {
                        days[j] = @YES;
                    }
                    if (startDay > i)
                    {// overflow handling, e.g. Su-We
                        for (int j = startDay; j <= 6; j++)
                        {
                            days[j] = @YES;
                        }
                        for (int j = 0; j <= i; j++)
                        {
                            days[j] = @YES;
                        }
                    }
                    startDay = -1;
                }
                else
                {
                    days[i] = @YES;
                }
                previousDay = i;
            }
            else
            {
                // Read Month
                int m = 0;
                for (NSString *s in monthsStr)
                {
                    if ([s characterAtIndex:0] == ch && [s characterAtIndex:1] == [r characterAtIndex:k + 1]
                        && [s characterAtIndex:2] == [r characterAtIndex:k + 2]) {
                        break;
                    }
                    m++;
                }
                if (m < monthsStr.count)
                {
                    if (startMonth != -1)
                    {
                        for (int j = startMonth; j <= m; j++)
                        {
                            months[j] = @YES;
                        }
                        if (startMonth > m)
                        {// overflow handling, e.g. Oct-Mar
                            for (int j = startMonth; j <= 11; j++)
                            {
                                months[j] = @YES;
                            }
                            for (int j = 0; j <= m; j++)
                            {
                                months[j] = @YES;
                            }
                        }
                        startMonth = -1;
                    }
                    else
                    {
                        months[m] = @YES;
                    }
                    previousMonth = m;
                }
                if (previousMonth == -1)
                {
                    if (ch == 'p' && [r characterAtIndex:k + 1] == 'h')
                    {
                        [basic setPublicHolidays:YES];
                    }
                    if (ch == 's' && [r characterAtIndex:k + 1] == 'h')
                    {
                        [basic setSchoolHolidays:YES];
                    }
                }
            }
        }
        else
        {
            return [[OAUnparseableRule alloc] initWithRuleString:r];
        }
    }
    if (previousDay == -1 && ![basic appliesToPublicHolidays] && ![basic appliesToSchoolHolidays])
    {
        // no days given => take all days.
        for (int i = 0; i < 7; i++)
        {
            days[i] = @YES;
        }
    }
    if (previousMonth == -1)
    {
        // no month given => take all months.
        for (int i = 0; i < 12; i++) {
            months[i] = @YES;
        }
    }
    NSString *timeSubstr = [localRuleString substringFromIndex:k];
    NSArray<NSString *> *times = [timeSubstr componentsSeparatedByString:@","];
    BOOL timesExist = YES;
    for (int i = 0; i < times.count; i++)
    {
        NSString *time = times[i];
        time = [time stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (time.length == 0)
        {
            continue;
        }
        if ([time isEqualToString:@"off"])
        {
            break; // add no time values
        }
        if ([time isEqualToString:@"24/7"])
        {
            // for some reason, this is used. See tagwatch.
            [basic addTimeRange:0 endTime:24 * 60];
            break;
        }
        NSArray<NSString *> *stEnd = [time componentsSeparatedByString:@"-"];
        if (stEnd.count != 2)
        {
            if (i == times.count - 1 && [basic getStartTime] == 0 && [basic getEndTime] == 0)
            {
                return [[OAUnparseableRule alloc] initWithRuleString:r];
            }
            continue;
        }
        timesExist = YES;
        int st;
        int end;
        @try
        {
            int i1 = [stEnd[0] indexOf:@":"];
            int i2 = [stEnd[1] indexOf:@":"];
            int startHour, startMin, endHour, endMin;
            if (i1 == -1)
            {
                // if no minutes are given, try complete value as hour
                startHour = [[stEnd[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] intValue];
                startMin = 0;
            }
            else
            {
                startHour = [[[stEnd[0] substringToIndex:i1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] intValue];
                startMin = [[[stEnd[0] substringFromIndex:i1 + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] intValue];
            }
            if (i2 == -1)
            {
                // if no minutes are given, try complete value as hour
                endHour = [[stEnd[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] intValue];
                endMin = 0;
            }
            else
            {
                endHour = [[[stEnd[1] substringToIndex:i2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] intValue];
                endMin = [[[stEnd[1] substringFromIndex:i2 + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] intValue];
            }
            st = startHour * 60 + startMin;
            end = endHour * 60 + endMin;
        }
        @catch (NSException *e)
        {
            return [[OAUnparseableRule alloc] initWithRuleString:r];
        }
        [basic addTimeRange:st endTime:end];
    }
    if (!timesExist)
    {
        return [[OAUnparseableRule alloc] initWithRuleString:r];
    }
    return basic;
}

/**
 * parse OSM opening_hours string to an OpeningHours object
 *
 * @param format the string to parse
 * @return null when parsing was unsuccessful
 */
+ (OAOpeningHours *) parseOpenedHours:(NSString *) format
{
    if (!format)
    {
        return nil;
    }
    
    // split the OSM string in multiple rules
    NSArray *rules = [format componentsSeparatedByString:@";"];
    // FIXME: What if the semicolon is inside a quoted string?
    OAOpeningHours *rs = [[OAOpeningHours alloc] init];
    for (NSString *r in rules)
    {
        NSString *_r = [r stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (_r.length == 0)
        {
            continue;
        }
        // check if valid
        id<OAOpeningHoursRule> r1 = [self parseRule:_r];
        BOOL rule = [r1 isKindOfClass:[OABasicOpeningHourRule class]];
        if (rule)
        {
            [rs addRule:r1];
        }
    }
    return rs;
}

/**
 * parse OSM opening_hours string to an OpeningHours object.
 * Does not return null when parsing unsuccessful. When parsing rule is unsuccessful,
 * such rule is stored as UnparseableRule.
 *
 * @param format the string to parse
 * @return the OpeningHours object
 */
+ (OAOpeningHours *) parseOpenedHoursHandleErrors:(NSString *) format
{
    if (!format)
    {
        return nil;
    }
    NSArray *rules = [format componentsSeparatedByString:@";"];
    OAOpeningHours *rs = [[OAOpeningHours alloc] init];
    for (NSString *r in rules)
    {
        NSString *_r = [r stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (_r.length == 0)
        {
            continue;
        }
        // check if valid
        [rs addRule:[OAOpeningHoursParser parseRule:r]];
    }
    return rs;
}

/**
 * test if the calculated opening hours are what you expect
 *
 * @param time     the time to test in the format "dd.MM.yyyy HH:mm"
 * @param hours    the OpeningHours object
 * @param expected the expected state
 */
+ (void) testOpened:(NSString *) time hours:(OAOpeningHours *) hours expected:(BOOL) expected
{
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"dd.MM.yyyy HH:mm"];

    NSDate *date = [f dateFromString:time];
    BOOL calculated = [hours isOpenedForTime:date];
    NSLog(@"  %@ok: Expected %@: %d = %d (rule %@)\n", ((calculated != expected) ? @"NOT " : @""), time, expected, calculated, [hours getCurrentRuleTime:date]);
    if (calculated != expected)
    {
        [NSException exceptionWithName:@"testOpened" reason:@"BUG!!!" userInfo:nil];
    }
}

+ (void) testParsedAndAssembledCorrectly:(NSString *) timeString hours:(OAOpeningHours *) hours
{
    NSString *assembledString = [hours toStringNoMonths];
    BOOL isCorrect = [[assembledString lowercaseString] isEqualToString:[timeString lowercaseString]];
    NSLog(@"  %@ok: Expected: \"%@\" got: \"%@\"\n", (!isCorrect ? @"NOT " : @""), timeString, assembledString);
    if (!isCorrect)
    {
        [NSException exceptionWithName:@"testParsedAndAssembledCorrectly" reason:@"BUG!!!" userInfo:nil];
    }
}

+ (void) runTest
{
    // Test basic case
    OAOpeningHours *hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Fr 08:30-14:40"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"09.08.2012 11:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"09.08.2012 16:00" hours:hours expected:NO];
    hours = [OAOpeningHoursParser parseOpenedHours:@"mo-fr 07:00-19:00; sa 12:00-18:00"];
    NSLog(@"%@", [hours toString]);
    
    NSString *string = @"Mo-Fr 11:30-15:00, 17:30-23:00; Sa, Su, PH 11:30-23:00";
    hours = [OAOpeningHoursParser parseOpenedHours:string];
    [OAOpeningHoursParser testParsedAndAssembledCorrectly:string hours:hours];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"7.09.2015 14:54" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"7.09.2015 15:05" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"3.04.2016 16:05" hours:hours expected:YES];
    
    // two time and date ranges
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-We, Fr 08:30-14:40,15:00-19:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"08.08.2012 14:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"08.08.2012 14:50" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"10.08.2012 15:00" hours:hours expected:YES];
    
    // test exception on general schema
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Sa 08:30-14:40; Tu 08:00 - 14:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"07.08.2012 14:20" hours:hours expected:NO];
    
    // test off value
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Sa 09:00-18:25; Th off"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"08.08.2012 12:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"09.08.2012 12:00" hours:hours expected:NO];
    
    //test 24/7
    hours = [OAOpeningHoursParser parseOpenedHours:@"24/7"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"08.08.2012 23:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"08.08.2012 12:23" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"08.08.2012 06:23" hours:hours expected:YES];
    
    // some people seem to use the following syntax:
    hours = [OAOpeningHoursParser parseOpenedHours:@"Sa-Su 24/7"];
    NSLog(@"%@", [hours toString]);
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Fr 9-19"];
    NSLog(@"%@", [hours toString]);
    hours = [OAOpeningHoursParser parseOpenedHours:@"09:00-17:00"];
    NSLog(@"%@", [hours toString]);
    hours = [OAOpeningHoursParser parseOpenedHours:@"sunrise-sunset"];
    NSLog(@"%@", [hours toString]);
    hours = [OAOpeningHoursParser parseOpenedHours:@"10:00+"];
    NSLog(@"%@", [hours toString]);
    hours = [OAOpeningHoursParser parseOpenedHours:@"Su-Th sunset-24:00, 04:00-sunrise; Fr-Sa sunset-sunrise"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"12.08.2012 04:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"12.08.2012 23:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"08.08.2012 12:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"08.08.2012 05:00" hours:hours expected:YES];
    
    // test simple day wrap
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo 20:00-02:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"05.05.2013 10:30" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.05.2013 23:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"06.05.2013 10:30" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"06.05.2013 20:30" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"06.05.2013 23:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"07.05.2013 00:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"07.05.2013 00:30" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"07.05.2013 01:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"07.05.2013 20:30" hours:hours expected:NO];
    
    // test maximum day wrap
    hours = [OAOpeningHoursParser parseOpenedHours:@"Su 10:00-10:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"05.05.2013 09:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.05.2013 10:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"05.05.2013 23:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"06.05.2013 00:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"06.05.2013 09:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"06.05.2013 10:00" hours:hours expected:NO];
    
    // test day wrap as seen on OSM
    // Incorrectly evaluated: https://wiki.openstreetmap.org/w/index.php?title=Key:opening_hours/specification#explain:additional_rule_separator
    // <normal_rule_separator> does overwrite previous definitions.
    // VICTOR: Do we have a test for incorrectly evaluated?
    hours = [OAOpeningHoursParser parseOpenedHours:@"Tu-Th 07:00-2:00; Fr 17:00-4:00; Sa 18:00-05:00; Su,Mo off"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"05.05.2013 04:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"05.05.2013 05:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.05.2013 12:30" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"06.05.2013 10:30" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"07.05.2013 01:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"07.05.2013 20:25" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"07.05.2013 23:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"08.05.2013 00:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"08.05.2013 02:00" hours:hours expected:NO];
    
    // test day wrap as seen on OSM
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Th 09:00-03:00; Fr-Sa 09:00-04:00; Su off"];
    [OAOpeningHoursParser testOpened:@"11.05.2015 08:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"11.05.2015 09:01" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"12.05.2015 02:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"12.05.2015 03:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"16.05.2015 03:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"16.05.2015 04:01" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"17.05.2015 01:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"17.05.2015 04:01" hours:hours expected:NO];
    
    hours = [OAOpeningHoursParser parseOpenedHours:@"Tu-Th 07:00-2:00; Fr 17:00-4:00; Sa 18:00-05:00; Su,Mo off"];
    [OAOpeningHoursParser testOpened:@"11.05.2015 08:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"11.05.2015 09:01" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"12.05.2015 02:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"12.05.2015 03:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"16.05.2015 03:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"16.05.2015 04:01" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"17.05.2015 01:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"17.05.2015 05:01" hours:hours expected:NO];
    
    // tests single month value
    hours = [OAOpeningHoursParser parseOpenedHours:@"May: 07:00-19:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"05.05.2013 12:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"05.05.2013 05:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.05.2013 21:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.01.2013 12:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.01.2013 05:00" hours:hours expected:NO];
    
    // tests multi month value
    hours = [OAOpeningHoursParser parseOpenedHours:@"Apr-Sep: 8:00-22:00; Oct-Mar: 10:00-18:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"05.03.2013 15:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"05.03.2013 20:00" hours:hours expected:NO];
    
    [OAOpeningHoursParser testOpened:@"05.05.2013 20:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"05.05.2013 23:00" hours:hours expected:NO];
    
    [OAOpeningHoursParser testOpened:@"05.10.2013 15:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"05.10.2013 20:00" hours:hours expected:NO];
    
    // Test time with breaks
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Fr: 9:00-13:00, 14:00-18:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"02.12.2015 12:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"02.12.2015 13:30" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"02.12.2015 16:00" hours:hours expected:YES];
    
    [OAOpeningHoursParser testOpened:@"05.12.2015 16:00" hours:hours expected:NO];
    
    // Test holidays
    NSString *hoursString = @"mo-fr 11:00-21:00; PH off";
    hours = [OAOpeningHoursParser parseOpenedHoursHandleErrors:hoursString];
    [OAOpeningHoursParser testParsedAndAssembledCorrectly:hoursString hours:hours];

    NSLog(@"Test finished");
}

@end

/**
 * This class contains the entire OpeningHours schema and
 * offers methods to check directly weather something is open
 *
 * @author sander
 */
@implementation OAOpeningHours
{
    /**
     * list of the different rules
     */
    NSMutableArray *_rules;
}
/**
 * Constructor
 *
 * @param rules List of OpeningHoursRule to be given
 */

- (instancetype)initWithRules:(NSArray *) rules
{
    self = [super init];
    if (self) {
        _rules = [NSMutableArray arrayWithArray:rules];
    }
    return self;
}

/**
 * Empty constructor
 */

- (instancetype)init
{
    self = [super init];
    if (self) {
        _rules = [NSMutableArray array];
    }
    return self;
}

/**
 * add a rule to the opening hours
 *
 * @param r rule to add
 */
- (void) addRule:(id<OAOpeningHoursRule>) r
{
    [_rules addObject:r];
}

/**
 * return the list of rules
 *
 * @return the rules
 */
- (NSArray *) getRules
{
    return _rules;
}

/**
 * check if the feature is opened at time "date"
 *
 * @param date the time to check
 * @return YES if feature is open
 */
- (BOOL) isOpenedForTime:(NSDate *) date
{
    /*
     * first check for rules that contain the current day
     * afterwards check for rules that contain the previous
     * day with overlapping times (times after midnight)
     */
    BOOL isOpenDay = NO;
    for (id<OAOpeningHoursRule> r in _rules) {
        if ([r containsDay:date] && [r containsMonth:date]) {
            isOpenDay = [r isOpenedForTime:date checkPrevious:NO];
        }
    }
    BOOL isOpenPrevious = NO;
    for (id<OAOpeningHoursRule> r  in _rules) {
        if ([r containsPreviousDay:date] && [r containsMonth:date]) {
            isOpenPrevious = [r isOpenedForTime:date checkPrevious:YES];
        }
    }
    return isOpenDay || isOpenPrevious;
}

- (NSString *) getCurrentRuleTime:(NSDate *) date
{
    NSString *ruleOpen = nil;
    NSString *ruleClosed = nil;
    for (id<OAOpeningHoursRule> r in _rules) {
        if ([r containsPreviousDay:date] && [r containsMonth:date]) {
            if ([r isOpenedForTime:date checkPrevious:YES]) {
                ruleOpen = [r toRuleString:YES];
            } else {
                ruleClosed = [r toRuleString:YES];
            }
        }
    }
    for (id<OAOpeningHoursRule> r in _rules) {
        if ([r containsDay:date] && [r containsMonth:date]) {
            if ([r isOpenedForTime:date checkPrevious:NO]) {
                ruleOpen = [r toRuleString:YES];
            } else {
                ruleClosed = [r toRuleString:YES];
            }
        }
    }
    
    if (ruleOpen != nil) {
        return ruleOpen;
    }
    return ruleClosed;
}

- (NSString *) toString
{
    NSMutableString *s = [NSMutableString string];
    
    if (_rules.count == 0) {
        return @"";
    }
    
    for (id<OAOpeningHoursRule> r in _rules) {
        [s appendString:[r toString]];
        [s appendString:@"; "];
    }
    
    return [s substringToIndex:s.length - 2];
}

- (NSString *) toStringNoMonths
{
    NSMutableString *s = [NSMutableString string];
    if (_rules.count == 0) {
        return @"";
    }
    
    for (id<OAOpeningHoursRule> r in _rules) {
        [s appendString:[r toRuleString:YES]];
        [s appendString:@"; "];
    }
    
    return [s substringToIndex:s.length - 2];
}

- (NSString *) toLocalStringNoMonths
{
    NSMutableString *s = [NSMutableString string];
    if (_rules.count == 0) {
        return @"";
    }
    
    for (id<OAOpeningHoursRule> r in _rules) {
        [s appendString:[r toLocalRuleString]];
        [s appendString:@"; "];
    }
    
    return [s substringToIndex:s.length - 2];
}


@end


/**
 * implementation of the basic OpeningHoursRule
 * <p/>
 * This implementation only supports month, day of weeks and numeral times, or the value "off"
 */
@implementation OABasicOpeningHourRule
{
    /**
     * represents the list on which days it is open.
     * Day number 0 is MONDAY
     */
    NSMutableArray *_days;
    
    /**
     * represents the list on which month it is open.
     * Day number 0 is JANUARY.
     */
    NSMutableArray *_months;
    
    /**
     * lists of equal size representing the start and end times
     */
    NSMutableArray *_startTimes;
    NSMutableArray *_endTimes;
    
    /**
     * Public holiday flag
     */
    BOOL _publicHoliday;
    
    /**
     * School holiday flag
     */
    BOOL _schoolHoliday;

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _days = [NSMutableArray arrayWithCapacity:7];
        for (int i = 0; i < 7; i++)
        {
            _days[i] = @0;
        }
        _months = [NSMutableArray arrayWithCapacity:12];
        for (int i = 0; i < 12; i++)
        {
            _months[i] = @0;
        }
        
        _startTimes = [NSMutableArray array];
        _endTimes = [NSMutableArray array];
        _publicHoliday = NO;
        _schoolHoliday = NO;
    }
    return self;
}

/**
 * return an array representing the days of the rule
 *
 * @return the days of the rule
 */
- (NSMutableArray *) getDays
{
    return _days;
}

/**
 * return an array representing the months of the rule
 *
 * @return the months of the rule
 */
- (NSMutableArray *) getMonths
{
    return _months;
}

- (BOOL) appliesToPublicHolidays
{
    return _publicHoliday;
}

- (BOOL) appliesToSchoolHolidays
{
    return _schoolHoliday;
}

- (void) setPublicHolidays:(BOOL) value
{
    _publicHoliday = value;
}

- (void) setSchoolHolidays:(BOOL) value
{
    _schoolHoliday = value;
}

- (void) setSingleValueForArrayList:(NSMutableArray *) arrayList s:(int) s
{
    if (arrayList.count > 0)
    {
        [arrayList removeAllObjects];
    }
    [arrayList addObject:@(s)];
}

/**
 * set a single start time, erase all previously added start times
 *
 * @param s startTime to set
 */
- (void) setStartTime:(int) s
{
    [self setSingleValueForArrayList:_startTimes s:s];
    if (_endTimes.count != 1)
    {
        [self setSingleValueForArrayList:_endTimes s:0];
    }
}

/**
 * set a single end time, erase all previously added end times
 *
 * @param e endTime to set
 */
- (void) setEndTime:(int) e
{
    [self setSingleValueForArrayList:_endTimes s:e];
    if (_startTimes.count != 1)
    {
        [self setSingleValueForArrayList:_startTimes s:0];
    }
}

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
- (void) setStartTime:(int) s position:(int) position
{
    if (position == _startTimes.count)
    {
        [_startTimes addObject:@(s)];
        [_endTimes addObject:@0];
    }
    else
    {
        [_startTimes replaceObjectAtIndex:position withObject:@(s)];
    }
}

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
- (void) setEndTime:(int) s position:(int) position
{
    if (position == _startTimes.count)
    {
        [_endTimes addObject:@(s)];
        [_startTimes addObject:@0];
    }
    else
    {
        [_endTimes replaceObjectAtIndex:position withObject:@(s)];
    }
}

/**
 * get a single start time
 *
 * @return a single start time
 */
- (int) getStartTime
{
    if (_startTimes.count == 0)
    {
        return 0;
    }
    return [_startTimes[0] intValue];
}

/**
 * get a single start time in position
 *
 * @param position position to get value from
 * @return a single start time
 */
- (int) getStartTime:(int) position
{
    return [_startTimes[position] intValue];
}

/**
 * get a single end time
 *
 * @return a single end time
 */
- (int) getEndTime
{
    if (_endTimes.count == 0)
    {
        return 0;
    }
    return [_endTimes[0] intValue];
}

/**
 * get a single end time in position
 *
 * @param position position to get value from
 * @return a single end time
 */
- (int) getEndTime:(int) position
{
    return [_endTimes[position] intValue];
}

/**
 * get all start times as independent list
 *
 * @return all start times
 */
- (NSArray *) getStartTimes
{
    return [NSArray arrayWithArray:_startTimes];
}

/**
 * get all end times as independent list
 *
 * @return all end times
 */
- (NSArray *) getEndTimes
{
    return [NSArray arrayWithArray:_endTimes];
}

/**
 * Check if the weekday of time "date" is part of this rule
 *
 * @param date the time to check
 * @return YES if this day is part of the rule
 */
- (BOOL) containsDay:(NSDate *) date
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date];
    int i = (int)[comps weekday];
    int d = (i + 5) % 7;
    if ([_days[d] intValue])
    {
        return YES;
    }
    return NO;
}

/**
 * Check if the previous weekday of time "date" is part of this rule
 *
 * @param date the time to check
 * @return YES if the previous day is part of the rule
 */
- (BOOL) containsPreviousDay:(NSDate *) date
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date];
    int i = (int)[comps weekday];
    int p = (i + 4) % 7;
    if ([_days[p] intValue]) {
        return YES;
    }
    return NO;
}

/**
 * Check if the month of "date" is part of this rule
 *
 * @param date the time to check
 * @return YES if the month is part of the rule
 */
- (BOOL) containsMonth:(NSDate *) date
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:date];
    int i = (int)[comps month] - 1;
    if ([_months[i] intValue]) {
        return YES;
    }
    return NO;
}

/**
 * Check if this rule says the feature is open at time "date"
 *
 * @param date the time to check
 * @return NO in all other cases, also if only day is wrong
 */
- (BOOL) isOpenedForTime:(NSDate *) date  checkPrevious:(BOOL) checkPrevious
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
    int i = (int)[comps weekday];
    int d = (i + 5) % 7;
    int p = d - 1;
    if (p < 0)
    {
        p += 7;
    }
    int time = (int)([comps hour] * 60 + [comps minute]); // Time in minutes
    for (i = 0; i < _startTimes.count; i++)
    {
        int startTime = [_startTimes[i] intValue];
        int endTime = [_endTimes[i] intValue];
        if (startTime < endTime || endTime == -1)
        {
            // one day working like 10:00-20:00 (not 20:00-04:00)
            if ([_days[d] intValue] && !checkPrevious)
            {
                if (time >= startTime && (endTime == -1 || time <= endTime))
                {
                    return YES;
                }
            }
        }
        else
        {
            // opening_hours includes day wrap like
            // "We 20:00-03:00" or "We 07:00-07:00"
            if (time >= startTime && [_days[d] intValue] && !checkPrevious)
            {
                return YES;
            }
            else if (time < endTime && [_days[p] intValue] && checkPrevious)
            {
                // check in previous day
                return YES;
            }
        }
    }
    return NO;
}


- (NSString *) toRuleString:(BOOL) avoidMonths
{
    return [self toRuleString:avoidMonths dayNames:daysStr monthNames:monthsStr];
}

- (NSString *) toRuleString:(BOOL) avoidMonths dayNames:(NSArray *) dayNames monthNames:(NSArray *) monthNames
{
    NSMutableString *b = [NSMutableString stringWithCapacity:25];
    // Month
    BOOL dash = NO;
    BOOL first = YES;
    if (!avoidMonths)
    {
        for (int i = 0; i < 12; i++) {
            if ([_months[i] intValue]) {
                if (i > 0 && [_months[i - 1] intValue] && i < 11 && [_months[i + 1] intValue])
                {
                    if (!dash)
                    {
                        dash = YES;
                        [b appendString:@"-"];
                    }
                    continue;
                }
                if (first)
                {
                    first = NO;
                }
                else if (!dash)
                {
                   [b appendString:@", " ];
                }
                [b appendString:monthNames[i]];
                dash = NO;
            }
        }
        if (b.length != 0) {
            [b appendString:@": "];
        }
    }
    // Day
    BOOL open24_7 = YES;
    for (int i = 0; i < 7; i++)
    {
        if (![_days[i] intValue])
        {
            open24_7 = NO;
            break;
        }
    }
    [self appendDaysString:b daysNames:dayNames];
    // Time
    if (_startTimes.count == 0)
    {
        [b appendString:@" off "];
    }
    else
    {
        for (int i = 0; i < _startTimes.count; i++)
        {
            int startTime = [_startTimes[i] intValue];
            int endTime = [_endTimes[i] intValue];
            if (open24_7 && startTime == 0 && endTime / 60 == 24) {
                return @"24/7";
            }
            [b appendString:@" "];
            int stHour = startTime / 60;
            int stTime = startTime - stHour * 60;
            int enHour = endTime / 60;
            int enTime = endTime - enHour * 60;
            [OAOpeningHoursParser formatTime:stHour t:stTime b:b];
            [b appendString:@"-"];
            [OAOpeningHoursParser formatTime:enHour t:enTime b:b];
            [b appendString:@","];
        }
    }
    return [b substringToIndex:b.length - 1];
}

- (NSString *) toLocalRuleString
{
    return [self toRuleString:YES dayNames:localDaysStr monthNames:localMothsStr];
}

- (NSString *) toString
{
    return [self toRuleString:NO];
}

- (void) appendDaysString:(NSMutableString *) builder
{
    [self appendDaysString:builder daysNames:daysStr];
}

- (void) appendDaysString:(NSMutableString *) builder daysNames:(NSArray *) daysNames
{
    BOOL dash = NO;
    BOOL first = YES;
    for (int i = 0; i < 7; i++)
    {
        if ([_days[i] intValue])
        {
            if (i > 0 && [_days[i - 1] intValue] && i < 6 && [_days[i + 1] intValue])
            {
                if (!dash)
                {
                    dash = YES;
                    [builder appendString:@"-"];
                }
                continue;
            }
            if (first)
            {
                first = NO;
            }
            else if (!dash)
            {
                [builder appendString:@", "];
            }
            [builder appendString:daysNames[[OAOpeningHoursParser getDayIndex:i]]];
            dash = NO;
        }
    }
    if (_publicHoliday) {
        if (!first) {
            [builder appendString:@", "];
        }
        [builder appendString:@"PH"];
        first = NO;
    }
    if (_schoolHoliday) {
        if (!first) {
            [builder appendString:@", "];
        }
        [builder appendString:@"SH"];
        first = NO;
    }
}

/**
 * Add a time range (startTime-endTime) to this rule
 *
 * @param startTime startTime to add
 * @param endTime   endTime to add
 */
- (void) addTimeRange:(int) startTime endTime:(int) endTime
{
    [_startTimes addObject:@(startTime)];
    [_endTimes addObject:@(endTime)];
}

- (int) timesSize
{
    return (int)_startTimes.count;
}

- (void) deleteTimeRange:(int) position
{
    [_startTimes removeObjectAtIndex:position];
    [_endTimes removeObjectAtIndex:position];
}
             

@end


@implementation OAUnparseableRule
{
    NSString *_ruleString;
}

- (instancetype)initWithRuleString:(NSString *) ruleString
{
    self = [super init];
    if (self) {
        _ruleString = ruleString;
    }
    return self;
}

- (BOOL) isOpenedForTime:(NSDate *) date  checkPrevious:(BOOL) checkPrevious
{
    return NO;
}

- (BOOL) containsPreviousDay:(NSDate *) date
{
    return NO;
}

- (BOOL) containsDay:(NSDate *) date
{
    return NO;
}

- (BOOL) containsMonth:(NSDate *) date
{
    return NO;
}

- (NSString *) toRuleString:(BOOL) avoidMonths
{
    return _ruleString;
}

- (NSString *) toLocalRuleString
{
    return [self toRuleString:NO];
}

- (NSString *) toString
{
    return [self toRuleString:NO];
}

@end
