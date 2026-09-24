#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpeningHoursParserTestSupport : NSObject

- (instancetype)initWithOpeningHoursString:(NSString *)openingHoursString;
+ (void)configureLocaleIdentifier:(nullable NSString *)localeIdentifier twelveHourFormattingEnabled:(BOOL)enabled;
+ (void)setAdditionalString:(NSString *)value forKey:(NSString *)key NS_SWIFT_NAME(setAdditionalString(_:forKey:));
+ (NSInteger)weekdayForDate:(NSDate *)date NS_SWIFT_NAME(weekday(for:));

- (BOOL)isOpenedAt:(NSString *)dateTimeString;
- (NSString *)infoAt:(NSString *)dateTimeString;
- (NSString *)shortInfoAt:(NSString *)dateTimeString;
- (NSString *)infoAt:(NSString *)dateTimeString sequenceIndex:(NSInteger)sequenceIndex;
- (NSString *)shortInfoAt:(NSString *)dateTimeString sequenceIndex:(NSInteger)sequenceIndex;
- (NSString *)assembledString;
- (NSString *)localizedAssembledString;

@end

NS_ASSUME_NONNULL_END
