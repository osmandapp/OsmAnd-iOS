//
//  OARoutingHelperUtils.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OARoutingHelperUtils : NSObject

+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards;

@end

NS_ASSUME_NONNULL_END
