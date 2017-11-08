//
//  OATurnResource.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OATurnResource : NSObject

@property (nonatomic, readonly) int turnType;
@property (nonatomic, readonly) BOOL shortArrow;
@property (nonatomic, readonly) BOOL noOverlap;
@property (nonatomic, readonly) BOOL leftSide;

- (instancetype) initWithTurnType:(int)turnType noOverlap:(BOOL)noOverlap leftSide:(BOOL)leftSide;
- (instancetype) initWithTurnTypeShort:(int)turnType leftSide:(BOOL)leftSide;

@end
