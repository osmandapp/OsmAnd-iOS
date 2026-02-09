//
//  QuadRect.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QuadRect : NSObject

@property (nonatomic, readonly) double left;
@property (nonatomic, readonly) double top;
@property (nonatomic, readonly) double right;
@property (nonatomic, readonly) double bottom;

- (nonnull instancetype)initWithLeft:(double)left top:(double)top right:(double)right bottom:(double)bottom;
- (nonnull instancetype)initWithRect:(QuadRect *)rect;

- (double)width;
- (double)height;
- (BOOL)contains:(double)left top:(double)top right:(double)right bottom:(double)bottom;
- (BOOL)contains:(QuadRect *)box;
- (double)centerX;
- (double) centerY;
- (void)offset:(double)dx dy:(double)dy;
- (void)inset:(double)dx dy:(double)dy;

+ (BOOL)intersects:(QuadRect *)a b:(QuadRect *)b;

@end
