//
//  OACollatorStringMatcher.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollatorStringMatcher.h"
#import "OAUtilities.h"
#import "OASearchAlgorithms.h"

static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSDiacriticInsensitiveSearch;
static NSCharacterSet * _APOSTROPHES;

@implementation OACollatorStringMatcher
{
    StringMatcherMode _mode;
    NSString *_part;
}

+ (void) initialize
{
    if (self == [OACollatorStringMatcher class])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *charString = @"'’ʼ´`ʹ‵′«»";
            _APOSTROPHES = [NSCharacterSet characterSetWithCharactersInString:charString];
        });
    }
}

- (instancetype)initWithPart:(NSString *)part mode:(StringMatcherMode)mode
{
    self = [super init];
    if (self)
    {
        part = [self.class lowercaseAndAlignChars:part];
        if (part.length > 0 && [part characterAtIndex:(part.length - 1)] == '.')
        {
            part = [part substringToIndex:part.length - 1];
            if (mode == CHECK_EQUALS_FROM_SPACE)
                mode = CHECK_STARTS_FROM_SPACE;
            else if (mode == CHECK_EQUALS)
                mode = CHECK_ONLY_STARTS_WITH;
        }
        _part = part;
        _mode = mode;
    }
    return self;
}

- (BOOL) matches:(NSString *)name
{
    return [self.class cmatches:name part:_part alignPart:NO mode:_mode];
}

+ (BOOL) cmatches:(NSString *)fullName part:(NSString *)part mode:(StringMatcherMode)mode
{
    return [self cmatches:fullName part:part alignPart:YES mode:mode];
}

+ (BOOL) cmatches:(NSString *)fullName part:(NSString *)part alignPart:(BOOL)alignPart  mode:(StringMatcherMode)mode
{
    if (fullName != nil && [self.class containsHyphen:fullName])
    {
        NSString *stringWithoutHyphen = [self replaceHyphen:fullName replacement:@("")];
        if ([self.class cmatches:stringWithoutHyphen part:part mode:mode])
        {
            return YES;
        }
    }
    
    if (alignPart)
    {
        part = [self.class alignChars:part];
    }
    
    fullName = [self.class lowercaseAndAlignChars:fullName];
    
    switch (mode)
    {
        case CHECK_CONTAINS:
            return [self.class ccontains:fullName part:part];
        case CHECK_EQUALS_FROM_SPACE:
            return [self.class cstartsWith:fullName theStart:part checkBeginning:YES checkSpaces:YES equals:YES];
        case CHECK_STARTS_FROM_SPACE:
            return [self.class cstartsWith:fullName theStart:part checkBeginning:YES checkSpaces:YES equals:NO];
        case CHECK_STARTS_FROM_SPACE_NOT_BEGINNING:
            return [self.class cstartsWith:fullName theStart:part checkBeginning:NO checkSpaces:YES equals:NO];
        case CHECK_ONLY_STARTS_WITH:
            return [self.class cstartsWith:fullName theStart:part checkBeginning:YES checkSpaces:NO equals:NO];
        case TRIM_AND_CHECK_ONLY_STARTS_WITH:
            if (part.length > fullName.length)
                part = [part substringWithRange:NSMakeRange(0, fullName.length)];
            return [self.class cstartsWith:fullName theStart:part checkBeginning:YES checkSpaces:NO equals:NO];
        case CHECK_EQUALS:
            return [self.class cstartsWith:fullName theStart:part checkBeginning:NO checkSpaces:NO equals:YES];
    }
    return false;
}


/**
 * Check if part contains in base
 *
 * @param part String to search
 * @param base String where to search
 * @return true if part is contained in base
 */
+ (BOOL) ccontains:(NSString *)base part:(NSString *)part
{
    if (base.length <= part.length)
        return [base compare:part options:comparisonOptions] == NSOrderedSame;
    
    NSRange range = [base rangeOfString:part options:comparisonOptions range:NSMakeRange(0, base.length) locale:[NSLocale currentLocale]];
    return (range.location != NSNotFound);
    
    /*
    for (int pos = 0; pos <= base.length - part.length + 1; pos++)
    {
        NSString *temp = [base substringFromIndex:pos];
        
        for (NSInteger length = temp.length; length >= 0; length--)
        {
            NSString *temp2 = [temp substringToIndex:length];
            if ([temp2 localizedCaseInsensitiveCompare:part] == NSOrderedSame)
                return YES;
        }
    }
    
    return NO;
    */
}

+ (int) cindexOf:(int)start part:(NSString *)part base:(NSString *)base
{
    for (int pos = start; pos <= base.length - part.length; pos++)
    {
        if ([[base substringWithRange:NSMakeRange(pos, part.length)] compare:part options:comparisonOptions] == NSOrderedSame)
            return pos;
    }
    return -1;
}

/**
 * Checks if string starts with another string.
 * Special check try to find as well in the middle of name
 *
 * Both arguments must already be lowercased and aligned (see +lowercaseAndAlignChars:);
 * +cmatches: is the only caller and does that once for both strings.
 *
 * @param fullTextP
 * @param theStart
 * @param fullText
 * @return true if searchIn starts with token
 */
+ (BOOL) cstartsWith:(NSString *)fullTextP theStart:(NSString *)theStart checkBeginning:(BOOL)checkBeginning checkSpaces:(BOOL)checkSpaces equals:(BOOL)equals
{
    // Both strings arrive normalized from +cmatches: (as in the Java original, where
    // cstartsWith() does no normalization of its own), so only hyphens are folded here.
    theStart = [self replaceHyphen:theStart replacement:@(" ")];
    NSString *searchIn = [self replaceHyphen:fullTextP replacement:@(" ")];
    NSInteger searchInLength = searchIn.length;
    
    NSInteger startLength = theStart.length;
    if (startLength == 0)
        return YES;
    // this is not correct without (lowercaseAndAlignChars) because of Auhofstrasse != Auhofstraße
    if (startLength > searchInLength)
        return NO;

    // simulate starts with for collator
    if (checkBeginning)
    {
        BOOL starts = [[searchIn substringToIndex:startLength] compare:theStart options:comparisonOptions] == NSOrderedSame;
        if (starts)
        {
            if (equals)
            {
                if (startLength == searchInLength || [self.class isSpace:[searchIn characterAtIndex:startLength]])
                {
                    return YES;
                }
            }
            else
            {
                return YES;
            }
        }
    }
    if (checkSpaces)
    {
        for (int i = 1; i <= searchInLength - startLength; i++)
        {
            if ([self isWordStart:searchIn index:i part:theStart])
            {
                if ([[searchIn substringWithRange:NSMakeRange(i, startLength)] compare:theStart options:comparisonOptions] == NSOrderedSame)
                {
                    if (equals)
                    {
                        if (i + startLength == searchInLength || [self.class isSpace:[searchIn characterAtIndex:i + startLength]])
                        {
                            return YES;
                        }
                    }
                    else
                    {
                        return YES;
                    }
                }
            }
        }
    }
    if (!checkBeginning && !checkSpaces && equals)
        return [searchIn compare:theStart options:comparisonOptions] == NSOrderedSame;
    
    return NO;
}

+ (BOOL) isSpace:(unichar) c
{
    // Called per character of every compared name: avoid re-fetching the shared
    // NSCharacterSets and short-circuit the ASCII range.
    if (c < 0x80)
        return !((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'));

    static NSCharacterSet *letters;
    static NSCharacterSet *digits;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        letters = [NSCharacterSet letterCharacterSet];
        digits = [NSCharacterSet decimalDigitCharacterSet];
    });
    return ![letters characterIsMember:c] && ![digits characterIsMember:c];
}

+ (BOOL)isWordStart:(NSString *)searchIn index:(int)index part:(NSString *)part
{
    if (![self isSpace:[searchIn characterAtIndex:index - 1]])
    {
        return NO;
    }

    unichar current = [searchIn characterAtIndex:index];
    if (![self isSpace:current])
    {
        return YES;
    }
    if (current != '-' || part.length <= 1 || [part characterAtIndex:0] != '-')
        return NO;
    const unichar second = [part characterAtIndex:1];
    if (second < 0x80)
        return second >= '0' && second <= '9';
    return [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:second];
}

+ (NSString *) lowercaseAndAlignChars:(NSString *)fullText
{
    return [self alignChars:[self lowerCaseIfNeeded:fullText]];
}

// -lowerCase resolves +[NSLocale currentLocale] and runs a locale-aware fold on every
// call. It runs on every compared name, so skip it when the text holds no character
// that lowercasing could possibly change.
+ (NSString *) lowerCaseIfNeeded:(NSString *)text
{
    const CFIndex length = text.length;
    if (length == 0) // also covers a nil string, which callers do pass
        return text;

    CFStringInlineBuffer buffer;
    CFStringInitInlineBuffer((__bridge CFStringRef) text, &buffer, CFRangeMake(0, length));
    for (CFIndex i = 0; i < length; i++)
    {
        const UniChar c = CFStringGetCharacterFromInlineBuffer(&buffer, i);
        if (c >= 0x80 || (c >= 'A' && c <= 'Z'))
            return text.lowerCase;
    }
    return text;
}

+ (BOOL) containsHyphen:(NSString *)text
{
    const CFIndex length = text.length;
    if (length == 0) // also covers a nil string, which callers do pass
        return NO;

    CFStringInlineBuffer buffer;
    CFStringInitInlineBuffer((__bridge CFStringRef) text, &buffer, CFRangeMake(0, length));
    for (CFIndex i = 0; i < length; i++)
    {
        if (CFStringGetCharacterFromInlineBuffer(&buffer, i) == '-')
            return YES;
    }
    return NO;
}

+ (NSString *) alignChars:(NSString *)fullText
{
    return [OASearchAlgorithms alignChars:fullText];
}

+ (NSString *) replaceHyphen:(NSString *)text replacement:(NSString *)replacement
{
    // Avoid allocating a copy when there is nothing to replace
    if (![self containsHyphen:text])
        return text;
    return [text stringByReplacingOccurrencesOfString:@"-" withString:replacement];
}

@end
