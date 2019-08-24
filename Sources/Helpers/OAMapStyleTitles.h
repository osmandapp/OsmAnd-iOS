//
//  OAMapStyleTitles.h
//  OsmAnd
//
//  Created by Paul on 8/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapStyleTitles : NSObject

+ (NSDictionary<NSString *, NSString *> *)getMapStyleTitles;
+ (int) getSortIndexForTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
