//
//  OAWay.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAEntity.h"

NS_ASSUME_NONNULL_BEGIN

@class OANode;
@class QuadRect;

@interface OAWay : OAEntity <OAEntityProtocol>

-(id)initWithWay:(OAWay *)way;
-(id)initWithId:(long)identifier nodes:(NSArray<OANode *> *)nodes;
-(id)initWithId:(long)identifier latitude:(double)lat longitude:(double)lon ids:(NSArray<NSNumber *> *)nodeIds;

-(void)addNodeById:(long)identifier;
-(long) getFirstNodeId;
-(long)getLastNodeId;

-(OANode *) getFirstNode;
-(OANode *) getLastNode;
-(void)addNode:(OANode *)node;
-(void)addNode:(OANode *)node atIndex:(NSInteger)index;
-(void)removeNodeByIndex:(NSInteger)index;

-(NSArray<NSNumber *> *) getNodeIds;
-(NSArray<OAEntityId *> *)getEntityIds;
-(NSArray<OANode *> *) getNodes;

-(QuadRect *) getLatLonBBox;

-(void)reverseNodes;

@end

NS_ASSUME_NONNULL_END
