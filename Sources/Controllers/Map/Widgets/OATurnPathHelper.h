//
//  OATurnPathHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <turnType.h>

//Index of processed turn
#define FIRST_TURN 1
#define SECOND_TURN 2
#define THIRD_TURN 3
#define SHOW_STEPS YES

#define LANE_IMG_SIZE 36.0

@class OATurnResource;

@interface OATurnPathHelper : NSObject

+ (void) calcTurnPath:(UIBezierPath *)pathForTurn outlay:(UIBezierPath *)outlay turnType:(std::shared_ptr<TurnType>)turnType transform:(CGAffineTransform)transform center:(CGPoint *)center mini:(BOOL)mini shortArrow:(BOOL)shortArrow noOverlap:(BOOL)noOverlap smallArrow:(BOOL)smallArrow;

+ (UIBezierPath *) getPathFromTurnType:(NSMapTable<OATurnResource *, UIBezierPath *> *)cache firstTurn:(int)firstTurn secondTurn:(int)secondTurn thirdTurn:(int)thirdTurn turnIndex:(int)turnIndex coef:(float)coef leftSide:(BOOL)leftSide smallArrow:(BOOL)smallArrow;

@end
