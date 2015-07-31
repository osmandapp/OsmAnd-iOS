//
//  QuadTree.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "QuadTree.h"
#import "QuadRect.h"

@interface Node : NSObject

@property (nonatomic) NSMutableArray *data;
@property (nonatomic) NSMutableArray *children;
@property (nonatomic) QuadRect *bounds;

@end

@implementation Node

- (instancetype)initWithQuadRect:(QuadRect *)rect
{
    self = [super init];
    if (self)
    {
        _bounds = [[QuadRect alloc] initWithLeft:rect.left top:rect.top right:rect.right bottom:rect.bottom];
        _children = [NSMutableArray arrayWithArray:@[[NSNull null],
                                                     [NSNull null],
                                                     [NSNull null],
                                                     [NSNull null]]];
    }
    return self;
}

@end


@implementation QuadTree
{
    float _ratio;
    int _maxDepth;
    Node *_root;
}

- (instancetype)initWithQuadRect:(QuadRect *)rect depth:(int)depth ratio:(float)ratio
{
    self = [super init];
    if (self)
    {
        _ratio = ratio;
        _root = [[Node alloc] initWithQuadRect:rect];
        _maxDepth = depth;
    }
    return self;
}

- (void)insert:(id)data box:(QuadRect *)box
{
    int depth = 0;
    [self doInsertData:data box:box n:_root depth:depth];
}

- (void)clear
{
    [self clear:_root];
}

- (void)clear:(Node *)rt
{
    if (rt)
    {
        if (rt.data)
            [rt.data removeAllObjects];

        if (rt.children)
        {
            for(Node *c in rt.children)
                [self clear:c];
        }
    }
}

- (void)insert:(id)data x:(float)x y:(float)y
{
    [self insert:data box:[[QuadRect alloc] initWithLeft:x top:y right:x bottom:y]];
}

- (NSArray *)queryInBox:(QuadRect *)box result:(NSMutableArray *)result
{
    [result removeAllObjects];
    [self queryNode:box result:result node:_root];
    return result;
}

- (void)queryNode:(QuadRect *)box result:(NSMutableArray *)result node:(Node *)node
{
    if (node && [node isKindOfClass:[Node class]])
    {
        if ([QuadRect intersects:box b:node.bounds])
        {
            if (node.data)
                [result addObjectsFromArray:node.data];

            for (int k = 0; k < 4; ++k)
                [self queryNode:box result:result node:node.children[k]];
        }
    }
}

- (void)doInsertData:(id)data box:(QuadRect *)box n:(Node *)n depth:(int)depth
{
    if (++depth >= _maxDepth)
    {
        if (!n.data)
            n.data = [NSMutableArray array];
        
        [n.data addObject:data];
    }
    else
    {
        NSMutableArray *ext = [NSMutableArray arrayWithArray:@[[NSNull null],
                                                               [NSNull null],
                                                               [NSNull null],
                                                               [NSNull null]]];
        [self splitBox:n.bounds n:ext];
        for (int i = 0; i < 4; ++i)
        {
            QuadRect *r = ext[i];
            if ([r contains:box])
            {
                if (n.children[i] == [NSNull null])
                    n.children[i] = [[Node alloc] initWithQuadRect:r];
                
                [self doInsertData:data box:box n:n.children[i] depth:depth];
                return;
            }
        }
        if (!n.data)
            n.data = [NSMutableArray array];
        
        [n.data addObject:data];
    }
}

- (void)splitBox:(QuadRect *)node_extent n:(NSMutableArray *)n
{
    // coord2d c=node_extent.center();
    
    double width = node_extent.width;
    double height = node_extent.height;
    
    double lox = node_extent.left;
    double loy = node_extent.top;
    double hix = node_extent.right;
    double hiy = node_extent.bottom;
    
    n[0] = [[QuadRect alloc] initWithLeft:lox top:loy right:lox + width * _ratio bottom:loy + height * _ratio];
    n[1] = [[QuadRect alloc] initWithLeft:hix - width * _ratio top:loy right:hix bottom:loy + height * _ratio];
    n[2] = [[QuadRect alloc] initWithLeft:lox top:hiy - height * _ratio right:lox + width * _ratio bottom:hiy];
    n[3] = [[QuadRect alloc] initWithLeft:hix - width * _ratio top:hiy - height * _ratio right:hix bottom:hiy];
}

@end
