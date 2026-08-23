//
//  OASearchAlgorithms.m
//  OsmAnd
//
//  Created by Ivan Pyrohivskyi on 15.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASearchAlgorithms.h"

@implementation OASearchAlgorithms

+ (NSString *)removeApostrophes:(NSString *)s
{
    if (!s || s.length == 0)
    {
        return s;
    }

    static NSCharacterSet *apostrophes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        apostrophes = [NSCharacterSet characterSetWithCharactersInString:@"'’ʼ´`′‵ʹ"];
    });
    if ([s rangeOfCharacterFromSet:apostrophes].location == NSNotFound)
    {
        return s;
    }

    NSMutableString *result = [s mutableCopy];
    for (NSUInteger i = result.length; i > 0; i--)
    {
        if ([apostrophes characterIsMember:[result characterAtIndex:i - 1]])
            [result deleteCharactersInRange:NSMakeRange(i - 1, 1)];
    }
    return [result copy];
}

+ (NSString *)replaceGermanSS:(NSString *)fullText
{
    if (!fullText)
    {
        return nil;
    }
    if ([fullText rangeOfString:@"ß"].location == NSNotFound)
    {
        return fullText;
    }
    return [fullText stringByReplacingOccurrencesOfString:@"ß" withString:@"ss"];
}

+ (NSString *)canonicalizePunctuation:(NSString *)s
{
    if (!s || s.length == 0)
    {
        return s;
    }

    static const unichar CHARS_TO_NORMALIZE_KEY[]   = {L'’', L'ʼ', L'(', L')', L'´', L'`', L'′', L'‵', L'ʹ'};
    static const unichar CHARS_TO_NORMALIZE_VALUE[] = {L'\'', L'\'', L' ', L' ', L'\'', L'\'', L'\'', L'\'', L'\''};
    const int size = sizeof(CHARS_TO_NORMALIZE_KEY) / sizeof(unichar);

    BOOL needNormalization = NO;
    for (int i = 0; i < size; i++)
    {
        NSString *searchChar = [NSString stringWithCharacters:&CHARS_TO_NORMALIZE_KEY[i] length:1];
        if ([s rangeOfString:searchChar].location != NSNotFound)
        {
            needNormalization = YES;
            break;
        }
    }
    if (!needNormalization)
    {
        return s;
    }
    NSMutableString *result = [s mutableCopy];
    for (int i = 0; i < size; i++)
    {
        NSString *target = [NSString stringWithCharacters:&CHARS_TO_NORMALIZE_KEY[i] length:1];
        NSString *replacement = [NSString stringWithCharacters:&CHARS_TO_NORMALIZE_VALUE[i] length:1];

        [result replaceOccurrencesOfString:target withString:replacement options:NSLiteralSearch range:NSMakeRange(0, result.length)];
    }

    return [result copy];
}

@end
