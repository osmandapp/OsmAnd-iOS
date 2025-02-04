#import <Foundation/Foundation.h>

@interface OAArabicNormalizer : NSObject

+ (BOOL)isSpecialArabic:(NSString *)text;
+ (NSString *)normalize:(NSString *)text;

@end