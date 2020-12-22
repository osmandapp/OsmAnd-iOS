//
//  OAUnsupportedAction.h
//  OsmAnd
//
//  Created by nnngrach on 18.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAUnsupportedAction : OAQuickAction

- (instancetype) initWithJSON:(NSDictionary *)json;
+ (OAQuickActionType *) CUSTOMCTYPE:(NSString *)name stringId:(NSString *)stringId;

@end

NS_ASSUME_NONNULL_END

