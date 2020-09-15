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

//  NameStringMatcher.java
//  git revision 7b10a094efad6f6a05d7d55f4503a99047416806

@interface OANameStringMatcher : NSObject<OAStringMatcher>

- (instancetype) initWithNamePart:(NSString *)namePart mode:(StringMatcherMode)mode;

- (BOOL) matchesMap:(NSArray<NSString *>  *)map;

@end
