//
//  OANameStringMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAStringMatcher.h"
#import "OACollatorStringMatcher.h"

@interface OANameStringMatcher : NSObject<OAStringMatcher>

- (instancetype)initWithLastWord:(NSString *)lastWordTrim mode:(StringMatcherMode)mode;

- (BOOL)matchesMap:(NSArray<NSString *>  *)map;

@end
