#import "OAArabicNormalizer.h"

@implementation OAArabicNormalizer

static NSRegularExpression *diacriticRegex;
static NSString *const kArabicDigits = @"٠١٢٣٤٥٦٧٨٩";
static NSString *const kDigitsReplacement = @"0123456789";
static NSString *const kKashida = @"\u0640";

+ (void)initialize {
    NSError *error = nil;
    diacriticRegex = [NSRegularExpression regularExpressionWithPattern:@"[\u064B-\u0652]"
                                                               options:0
                                                                 error:&error];
    if (error) {
        NSLog(@"Error initializing regex: %@", error.localizedDescription);
    }
}

+ (BOOL)isSpecialArabic:(NSString *)text {
    if (text == nil || text.length == 0) {
        return NO;
    }
    
    unichar firstChar = [text characterAtIndex:0];
    if ([self isArabicCharacter:firstChar]) {
        for (NSUInteger i = 0; i < text.length; i++) {
            unichar c = [text characterAtIndex:i];
            if ([self isDiacritic:c] || [self isArabicDigit:c] || [self isKashida:c]) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSString *)normalize:(NSString *)text {
    if (text == nil || text.length == 0) {
        return text;
    }
    
    // Remove diacritics
    NSMutableString *result = [NSMutableString stringWithString:text];
    result = [[diacriticRegex stringByReplacingMatchesInString:result
                                                       options:0
                                                         range:NSMakeRange(0, result.length)
                                                  withTemplate:@""] mutableCopy];
    
    // Remove Kashida
    [result replaceOccurrencesOfString:kKashida
                            withString:@""
                               options:0
                                 range:NSMakeRange(0, result.length)];
    
    return [self replaceDigits:result];
}

+ (NSString *)replaceDigits:(NSString *)text {
    if (text == nil || text.length == 0) {
        return nil;
    }
    
    unichar firstChar = [text characterAtIndex:0];
    if (![self isArabicCharacter:firstChar]) {
        return text;
    }
    
    NSMutableString *mutableText = [text mutableCopy];
    for (NSUInteger i = 0; i < kArabicDigits.length; i++) {
        unichar arabicDigit = [kArabicDigits characterAtIndex:i];
        NSString *replacement = [NSString stringWithFormat:@"%c", [kDigitsReplacement characterAtIndex:i]];
        NSString *arabicDigitStr = [NSString stringWithFormat:@"%C", arabicDigit];
        
        [mutableText replaceOccurrencesOfString:arabicDigitStr
                                     withString:replacement
                                        options:0
                                          range:NSMakeRange(0, mutableText.length)];
    }
    
    return mutableText;
}

+ (BOOL)isDiacritic:(unichar)c {
    return (c >= 0x064B && c <= 0x0652);
}

+ (BOOL)isArabicDigit:(unichar)c {
    return (c >= 0x0660 && c <= 0x0669);
}

+ (BOOL)isKashida:(unichar)c {
    return (c == 0x0640);
}

+ (BOOL)isArabicCharacter:(unichar)c {
    return (c >= 0x0600 && c <= 0x06FF);
}

@end
