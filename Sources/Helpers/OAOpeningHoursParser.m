//
//  OAOpeningHoursParser.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAOpeningHoursParser.h"
#import "OAUtilities.h"

typedef NS_ENUM(NSInteger, EOATokenType)
{
    TOKEN_NULL = -1,
    TOKEN_UNKNOWN = 0,
    TOKEN_COLON,
    TOKEN_COMMA,
    TOKEN_DASH,
    // order is important
    TOKEN_MONTH,
    TOKEN_DAY_MONTH,
    TOKEN_HOLIDAY,
    TOKEN_DAY_WEEK,
    TOKEN_HOUR_MINUTES,
    TOKEN_OFF_ON
};

@interface OAToken : NSObject

@property (nonatomic) int mainNumber;
@property (nonatomic) EOATokenType type;
@property (nonatomic) NSString *text;

- (instancetype) initWithTokenType:(EOATokenType)tokenType string:(NSString *)string;
+ (instancetype) nullToken;
- (NSString *) toString;
+ (int) getTypeOrd:(EOATokenType)type;

@end

@implementation OAToken

static OAToken *_nullToken = nil;

- (instancetype) initWithTokenType:(EOATokenType)tokenType string:(NSString *)string
{
    self = [super init];
    if (self)
    {
        _type = tokenType;
        _text = string;
        _mainNumber = -1;

        if (string)
        {
            NSInteger integer = NSNotFound;
            if ([[NSScanner scannerWithString:string] scanInteger:&integer] && integer != NSNotFound)
                _mainNumber = (int)integer;
        }
    }
    return self;
}

+ (instancetype) nullToken
{
    if (!_nullToken)
        _nullToken = [[OAToken alloc] initWithTokenType:TOKEN_NULL string:nil];
    return _nullToken;
}

- (NSString *) toString
{
    return [NSString stringWithFormat:@"%@ [%d] ", _text, (int)_type];
}

+ (int) getTypeOrd:(EOATokenType)type
{
    switch (type)
    {
        case TOKEN_UNKNOWN:
            return 0;
        case TOKEN_COLON:
            return 1;
        case TOKEN_COMMA:
            return 2;
        case TOKEN_DASH:
            return 3;
        case TOKEN_MONTH:
            return 4;
        case TOKEN_DAY_MONTH:
            return 5;
        case TOKEN_HOLIDAY:
            return 6;
        case TOKEN_DAY_WEEK:
            return 6;
        case TOKEN_HOUR_MINUTES:
            return 7;
        case TOKEN_OFF_ON:
            return 8;
            
        default:
            break;
    }
    return -1;
}

@end


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
    [newStrings addObject:@""];
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

+ (id<OAOpeningHoursRule>) parseRuleV2:(NSString *) r
{
    r = [r lowercaseString];
    
    NSArray<NSString *> *daysStr = [NSArray arrayWithObjects:@"mo", @"tu", @"we", @"th", @"fr", @"sa", @"su", nil];
    NSArray<NSString *> *monthsStr = [NSArray arrayWithObjects:@"jan", @"feb", @"mar", @"apr", @"may", @"jun", @"jul", @"aug", @"sep", @"oct", @"nov", @"dec", nil];
    NSArray<NSString *> *holidayStr = [NSArray arrayWithObjects:@"ph", @"sh", @"easter", nil];
    NSString *sunrise = @"07:00";
    NSString *sunset = @"21:00";
    NSString *endOfDay = @"24:00";
    r = [r stringByReplacingOccurrencesOfString:@"(" withString:@" "]; // avoid "(mo-su 17:00-20:00"
    r = [r stringByReplacingOccurrencesOfString:@")" withString:@" "];
    NSString *localRuleString = [r stringByReplacingOccurrencesOfString:@"sunset" withString:sunset];
    localRuleString = [localRuleString stringByReplacingOccurrencesOfString:@"sunrise" withString:sunrise];
    localRuleString = [localRuleString stringByReplacingOccurrencesOfString:@"\\+" withString:[NSString stringWithFormat:@"-%@", endOfDay]];
    
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
    NSMutableArray<OAToken *> *tokens = [NSMutableArray array];
    int startWord = 0;
    for (int i = 0; i <= localRuleString.length; i++)
    {
        char ch = i == localRuleString.length ? ' ' : [localRuleString characterAtIndex:i];
        BOOL delimiter = false;
        OAToken *del = nil;
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch]) {
            delimiter = true;
        } else if (ch == ':') {
            del = [[OAToken alloc] initWithTokenType:TOKEN_COLON string:@":"];
        } else if (ch == '-') {
            del = [[OAToken alloc] initWithTokenType:TOKEN_DASH string:@"-"];
        } else if (ch == ',') {
            del = [[OAToken alloc] initWithTokenType:TOKEN_COMMA string:@","];
        }
        if (delimiter || del)
        {
            NSString *wrd = [[localRuleString substringWithRange:NSMakeRange(startWord, i - startWord)] trim];
            if (wrd.length > 0)
                [tokens addObject:[[OAToken alloc] initWithTokenType:TOKEN_UNKNOWN string:wrd]];
            
            startWord = i + 1;
            if (del)
                [tokens addObject:del];
        }
    }
    // recognize day of week
    for (OAToken *t in tokens)
    {
        if (t.type == TOKEN_UNKNOWN)
            [self.class findInArray:t list:daysStr tokenType:TOKEN_DAY_WEEK];
        
        if (t.type == TOKEN_UNKNOWN)
            [self.class findInArray:t list:monthsStr tokenType:TOKEN_MONTH];
        
        if (t.type == TOKEN_UNKNOWN)
            [self.class findInArray:t list:holidayStr tokenType:TOKEN_HOLIDAY];
        
        if (t.type == TOKEN_UNKNOWN && ([@"off" isEqualToString:t.text] || [@"closed" isEqualToString:t.text]))
        {
            t.type = TOKEN_OFF_ON;
            t.mainNumber = 0;
        }
        if (t.type == TOKEN_UNKNOWN && ([@"24/7" isEqualToString:t.text] || [@"open" isEqualToString:t.text]))
        {
            t.type = TOKEN_OFF_ON;
            t.mainNumber = 1;
        }
    }
    // recognize hours minutes ( Dec 25: 08:30-20:00)
    for (int i = (int)tokens.count - 1; i >= 0; i--)
    {
        if (tokens[i].type == TOKEN_COLON)
        {
            if (i > 0 && i < tokens.count - 1)
            {
                if (tokens[i - 1].type == TOKEN_UNKNOWN && tokens[i - 1].mainNumber != -1 &&
                   tokens[i + 1].type == TOKEN_UNKNOWN && tokens[i + 1].mainNumber != -1)
                {
                    tokens[i].mainNumber = 60 * tokens[i - 1].mainNumber + tokens[i + 1].mainNumber;
                    tokens[i].type = TOKEN_HOUR_MINUTES;
                    [tokens removeObjectAtIndex:(i + 1)];
                    [tokens removeObjectAtIndex:(i - 1)];
                }
            }
        }
    }
    // recognize other numbers
    // if there is no on/off and minutes/hours
    BOOL hoursSpecified = false;
    for (int i = 0; i < tokens.count; i ++)
    {
        if (tokens[i].type == TOKEN_HOUR_MINUTES ||
           tokens[i].type == TOKEN_OFF_ON)
        {
            hoursSpecified = true;
            break;
        }
    }
    for (int i = 0; i < tokens.count; i ++)
    {
        if (tokens[i].type == TOKEN_UNKNOWN && tokens[i].mainNumber >= 0)
        {
            tokens[i].type = hoursSpecified ? TOKEN_DAY_MONTH : TOKEN_HOUR_MINUTES;
            if (tokens[i].type == TOKEN_HOUR_MINUTES)
                tokens[i].mainNumber = tokens[i].mainNumber * 60;
            else
                tokens[i].mainNumber = tokens[i].mainNumber - 1;
        }
    }
    // order MONTH MONTH_DAY DAY_WEEK HOUR_MINUTE OPEN_OFF
    EOATokenType currentParse = TOKEN_UNKNOWN;
    NSMutableArray<NSMutableArray<OAToken *> *> *listOfPairs = [NSMutableArray array];
    NSMutableSet<NSNumber *> *presentTokens = [NSMutableSet set];
    NSMutableArray<OAToken *> *currentPair = [NSMutableArray arrayWithCapacity:2];
    [listOfPairs addObject:currentPair];
    int indexP = 0;
    for (int i = 0; i <= tokens.count; i++)
    {
        OAToken *t = i == tokens.count ? nil : tokens[i];
        if (!t || [OAToken getTypeOrd:t.type] > [OAToken getTypeOrd:currentParse])
        {
            [presentTokens addObject:@(currentParse)];
            // case tokens.get(i).type.ordinal() < currentParse.ordinal() - not supported (Fr 15:00-18:00, Sa 16-18)
            if (currentParse == TOKEN_MONTH || currentParse == TOKEN_DAY_MONTH || currentParse == TOKEN_DAY_WEEK || currentParse == TOKEN_HOLIDAY)
            {
                NSMutableArray *array = (currentParse == TOKEN_MONTH) ? [basic getMonths] : (currentParse == TOKEN_DAY_MONTH) ? [basic getDayMonths] : [basic getDays];
                for (NSMutableArray<OAToken *> *pair in listOfPairs)
                {
                    if (pair.count > 1 && pair[0] != [OAToken nullToken] && pair[1] != [OAToken nullToken])
                    {
                        if (pair[0].mainNumber <= pair[1].mainNumber)
                        {
                            for (int j = pair[0].mainNumber; j <= pair[1].mainNumber && j < array.count; j++)
                            {
                                array[j] = @YES;
                            }
                        }
                        else
                        {
                            // overflow
                            for (int j = pair[0].mainNumber; j < array.count; j++)
                            {
                                array[j] = @YES;
                            }
                            for (int j = 0; j <= pair[1].mainNumber; j++)
                            {
                                array[j] = @YES;
                            }
                        }
                    }
                    else if (pair.count > 0 && pair[0] != [OAToken nullToken])
                    {
                        if (pair[0].type == TOKEN_HOLIDAY)
                        {
                            if (pair[0].mainNumber == 0) {
                                [basic setPublicHolidays:YES];
                            } else if (pair[0].mainNumber == 1) {
                                [basic setSchoolHolidays:YES];
                            } else if (pair[0].mainNumber == 2) {
                                [basic setEaster:YES];
                            }
                        }
                        else if (pair[0].mainNumber >= 0)
                        {
                            array[pair[0].mainNumber] = @YES;
                        }
                    }
                }
            }
            else if (currentParse == TOKEN_HOUR_MINUTES)
            {
                for (NSMutableArray<OAToken *> *pair in listOfPairs)
                    if (pair.count > 1 && pair[0] != [OAToken nullToken] && pair[1] != [OAToken nullToken])
                        [basic addTimeRange:pair[0].mainNumber endTime:pair[1].mainNumber];
            }
            else if (currentParse == TOKEN_OFF_ON)
            {
                NSMutableArray<OAToken *> *l = listOfPairs[0];
                if (l.count > 0 && l[0] != [OAToken nullToken] && l[0].mainNumber == 0)
                    [basic setOff:YES];
            }
            [listOfPairs removeAllObjects];
            currentPair = [NSMutableArray arrayWithCapacity:2];
            indexP = 0;
            [listOfPairs addObject:currentPair];
            currentPair[indexP++] = t ? t : [OAToken nullToken];
            if (t)
                currentParse = t.type;
        }
        else if (t.type == TOKEN_COMMA)
        {
            currentPair = [NSMutableArray arrayWithCapacity:2];
            indexP = 0;
            [listOfPairs addObject:currentPair];
        }
        else if (t.type == TOKEN_DASH)
        {
        }
        else if ([OAToken getTypeOrd:t.type] == [OAToken getTypeOrd:currentParse])
        {
            if (indexP < 2)
                currentPair[indexP++] = t ? t : [OAToken nullToken];
        }
    }
    if (![presentTokens containsObject:@(TOKEN_MONTH)])
    {
        NSMutableArray *months = [basic getMonths];
        for (int i = 0; i < months.count; i++)
            months[i] = @YES;
    }
    
    //		if(!presentTokens.contains(TokenType.TOKEN_DAY_MONTH)) {
    //			Arrays.fill(basic.getDayMonths(), true);
    //		}
    if (![presentTokens containsObject:@(TOKEN_DAY_WEEK)] && ![presentTokens containsObject:@(TOKEN_HOLIDAY)] && ![presentTokens containsObject:@(TOKEN_DAY_MONTH)])
    {
        NSMutableArray *days = [basic getDays];
        for (int i = 0; i < days.count; i++)
            days[i] = @YES;
    }
    //		if(!presentTokens.contains(TokenType.TOKEN_HOUR_MINUTES)) {
    //			basic.addTimeRange(0, 24 * 60);
    //		}
    //		System.out.println(r + " " +  tokens);
    return basic;
}

+ (void) findInArray:(OAToken *)t list:(NSArray<NSString *> *)list tokenType:(EOATokenType)tokenType
{
    for (int i = 0; i < list.count; i++)
    {
        if ([list[i] isEqualToString:t.text])
        {
            t.type = tokenType;
            t.mainNumber = i;
            break;
        }
    }
}

/**
 * Parse an opening_hours string from OSM to an OpeningHours object which can be used to check
 *
 * @param r the string to parse
 * @return BasicRule if the String is successfully parsed and UnparseableRule otherwise
 */
+ (id<OAOpeningHoursRule>) parseRule:(NSString *) r
{
    return [self.class parseRuleV2:r];
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
    [rs setOriginal:format];
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
    [rs setOriginal:format];
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
    BOOL calculated = [hours isOpenedForTimeV2:date];
    NSLog(@"  %@ok: Expected %@: %d = %d (rule %@)\n", ((calculated != expected) ? @"NOT " : @""), time, expected, calculated, [hours getCurrentRuleTime:date]);
    if (calculated != expected)
    {
        [NSException exceptionWithName:@"testOpened" reason:@"BUG!!!" userInfo:nil];
    }
}

+ (void) testParsedAndAssembledCorrectly:(NSString *) timeString hours:(OAOpeningHours *) hours
{
    NSString *assembledString = [hours toString];
    BOOL isCorrect = [[assembledString lowercaseString] isEqualToString:[timeString lowercaseString]];
    NSLog(@"  %@ok: Expected: \"%@\" got: \"%@\"\n", (!isCorrect ? @"NOT " : @""), timeString, assembledString);
    if (!isCorrect)
    {
        [NSException exceptionWithName:@"testParsedAndAssembledCorrectly" reason:@"BUG!!!" userInfo:nil];
    }
}

+ (void) runTest
{
    // 0. not supported MON DAY-MON DAY (only supported Feb 2-14 or Feb-Oct: 09:00-17:30)
    // parseOpenedHours("Feb 16-Oct 15: 09:00-18:30; Oct 16-Nov 15: 09:00-17:30; Nov 16-Feb 15: 09:00-16:30");
    
    // 1. not supported (,)
    // hours = parseOpenedHours("Mo-Su 07:00-23:00, Fr 08:00-20:00");
    
    // 2. not supported break properly
    // parseOpenedHours("Sa-Su 10:00-17:00 || \"by appointment\"");
    // comment is dropped
    
    // 3. not properly supported
    // hours = parseOpenedHours("Mo-Su (sunrise-00:30)-(sunset+00:30)");
    
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
    [OAOpeningHoursParser testOpened:@"6.09.2015 16:05" hours:hours expected:YES];
    
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
    [OAOpeningHoursParser testOpened:@"07.08.2012 08:15" hours:hours expected:YES];
    
    // test off value
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Sa 09:00-18:25; Th off"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"08.08.2012 12:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"09.08.2012 12:00" hours:hours expected:NO];
    
    // test 24/7
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
    [OAOpeningHoursParser testOpened:@"05.05.2013 04:59" hours:hours expected:YES]; // sunday 05.05.2013
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
    [OAOpeningHoursParser testOpened:@"12.05.2015 01:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"12.05.2015 02:59" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"12.05.2015 03:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"13.05.2015 01:59" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"13.05.2015 02:59" hours:hours expected:NO];
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
    hours = [OAOpeningHoursParser parseOpenedHours:@"Apr-Sep 8:00-22:00; Oct-Mar 10:00-18:00"];
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
    
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Su 07:00-23:00; Dec 25 08:00-20:00"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"25.12.2015 07:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"24.12.2015 07:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"24.12.2015 22:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"25.12.2015 08:00" hours:hours expected:YES];
    [OAOpeningHoursParser testOpened:@"25.12.2015 22:00" hours:hours expected:NO];
    
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Su 07:00-23:00; Dec 25 off"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"25.12.2015 14:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"24.12.2015 08:00" hours:hours expected:YES];
    
    // easter itself as public holiday is not supported
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Su 07:00-23:00; Easter off; Dec 25 off"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"25.12.2015 14:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"24.12.2015 08:00" hours:hours expected:YES];
    
    // test time off (not days
    hours = [OAOpeningHoursParser parseOpenedHours:@"Mo-Fr 08:30-17:00; 12:00-12:40 off;"];
    NSLog(@"%@", [hours toString]);
    [OAOpeningHoursParser testOpened:@"07.05.2017 14:00" hours:hours expected:NO]; // Sunday
    [OAOpeningHoursParser testOpened:@"06.05.2017 12:15" hours:hours expected:NO]; // Saturday
    [OAOpeningHoursParser testOpened:@"05.05.2017 14:00" hours:hours expected:YES]; // Friday
    [OAOpeningHoursParser testOpened:@"05.05.2017 12:15" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.05.2017 12:00" hours:hours expected:NO];
    [OAOpeningHoursParser testOpened:@"05.05.2017 11:45" hours:hours expected:YES];
    
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
    NSString *_original;
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
 * check if the feature is opened at time "cal"
 *
 * @param cal the time to check
 * @return true if feature is open
 */
- (BOOL) isOpenedForTimeV2:(NSDate *) date
{
    // make exception for overlapping times i.e.
    // (1) Mo 14:00-16:00; Tu off
    // (2) Mo 14:00-02:00; Tu off
    // in (2) we need to check first rule even though it is against specification
    BOOL overlap = false;
    for (NSInteger i = _rules.count - 1; i >= 0 ; i--)
    {
        id<OAOpeningHoursRule> r = _rules[i];
        if ([r hasOverlapTimes])
        {
            overlap = true;
            break;
        }
    }
    // start from the most specific rule
    for (NSInteger i = _rules.count - 1; i >= 0 ; i--)
    {
        id<OAOpeningHoursRule> r = _rules[i];
        if ([r contains:date])
        {
            BOOL open = [r isOpenedForTime:date];
            if (!open && overlap)
                continue;
            else
                return open;
        }
    }
    return false;
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
    // make exception for overlapping times i.e.
    // (1) Mo 14:00-16:00; Tu off
    // (2) Mo 14:00-02:00; Tu off
    // in (2) we need to check first rule even though it is against specification
    NSString *ruleClosed = nil;
    BOOL overlap = false;
    for (NSInteger i = _rules.count - 1; i >= 0; i--)
    {
        id<OAOpeningHoursRule> r = _rules[i];
        if ([r hasOverlapTimes])
        {
            overlap = true;
            break;
        }
    }
    // start from the most specific rule
    for (NSInteger i = _rules.count - 1; i >= 0; i--)
    {
        id<OAOpeningHoursRule> r = _rules[i];
        if ([r contains:date])
        {
            BOOL open = [r isOpenedForTime:date];
            if (!open && overlap)
                ruleClosed = [r toLocalRuleString];
            else
                return [r toLocalRuleString];
        }
    }
    return ruleClosed;
}

- (NSString *) getCurrentRuleTimeV1:(NSDate *) date
{
    NSString *ruleOpen = nil;
    NSString *ruleClosed = nil;
    for (id<OAOpeningHoursRule> r in _rules) {
        if ([r containsPreviousDay:date] && [r containsMonth:date]) {
            if ([r isOpenedForTime:date checkPrevious:YES]) {
                ruleOpen = [r toLocalRuleString];
            } else {
                ruleClosed = [r toLocalRuleString];
            }
        }
    }
    for (id<OAOpeningHoursRule> r in _rules) {
        if ([r containsDay:date] && [r containsMonth:date]) {
            if ([r isOpenedForTime:date checkPrevious:NO]) {
                ruleOpen = [r toLocalRuleString];
            } else {
                ruleClosed = [r toLocalRuleString];
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
    
    if (_rules.count == 0)
        return @"";
    
    for (id<OAOpeningHoursRule> r in _rules)
    {
        [s appendString:[r toString]];
        [s appendString:@"; "];
    }
    
    return [s substringToIndex:s.length - 2];
}

- (NSString *) toLocalString
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

- (void) setOriginal:(NSString *)original
{
    _original = original;
}

- (NSString *) getOriginal
{
    return _original;
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
     * represents the list on which day it is open.
     */
    NSMutableArray *_dayMonths;
    
    /**
     * lists of equal size representing the start and end times
     */
    NSMutableArray *_startTimes;
    NSMutableArray *_endTimes;
    
    BOOL _publicHoliday;
    BOOL _schoolHoliday;
    BOOL _easter;
    
    /**
     * Flag that means that time is off
     */
    BOOL _off;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _days = [NSMutableArray arrayWithCapacity:7];
        for (int i = 0; i < 7; i++)
            _days[i] = @NO;

        _months = [NSMutableArray arrayWithCapacity:12];
        for (int i = 0; i < 12; i++)
            _months[i] = @NO;

        _dayMonths = [NSMutableArray arrayWithCapacity:31];
        for (int i = 0; i < 31; i++)
            _dayMonths[i] = @NO;
        
        _startTimes = [NSMutableArray array];
        _endTimes = [NSMutableArray array];
        _publicHoliday = NO;
        _schoolHoliday = NO;
        _off = NO;
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

/**
 * @return the day months of the rule
 */
- (NSMutableArray *) getDayMonths
{
    return _dayMonths;
}


- (BOOL) appliesToPublicHolidays
{
    return _publicHoliday;
}

- (BOOL) appliesEaster
{
    return _easter;
}

- (BOOL) appliesToSchoolHolidays
{
    return _schoolHoliday;
}

- (void) setPublicHolidays:(BOOL) value
{
    _publicHoliday = value;
}

- (void) setEaster:(BOOL) value
{
    _easter = value;
}

- (void) setSchoolHolidays:(BOOL) value
{
    _schoolHoliday = value;
}

- (void) setOff:(BOOL) value
{
    _off = value;
}

- (void) setSingleValueForArrayList:(NSMutableArray *) arrayList s:(int) s
{
    if (arrayList.count > 0)
    {
        [arrayList removeAllObjects];
    }
    [arrayList addObject:@(s)];
}

- (BOOL) isOpenedForTime:(NSDate *)date
{
    int c = [self calculate:date];
    return c > 0;
}

- (BOOL) contains:(NSDate *)date
{
    int c = [self calculate:date];
    return c != 0;
}

- (BOOL) hasOverlapTimes
{
    for (int i = 0; i < _startTimes.count; i++)
    {
        int startTime = [_startTimes[i] intValue];
        int endTime = [_endTimes[i] intValue];
        if (startTime >= endTime && endTime != -1)
            return true;
    }
    return false;
}

- (int) calculate:(NSDate *)date
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    int month = (int)[comps month] - 1;
    if (![_months[month] intValue])
        return 0;

    int dmonth = (int)[comps day] - 1;
    int i = (int)[comps weekday];
    int day = (i + 5) % 7;
    int previous = (day + 6) % 7;
    BOOL thisDay = [_days[day] intValue] || [_dayMonths[dmonth] intValue];
    // potential error for Dec 31 12:00-01:00
    BOOL previousDay = [_days[previous] intValue] || (dmonth > 0 && [_dayMonths[dmonth - 1] intValue]);
    if (!thisDay && !previousDay)
        return 0;
    
    int time = (int)[comps hour] * 60 + (int)[comps minute]; // Time in minutes
    for (i = 0; i < _startTimes.count; i++)
    {
        int startTime = [_startTimes[i] intValue];
        int endTime = [_endTimes[i] intValue];
        if (startTime < endTime || endTime == -1)
        {
            // one day working like 10:00-20:00 (not 20:00-04:00)
            if (time >= startTime && (endTime == -1 || time <= endTime) && thisDay)
            {
                return _off ? -1 : 1;
            }
        } else {
            // opening_hours includes day wrap like
            // "We 20:00-03:00" or "We 07:00-07:00"
            if (time >= startTime && thisDay)
            {
                return _off ? -1 : 1;
            }
            else if (time < endTime && previousDay)
            {
                return _off ? -1 : 1;
            }
        }
    }
    if (thisDay && (_startTimes.count == 0 || !_off))
        return -1;
    
    return 0;
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
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
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
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
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
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:date];
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
    NSDateComponents *comps = [cal components:NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
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
                    return !_off;
                }
            }
        }
        else
        {
            // opening_hours includes day wrap like
            // "We 20:00-03:00" or "We 07:00-07:00"
            if (time >= startTime && [_days[d] intValue] && !checkPrevious)
            {
                return !_off;
            }
            else if (time < endTime && [_days[p] intValue] && checkPrevious)
            {
                // check in previous day
                return !_off;
            }
        }
    }
    return NO;
}


- (NSString *) toRuleString
{
    return [self toRuleString:daysStr monthNames:monthsStr];
}

- (NSString *) toRuleString:(NSArray *) dayNames monthNames:(NSArray *) monthNames
{
    NSMutableString *b = [NSMutableString stringWithCapacity:25];
    BOOL allMonths = true;
    for (int i = 0; i < _months.count; i++)
    {
        if (![_months[i] intValue])
        {
            allMonths = false;
            break;
        }
    }
    // Month
    if (!allMonths)
        [self addArray:_months arrayNames:monthNames b:b];
    
    BOOL allDays = true;
    for (int i = 0; i < _dayMonths.count; i++)
    {
        if (![_dayMonths[i] intValue])
        {
            allDays = false;
            break;
        }
    }
    if (!allDays)
        [self addArray:_dayMonths arrayNames:nil b:b];
    
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
        [b appendString:@"off"];
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
            if (i > 0)
                [b appendString:@", "];
            
            int stHour = startTime / 60;
            int stTime = startTime - stHour * 60;
            int enHour = endTime / 60;
            int enTime = endTime - enHour * 60;
            [OAOpeningHoursParser formatTime:stHour t:stTime b:b];
            [b appendString:@"-"];
            [OAOpeningHoursParser formatTime:enHour t:enTime b:b];
        }
        if (_off)
        {
            [b appendString:@" off"];
        }
    }
    return [NSString stringWithString:b];
}

- (void) addArray:(NSArray *)array arrayNames:(NSArray *)arrayNames b:(NSMutableString *)b
{
    BOOL dash = false;
    BOOL first = true;
    for (int i = 0; i < array.count; i++)
    {
        if ([array[i] intValue])
        {
            if (i > 0 && [array[i - 1] intValue] && i < array.count - 1 && [array[i + 1] intValue])
            {
                if (!dash)
                {
                    dash = true;
                    [b appendString:@"-"];
                }
                continue;
            }
            if (first)
            {
                first = false;
            }
            else if (!dash)
            {
                [b appendString:@", "];
            }
            [b appendString:(!arrayNames ? [NSString stringWithFormat:@"%d", (i + 1)] : arrayNames[i])];
            dash = false;
        }
    }
    if (!first)
    {
        [b appendString:@" "];
    }
}

- (NSString *) toLocalRuleString
{
    return [self toRuleString:localDaysStr monthNames:localMothsStr];
}

- (NSString *) toString
{
    return [self toRuleString];
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
    if (_publicHoliday)
    {
        if (!first)
            [builder appendString:@", "];
        
        [builder appendString:@"PH"];
        first = NO;
    }
    if (_schoolHoliday)
    {
        if (!first)
            [builder appendString:@", "];
        
        [builder appendString:@"SH"];
        first = NO;
    }
    if (_easter)
    {
        if (!first)
            [builder appendString:@", "];

        [builder appendString:@"Easter"];
        first = false;
    }
    if (!first)
        [builder appendString:@" "];
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

- (BOOL) hasOverlapTimes
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

- (NSString *) toRuleString
{
    return _ruleString;
}

- (NSString *) toLocalRuleString
{
    return [self toRuleString];
}

- (NSString *) toString
{
    return [self toRuleString];
}

- (BOOL) isOpenedForTime:(NSDate *)date
{
    return NO;
}

- (BOOL) contains:(NSDate *)date
{
    return NO;
}

@end
