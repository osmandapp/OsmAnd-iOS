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

    static const unichar apostrophes[] = {
        0x0027, // '
        0x2019, // ’
        0x02BC, // ʼ
        0x00B4, // ´
        0x0060, // `
        0x2032, // ′
        0x2035, // ‵
        0x02B9  // ʹ
    };
    const int count = sizeof(apostrophes) / sizeof(unichar);

    NSMutableString *result = [NSMutableString stringWithCapacity:s.length];

    for (NSUInteger i = 0; i < s.length; i++)
    {
        unichar c = [s characterAtIndex:i];
        BOOL isApostroph = NO;

        for (int j = 0; j < count; j++)
        {
            if (c == apostrophes[j])
            {
                isApostroph = YES;
                break;
            }
        }

        if (!isApostroph)
        {
            [result appendFormat:@"%C", c];
        }
    }

    return [result copy];
}

+ (NSString *)replaceGermanSS:(NSString *)fullText
{
    if (!fullText)
    {
        return nil;
    }
    return [fullText stringByReplacingOccurrencesOfString:@"ß" withString:@"ss"];
}

+ (NSString *)canonicalizePunctuation:(NSString *)s
{
    if (!s || s.length == 0)
    {
        return s;
    }

    static const unichar keys[]   = {0x2019, 0x02BC, 0x0028, 0x0029, 0x00B4, 0x0060, 0x2032, 0x2035, 0x02B9};
    static const unichar values[] = {0x0027, 0x0027, 0x0020, 0x0020, 0x0027, 0x0027, 0x0027, 0x0027, 0x0027};
    const int size = sizeof(keys) / sizeof(unichar);

    BOOL needNormalization = NO;
    for (int i = 0; i < size; i++)
    {
        NSString *searchChar = [NSString stringWithCharacters:&keys[i] length:1];
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
        NSString *target = [NSString stringWithCharacters:&keys[i] length:1];
        NSString *replacement = [NSString stringWithCharacters:&values[i] length:1];

        [result replaceOccurrencesOfString:target withString:replacement options:NSLiteralSearch range:NSMakeRange(0, result.length)];
    }

    return [result copy];
}

@end
