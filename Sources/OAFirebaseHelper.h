//
//  OAFirebaseHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/11/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAFirebaseHelper : NSObject

+ (void)logEvent:(nonnull NSString *)name;
+ (void)setUserProperty:(nullable NSString *)value forName:(nonnull NSString *)name;

@end
