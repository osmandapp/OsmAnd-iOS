//
//  OAAppVersion.h
//  OsmAnd
//
//  Created by nnngrach on 28.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAAppVersion : NSObject

+ (NSString *)getVersion;
+ (NSString *)getBuildVersion;
+ (float) getVersionNumber;
+ (float) getBuildVersionNumber;

+ (NSString *)getVersionWithSeparator:(NSString *)separator;
+ (NSString *)getFullVersionWithAppName;
+ (NSString *)getVersionForUrl;

@end
