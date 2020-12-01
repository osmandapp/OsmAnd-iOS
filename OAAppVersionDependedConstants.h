//
//  OAAppVersionDependedConstants.h
//  OsmAnd
//
//  Created by nnngrach on 28.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLatestChangesUrl @"http://osmand.net/blog/osmand-ios-3-80-released"

@interface OAAppVersionDependedConstants : NSObject

+ (NSString *) getShortAppVersion;
+ (NSString *) getShortAppVersionWithSeparator:(NSString *)separator;

@end
