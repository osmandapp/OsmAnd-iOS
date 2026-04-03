#import "OpeningHoursParserTestSupport.h"
#import "OAExternalTimeFormatter.h"

#include <openingHoursParser.h>

namespace {

tm parseDateTimeString(NSString *dateTimeString) {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        formatter.dateFormat = @"dd.MM.yyyy HH:mm";
    });

    NSDate *date = [formatter dateFromString:dateTimeString];
    NSCAssert(date != nil, @"Invalid date string: %@", dateTimeString);

    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = formatter.timeZone;
    NSDateComponents *components =
        [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                              NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond |
                              NSCalendarUnitWeekday
                    fromDate:date];

    tm dateTime = {};
    dateTime.tm_year = (int)components.year - 1900;
    dateTime.tm_mon = (int)components.month - 1;
    dateTime.tm_mday = (int)components.day;
    dateTime.tm_hour = (int)components.hour;
    dateTime.tm_min = (int)components.minute;
    dateTime.tm_sec = (int)components.second;
    dateTime.tm_wday = (int)components.weekday - 1;
    return dateTime;
}

NSString *normalizeString(const std::string &value) {
    return [NSString stringWithUTF8String:value.c_str()] ?: @"";
}

} // namespace

@implementation OpeningHoursParserTestSupport {
    std::shared_ptr<OpeningHoursParser::OpeningHours> _hours;
}

+ (void)configureLocaleIdentifier:(NSString *)localeIdentifier twelveHourFormattingEnabled:(BOOL)enabled {
    [OAExternalTimeFormatter setLocale:localeIdentifier];
    OpeningHoursParser::setExternalTimeFormatterCallback([OAExternalTimeFormatter getExternalTimeFormatterCallback]);
    OpeningHoursParser::setTwelveHourFormattingEnabled(enabled);
    OpeningHoursParser::setAmpmOnLeft([OAExternalTimeFormatter isCurrentRegionWithAmpmOnLeft]);
    OpeningHoursParser::setLocalizedDaysOfWeek([OAExternalTimeFormatter getLocalizedWeekdays]);
    OpeningHoursParser::setLocalizedMonths([OAExternalTimeFormatter getLocalizedMonths]);
}

- (instancetype)initWithOpeningHoursString:(NSString *)openingHoursString {
    self = [super init];
    if (self) {
        _hours = OpeningHoursParser::parseOpenedHours([openingHoursString UTF8String]);
    }
    return self;
}

- (BOOL)isOpenedAt:(NSString *)dateTimeString {
    tm dateTime = parseDateTimeString(dateTimeString);
    return _hours->isOpenedForTimeV2(dateTime, OpeningHoursParser::OpeningHours::ALL_SEQUENCES);
}

- (NSString *)infoAt:(NSString *)dateTimeString {
    return [self infoAt:dateTimeString sequenceIndex:OpeningHoursParser::OpeningHours::ALL_SEQUENCES];
}

- (NSString *)infoAt:(NSString *)dateTimeString sequenceIndex:(NSInteger)sequenceIndex {
    tm dateTime = parseDateTimeString(dateTimeString);
    const auto info = sequenceIndex == OpeningHoursParser::OpeningHours::ALL_SEQUENCES
        ? _hours->getCombinedInfo(dateTime)
        : _hours->getInfo(dateTime)[sequenceIndex];
    return normalizeString(info->getInfo());
}

- (NSString *)assembledString {
    return normalizeString(_hours->toString());
}

- (NSString *)localizedAssembledString {
    return normalizeString(_hours->toLocalString());
}

@end
