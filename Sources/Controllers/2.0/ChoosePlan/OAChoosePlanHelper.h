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

+ (void) showChoosePlanScreen:(OAProduct *)product navController:(UINavigationController *)navController;

@end

NS_ASSUME_NONNULL_END
