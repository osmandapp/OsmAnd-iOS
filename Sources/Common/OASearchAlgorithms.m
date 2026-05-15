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

@end
