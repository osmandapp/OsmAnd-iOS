//
//  OANode.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface OANode : OAEntity <OAEntityProtocol>

-(id)initWithNode:(OANode *)node identifier:(long)identifier;

@end

NS_ASSUME_NONNULL_END
