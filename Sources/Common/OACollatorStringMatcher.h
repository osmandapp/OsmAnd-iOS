//
//  OACollatorStringMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAStringMatcher.h"

typedef enum
{
    CHECK_ONLY_STARTS_WITH,
    CHECK_STARTS_FROM_SPACE,
    CHECK_STARTS_FROM_SPACE_NOT_BEGINNING,
    CHECK_EQUALS_FROM_SPACE,
    CHECK_CONTAINS
    
} StringMatcherMode;

@interface OACollatorStringMatcher : NSObject<OAStringMatcher>

- (instancetype)initWithPart:(NSString *)part mode:(StringMatcherMode)mode;
- (BOOL) matches:(NSString *)name;

+ (BOOL) cmatches:(NSString *)base part:(NSString *)part mode:(StringMatcherMode)mode;
+ (BOOL) ccontains:(NSString *)base part:(NSString *)part;
+ (BOOL) cstartsWith:(NSString *)searchInParam theStart:(NSString *)theStart checkBeginning:(BOOL)checkBeginning checkSpaces:(BOOL)checkSpaces equals:(BOOL)equals;



@end
