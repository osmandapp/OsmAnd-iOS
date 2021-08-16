//
//  OAAbbreviations.m
//  OsmAnd Maps
//
//  Created by plotva on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAAbbreviations.h"
#import "OASearchPhrase.h"

@implementation OAAbbreviations

static NSDictionary *ABBREVIATIONS = @{ @"e" : @"East",
                                 @"w" : @"West",
                                 @"s" : @"South",
                                 @"n" : @"North",
                                 @"sw" : @"Southwest",
                                 @"se" : @"Southeast",
                                 @"nw" : @"Northwest",
                                 @"ne" : @"Northeast",
                                 @"ln" : @"Lane"
};

+ (NSString *) replace:(NSString *)word
{
    NSString *value = ABBREVIATIONS[[word lowercaseString]];
    return value ? value : word;
}

+ (NSString *) replaceAll:(NSString *)phrase
{
    NSArray<NSString *> *words = [phrase componentsSeparatedByString:[OASearchPhrase getDelimiter]];
    NSMutableString *r = [NSMutableString new];
    BOOL changed = NO;
    for (NSString *word in words)
    {
        if ([r length] > 0)
            [r appendString:[OASearchPhrase getDelimiter]];
        
        NSString *abbrRes = [ABBREVIATIONS objectForKey:[word lowercaseString]];
        if (abbrRes == nil)
        {
            [r appendString:word];
        }
        else
        {
            changed = YES;
            [r appendString:abbrRes];
        }
    }
    return changed ? [NSString stringWithString:r] : phrase;
}

@end
