//
//  OANode.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/Node.java
//  git revision cc94ead73db0af7a3793cd56ba08a750d2c992f9

#import "OAEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface OANode : OAEntity <OAEntityProtocol>

-(id)initWithNode:(OANode *)node identifier:(long long)identifier;

@end

NS_ASSUME_NONNULL_END
