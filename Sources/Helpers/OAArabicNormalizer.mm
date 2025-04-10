#import "OAArabicNormalizer.h"

@implementation OAArabicNormalizer

static NSString *const kArabicDigits = @"٠١٢٣٤٥٦٧٨٩";
static NSString *const kDigitsReplacement = @"0123456789";
static NSArray *DIACRITIC_REGEX;
static NSDictionary *DIACRITIC_REPLACE;

+ (void)initialize {
    DIACRITIC_REGEX = @[
                @"[\u064B-\u065F]",
                @"[\u0610-\u061A]",
                @"[\u06D6-\u06ED]",
                @"\u0640",
                @"\u0670"
    ];
    
    DIACRITIC_REPLACE = @{
                @"\u0624": @"\u0648", // Replace Waw Hamza Above by Waw
                @"\u0629": @"\u0647", // Replace Ta Marbuta by Ha
                @"\u064A": @"\u0649", // Replace Ya by Alif Maksura
                @"\u0626": @"\u0649", // Replace Ya Hamza Above by Alif Maksura
                @"\u0622": @"\u0627", // Replace Alifs with Hamza Above
                @"\u0623": @"\u0627", // Replace Alifs with Hamza Below
                @"\u0625": @"\u0627"  // Replace with Madda Above by Alif
    };
}

+ (BOOL)isSpecialArabic:(NSString *)text {
    if (text == nil || text.length == 0) {
        return NO;
    }
    
    unichar firstChar = [text characterAtIndex:0];
    if ([self isArabicCharacter:firstChar]) {
        for (NSUInteger i = 0; i < text.length; i++) {
            unichar c = [text characterAtIndex:i];
            if ([self isDiacritic:c] || [self isArabicDigit:c] || [self isNeedReplace:c]) {
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
    NSString *result = text;
    for (NSString *regex in DIACRITIC_REGEX) {
        NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:nil];
        result = [regExp stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@""];
    }
        
    // Replace characters
    for (NSString *key in DIACRITIC_REPLACE) {
        result = [result stringByReplacingOccurrencesOfString:key withString:DIACRITIC_REPLACE[key]];
    }
        
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
    return (c >= 0x064B && c <= 0x065F) ||
            (c >= 0x0610 && c <= 0x061A) ||
            (c >= 0x06D6 && c <= 0x06ED) ||
            c == 0x0640 || c == 0x0670;
}

+ (BOOL)isArabicDigit:(unichar)c {
    return (c >= 0x0660 && c <= 0x0669);
}

+ (BOOL)isArabicCharacter:(unichar)c {
    return (c >= 0x0600 && c <= 0x06FF);
}

+ (BOOL)isNeedReplace:(unichar)c {
    NSString *charAsString = [NSString stringWithCharacters:&c length:1];
    return DIACRITIC_REPLACE[charAsString] != nil;
}

@end
