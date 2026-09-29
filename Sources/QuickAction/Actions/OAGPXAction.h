//
//  OAGPXAction.h
//  OsmAnd
//
//  Created by Paul on 8/8/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAGPXAction : OAQuickAction

+ (NSString *)categoryFromParams:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
