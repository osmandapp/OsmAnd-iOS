//
//  OACollatorStringMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
//  8298dbdf17d9ece341fa7b790019c193e01698c5

#import <Foundation/Foundation.h>
#import "OAStringMatcher.h"

typedef enum
{
    // tests only first word as base starts with part
    CHECK_ONLY_STARTS_WITH,
    // tests all words (split by space) and one of word should start with a given part
    CHECK_STARTS_FROM_SPACE,
    // tests all words except first (split by space) and one of word should start with a given part
    CHECK_STARTS_FROM_SPACE_NOT_BEGINNING,
    // tests all words (split by space) and one of word should be equal to part
    CHECK_EQUALS_FROM_SPACE,
    // TO DO: make a separate method
    // trims part to make shorter then full text and tests only first word as base starts with part
    TRIM_AND_CHECK_ONLY_STARTS_WITH,
    // simple collator contains in any part of the base
    CHECK_CONTAINS,
    // simple collator equals
    CHECK_EQUALS,

} StringMatcherMode;

@interface OACollatorStringMatcher : NSObject<OAStringMatcher>

- (instancetype) initWithPart:(NSString *)part mode:(StringMatcherMode)mode;
- (BOOL) matches:(NSString *)name;

+ (BOOL) cmatches:(NSString *)fullName part:(NSString *)part mode:(StringMatcherMode)mode;
+ (BOOL) ccontains:(NSString *)fullTextP part:(NSString *)part;
+ (BOOL) cstartsWith:(NSString *)fullText theStart:(NSString *)theStart checkBeginning:(BOOL)checkBeginning checkSpaces:(BOOL)checkSpaces equals:(BOOL)equals;

- (NSInteger)compare:(NSString *)source target:(NSString *)target;


@end
