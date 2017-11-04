//
//  OATurnDrawable.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATurnPathHelper.h"

@interface OATurnDrawable : UIView

//@property (nonatomic) Paint paintBlack;
//@property (nonatomic) Paint paintRouteDirection;
@property (nonatomic) UIBezierPath *pathForTurn;
@property (nonatomic) UIBezierPath *pathForTurnOutlay;
@property (nonatomic, readonly) std::shared_ptr<TurnType> turnType;
@property (nonatomic) int turnImminent;
@property (nonatomic) BOOL deviatedFromRoute;
@property (nonatomic) UIFont *textFont;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *clr;

- (instancetype) initWithMini:(BOOL)mini;

- (BOOL) setTurnType:(std::shared_ptr<TurnType>)turnType;
- (void) setTurnImminent:(int)turnImminent deviatedFromRoute:(BOOL)deviatedFromRoute;

@end
