//
//  OANode.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/Node.java
//  git revision f7bdb0f04af2f48a6cd7b1963d6c5cceac9383a7

#import "OAEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface OANode : OAEntity <OAEntityProtocol>

-(id)initWithNode:(OANode *)node identifier:(long long)identifier;

@end

NS_ASSUME_NONNULL_END
