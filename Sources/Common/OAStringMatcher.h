//
//  OAStringMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

/**
 * Easy matcher to be able to filter streets,buildings, etc.. using custom
 * rules
 *
 */
@protocol OAStringMatcher <NSObject>

/**
 * @param name
 * @return true if this matcher matches the <code>name</code> String
 */
- (BOOL)matches:(NSString *)name;

@end
