//
//  OAChoosePlanHelper.h
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAProduct;

@interface OAChoosePlanHelper : NSObject

+ (void) showChoosePlanScreenWithSuffix:(NSString *)productIdentifierSuffix navController:(UINavigationController *)navController;

+ (void) showChoosePlanScreenWithProduct:(OAProduct * _Nullable)product navController:(UINavigationController *)navController;
+ (void) showChoosePlanScreenWithProduct:(OAProduct * _Nullable)product navController:(UINavigationController *)navController purchasing:(BOOL)purchasing;

@end

NS_ASSUME_NONNULL_END
