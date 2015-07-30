//
//  QuadTree.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QuadRect;

@interface QuadTree : NSObject

- (instancetype)initWithQuadRect:(QuadRect *)rect depth:(int)depth ratio:(float)ratio;

- (void)clear;
- (void)insert:(id)data box:(QuadRect *)box;
- (void)insert:(id)data x:(float)x y:(float)y;
- (NSArray *)queryInBox:(QuadRect *)box result:(NSMutableArray *)result;

@end
