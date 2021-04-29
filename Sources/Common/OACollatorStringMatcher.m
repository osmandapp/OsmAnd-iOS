//
//  OACollatorStringMatcher.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollatorStringMatcher.h"
#import "OAUtilities.h"

static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSDiacriticInsensitiveSearch;

@implementation OACollatorStringMatcher
{
    StringMatcherMode _mode;
    NSString *_part;
}


- (instancetype)initWithPart:(NSString *)part mode:(StringMatcherMode)mode
{
    self = [super init];
    if (self)
    {
        part = [self.class simplifyStringAndAlignChars:part];
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
    return [self.class cmatches:name part:_part mode:_mode];
}


+ (BOOL) cmatches:(NSString *)fullName part:(NSString *)part mode:(StringMatcherMode)mode
{
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
 * @param fullTextP
 * @param theStart
 * @param fullText
 * @return true if searchIn starts with token
 */
+ (BOOL) cstartsWith:(NSString *)fullTextP theStart:(NSString *)theStart checkBeginning:(BOOL)checkBeginning checkSpaces:(BOOL)checkSpaces equals:(BOOL)equals
{
    NSString *searchIn = [self simplifyStringAndAlignChars:fullTextP];
    NSInteger searchInLength = searchIn.length;
    
    NSInteger startLength = theStart.length;
    if (startLength == 0)
        return YES;
    // this is not correct because of Auhofstrasse != Auhofstraße
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
            if ([self.class isSpace:[searchIn characterAtIndex:i - 1]] && ![self.class isSpace:[searchIn characterAtIndex:i]])
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
                        return true;
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
    return ![[NSCharacterSet letterCharacterSet] characterIsMember:c] && ![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:c];
}

+ (NSString *) simplifyStringAndAlignChars:(NSString *)fullText
{
    int i;
    fullText = fullText.lowerCase;
    while( (i = [fullText indexOf:@"ß"] ) != -1 ) {
        fullText = [NSString stringWithFormat:@"%@ss%@", [fullText substringToIndex:i], [fullText substringFromIndex:i+1]];
    }
    return fullText;
}

- (NSInteger)compare:(NSString *)source target:(NSString *)target
{
    return [source compare: target];
}


@end
