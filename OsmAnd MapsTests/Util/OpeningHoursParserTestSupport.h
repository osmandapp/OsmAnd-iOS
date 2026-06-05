#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpeningHoursParserTestSupport : NSObject

- (instancetype)initWithOpeningHoursString:(NSString *)openingHoursString;
+ (void)configureLocaleIdentifier:(nullable NSString *)localeIdentifier twelveHourFormattingEnabled:(BOOL)enabled;
+ (void)configureTimeLocaleIdentifier:(nullable NSString *)timeLocaleIdentifier twelveHourFormattingEnabled:(BOOL)enabled;
+ (void)configureLocalizedNamesLocaleIdentifier:(nullable NSString *)localizedNamesLocaleIdentifier
                         timeLocaleIdentifier:(nullable NSString *)timeLocaleIdentifier
                   twelveHourFormattingEnabled:(BOOL)enabled;

- (BOOL)isOpenedAt:(NSString *)dateTimeString;
- (NSString *)infoAt:(NSString *)dateTimeString;
- (NSString *)shortInfoAt:(NSString *)dateTimeString;
- (NSString *)infoAt:(NSString *)dateTimeString sequenceIndex:(NSInteger)sequenceIndex;
- (NSString *)shortInfoAt:(NSString *)dateTimeString sequenceIndex:(NSInteger)sequenceIndex;
- (NSString *)assembledString;
- (NSString *)localizedAssembledString;

@end

NS_ASSUME_NONNULL_END
