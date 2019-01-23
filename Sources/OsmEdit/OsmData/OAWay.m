//
//  OAWay.m
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAWay.h"
#import "OANode.h"
#import "QuadRect.h"
#import "OAOsmMapUtils.h"

@implementation OAWay
{
    NSMutableArray<NSNumber *> *_nodeIds;
    NSMutableArray<OANode *> *_nodes;
}

-(id)initWithWay:(OAWay *)way
{
    self = [super initWithId:[way getId]];
    if (self) {
        NSArray<NSNumber *> *nodeIds = [way getNodeIds];
        if (nodeIds)
            _nodeIds = [NSMutableArray arrayWithArray:nodeIds];
        NSArray<OANode *> *nodes = [way getNodes];
        if (nodes)
            _nodes = [NSMutableArray arrayWithArray:nodes];
    }
    return self;
}


-(id)initWithId:(long)identifier nodes:(NSArray<OANode *> *)nodes
{
    self = [super initWithId:identifier];
    if (self) {
        _nodes = [NSMutableArray arrayWithArray:nodes];
        NSMutableArray<NSNumber *> *nodeIds = [NSMutableArray arrayWithCapacity:[_nodes count]];
        for (OANode *nd in _nodes) {
            [nodeIds addObject:[NSNumber numberWithLong:[nd getId]]];
        }
        _nodeIds = [NSMutableArray arrayWithArray:nodeIds];
    }
    return self;
}

-(id)initWithId:(long)identifier latitude:(double)lat longitude:(double)lon ids:(NSArray<NSNumber *> *)nodeIds
{
    self = [super initWithId:identifier latitude:lat longitude:lon];
    if (self) {
        _nodeIds = [NSMutableArray arrayWithArray:nodeIds];
    }
    return self;
}

-(NSArray<NSNumber *> *) getNodeIds
{
    if (!_nodeIds)
        return [NSArray new];
    return [NSArray arrayWithArray:_nodeIds];
}

-(NSArray<OANode *> *) getNodes
{
    if (!_nodes)
        return [NSArray new];
    return [NSArray arrayWithArray:_nodes];
}

-(void)addNodeById:(long)identifier
{
    if (!_nodeIds)
        _nodeIds = [NSMutableArray new];
    
    [_nodeIds addObject:[NSNumber numberWithLong:identifier]];
}
-(long) getFirstNodeId
{
    if (!_nodeIds || [_nodeIds count] == 0)
        return -1;
    
    return _nodeIds.firstObject.longValue;
}

-(long)getLastNodeId
{
    if (!_nodeIds || [_nodeIds count] == 0)
        return -1;
    
    return _nodeIds.lastObject.longValue;
}

-(OANode *) getFirstNode
{
    if (!_nodes || [_nodes count] == 0)
        return nil;
    
    return _nodes.firstObject;
}

-(OANode *) getLastNode
{
    if (!_nodes || [_nodes count] == 0)
        return nil;
    
    return _nodes.lastObject;
}

-(void)addNode:(OANode *)node
{
    if (!_nodeIds)
        _nodeIds = [NSMutableArray new];

    if (!_nodes)
        _nodes = [NSMutableArray new];
    
    [_nodeIds addObject:[NSNumber numberWithLong:[node getId]]];
    [_nodes addObject:node];
}

-(void)reverseNodes
{
    if (_nodes)
        _nodes = [[[_nodes reverseObjectEnumerator] allObjects] mutableCopy];
    if (_nodeIds)
        _nodeIds = [[[_nodeIds reverseObjectEnumerator] allObjects] mutableCopy];
}

- (CLLocationCoordinate2D)getLatLon {
    if (!_nodes)
        return kCLLocationCoordinate2DInvalid;
    return [OAOsmMapUtils getWeightCenterForWay:self];
}

- (void)initializeLinks:(nonnull NSDictionary<OAEntityId *,OAEntity *> *)entities {
    if (_nodeIds) {
        if (!_nodes) {
            _nodes = [NSMutableArray new];
        } else {
            [_nodes removeAllObjects];
        }
        NSInteger nIsize = [_nodeIds count];
        for (int i = 0; i < nIsize; i++) {
            [_nodes addObject:((OANode *)[entities objectForKey:[[OAEntityId alloc]
                                                                 initWithEntityType:NODE identifier:_nodeIds[i].longValue]])];
        }
    }
}

// Unused in Android
-(void)addNode:(OANode *)node atIndex:(NSInteger)index
{
    if (!_nodeIds)
        _nodeIds = [NSMutableArray new];
    
    if (!_nodes)
        _nodes = [NSMutableArray new];
    
    _nodeIds[index] = [NSNumber numberWithLong:[node getId]];
    _nodes[index] = node;
}

-(void)removeNodeByIndex:(NSInteger)index
{
    if (!_nodeIds)
        return;
    
    [_nodeIds removeObjectAtIndex:index];
    if (_nodes&& [_nodes count] > index)
        [_nodes removeObjectAtIndex:index];
}

-(NSArray<OAEntityId *> *)getEntityIds
{
    if (!_nodeIds)
        return [[NSArray alloc] init];
    
    NSMutableArray<OAEntityId *> *ls = [NSMutableArray new];
    for (NSNumber *nodeId in _nodeIds) {
        [ls addObject:[[OAEntityId alloc] initWithEntityType:NODE identifier:nodeId.longValue]];
    }
    return ls;
}
// Returns top - as maximum latitude, bottom as minimum
-(QuadRect *) getLatLonBBox
{
    QuadRect *qr = nil;
    if (_nodes) {
        for (OANode *n in _nodes) {
            if (!qr)
            {
                qr = [[QuadRect alloc] initWithLeft:[n getLongitude] top:[n getLatitude] right:[n getLongitude] bottom:[n getLatitude]];
            }
            if ([n getLongitude] < qr.left) {
                qr = [[QuadRect alloc] initWithLeft:[n getLongitude] top:qr.top right:qr.right bottom:qr.bottom];
            } else if ([n getLongitude] > qr.right) {
                qr = [[QuadRect alloc] initWithLeft:qr.left top:qr.top right:[n getLongitude] bottom:qr.bottom];
            }
            if ([n getLatitude] > qr.top) {
                qr = [[QuadRect alloc] initWithLeft:qr.left top:[n getLatitude] right:qr.right bottom:qr.bottom];
            } else if ([n getLatitude] < qr.bottom) {
                qr = [[QuadRect alloc] initWithLeft:qr.left top:qr.top right:qr.right bottom:[n getLatitude]];
            }
        }
    }
    return qr;
}

@end
