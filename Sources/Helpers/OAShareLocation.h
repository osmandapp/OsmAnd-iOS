//
//  OAShareLocation.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 8/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAShareLocation : NSObject

+ (void)shareLocation;
+ (void)shareLocationWithMessage:(NSString *)shareText;
+ (void)shareLocationWithActivityItems:(NSArray *)activityItems;
+ (void)shareLocationWithExcludedActivityTypes:(NSArray *)excludedActivityTypes;
+ (void)shareLocationWithMessage:(NSString *)shareText andExcludedActivityTypes:(NSArray *)excludedActivityTypes;
+ (void)shareLocationWithActivityItems:(NSArray *)activityItems andExcludedActivityTypes:(NSArray *)excludedActivityTypes;

@end
