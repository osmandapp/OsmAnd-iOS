//
//  OATurnDrawable.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOATurnDrawableThemeColor)
{
    EOATurnDrawableThemeColorMap,
    EOATurnDrawableThemeColorLight,
    EOATurnDrawableThemeColorDark
};

@interface OATurnDrawable : UIView

//@property (nonatomic) Paint paintBlack;
//@property (nonatomic) Paint paintRouteDirection;
@property (nonatomic) UIBezierPath *pathForTurn;
@property (nonatomic) UIBezierPath *pathForTurnOutlay;
@property (nonatomic) int turnImminent;
@property (nonatomic) BOOL deviatedFromRoute;
@property (nonatomic) UIFont *textFont;
@property (nonatomic) UIColor *clr;
@property (nonatomic) CGPoint centerText;

- (instancetype) initWithMini:(BOOL)mini themeColor:(EOATurnDrawableThemeColor)themeColor;

- (void) setTurnImminent:(int)turnImminent deviatedFromRoute:(BOOL)deviatedFromRoute;

@end
