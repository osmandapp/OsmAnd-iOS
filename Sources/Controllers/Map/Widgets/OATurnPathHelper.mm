//
//  OATurnPathHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATurnPathHelper.h"

//Index of processed turn
#define FIRST_TURN 1
#define SECOND_TURN 2
#define THIRD_TURN 3
#define SHOW_STEPS YES

@interface OATurnPathHelper ()

+ (float) getX:(double)angle radius:(double)radius;
+ (float) getY:(double)angle radius:(double)radius;
+ (float) alignRotation:(float)t leftSide:(BOOL)leftSide minDelta:(double)minDelta out:(int)out;

+ (void) arcLineTo:(UIBezierPath *)pathForTurn angle:(double)angle cx:(float)cx cy:(float)cy radius:(float)radius;
+ (void) arcQuadTo:(UIBezierPath *)pathForTurn angle0:(double)angle0 radius0:(float)radius0 angle:(double)angle radius:(float)radius angle2:(double)angle2 radius2:(float)radius2 dl:(float)dl cx:(float)cx cy:(float)cy;

@end

@interface OATurnVariables : NSObject

@end

@implementation OATurnVariables
{
    float radEndOfArrow;
    float radInnerCircle;
    float radOuterCircle;
    
    float radBottom;
    float radStepInter;
    float radArrowTriangle1;
    
    float widthStepIn;
    float widthStepInter;
    float widthArrow;
    float radArrowTriangle2;
    double dfL;
    double dfAr2;
    double dfStepInter;
    double dfAr;
    double dfOut;
    double dfStepOut;
    double dfIn;
    double minDelta;
    double rot;
    float cx;
    float cy;
    float scaleTriangle;
}

- (instancetype) initWithLeftSide:(BOOL)_leftSide turnAngle:(float)_turnAngle out:(int)_out wa:(int)_wa ha:(int)_ha scaleTriangle:(float)_scaleTriangle
{
    self = [super init];
    if (self)
    {
        radEndOfArrow = 44.f;
        radInnerCircle = 10.f;
        radOuterCircle = radInnerCircle + 8.f;
        
        radBottom = radOuterCircle + 10.f;
        radStepInter = radOuterCircle + 6.f;
        radArrowTriangle1 = radOuterCircle + 7.f;
        
        widthStepIn = 8.f;
        widthStepInter = 6.f;
        widthArrow = 22.f;
        
        scaleTriangle = _scaleTriangle;
        widthArrow = widthArrow * scaleTriangle;
        radArrowTriangle2 = radArrowTriangle1 + 1 * scaleTriangle * scaleTriangle;
        
        dfL = (_leftSide ? 1 : -1) * asinf(widthStepIn / (2.0 * radBottom));
        dfAr2 = (_leftSide ? 1 : -1) * asinf(widthArrow / (2.0 * radArrowTriangle2));
        dfStepInter = (_leftSide ? 1 : -1) * asinf(widthStepInter / radStepInter);
        dfAr = asinf(radBottom * sinf(dfL) / radArrowTriangle1);
        dfOut = asinf(radBottom * sinf(dfL) / radOuterCircle);
        dfStepOut = asinf(radStepInter * sinf(dfStepInter) / radOuterCircle);
        dfIn = asinf(radBottom * sinf(dfL) / radInnerCircle);
        minDelta = ABS(dfIn * 2 / M_PI * 180) + 2;
        
        rot = [OATurnPathHelper alignRotation:_turnAngle leftSide:_leftSide minDelta:minDelta out:_out] / 180 * M_PI;
        
        cx = _wa / 2;
        cy = _ha / 2;
        // align center
        float potentialArrowEndX = (float) (sinf(rot) * radEndOfArrow);
        float potentialArrowEndY = (float) (cosf(rot) * radEndOfArrow);
        if (potentialArrowEndX > cx)
            cx = potentialArrowEndX;
        else if (potentialArrowEndX < -cx)
            cx = 2 * cx + potentialArrowEndX;
        
        if (potentialArrowEndY > cy)
            cy = 2 * cy - potentialArrowEndY;
        else if (potentialArrowEndY < -cy)
            cy = -potentialArrowEndY;
    }
    return self;
}

- (float) getProjX:(double)angle radius:(double)radius
{
    return [OATurnPathHelper getX:angle radius:radius] + cx;
}

- (float) getProjY:(double)angle radius:(double)radius
{
    return [OATurnPathHelper getY:angle radius:radius] + cy;
}

- (float) getTriangle2X
{
    return [self getProjX:rot + dfAr radius:radArrowTriangle1];
}

- (float) getTriangle1X
{
    return [self getProjX:rot - dfAr radius:radArrowTriangle1];
}

- (float) getTriangle2Y
{
    return [self getProjY:rot + dfAr radius:radArrowTriangle1];
}

- (float) getTriangle1Y
{
    return [self getProjY:rot - dfAr radius:radArrowTriangle1];
}

- (void) drawTriangle:(UIBezierPath *)pathForTurn
{
    // up from arc
    [OATurnPathHelper arcLineTo:pathForTurn angle:rot - dfAr cx:cx cy:cy radius:radArrowTriangle1];
    // left triangle
    // arcLineTo(pathForTurn, rot - dfAr2, cx, cy, radAr2); // 1.
    // arcQuadTo(pathForTurn, rot - dfAr2, radAr2, rot, radArrow, 0.9f, cx, cy); // 2.
    [OATurnPathHelper arcQuadTo:pathForTurn angle0:rot - dfAr radius0:radArrowTriangle1 angle:rot - dfAr2 radius:radArrowTriangle2 angle2:rot radius2:radEndOfArrow dl:4.5f * scaleTriangle cx:cx cy:cy]; // 3.
    // arcLineTo(pathForTurn, rot, cx, cy, radArrow); // 1.
    [OATurnPathHelper arcQuadTo:pathForTurn angle0:rot - dfAr2 radius0:radArrowTriangle2 angle:rot radius:radEndOfArrow angle2:rot + dfAr2 radius2:radArrowTriangle2 dl:4.5f cx:cx cy:cy];
    // right triangle
    // arcLineTo(pathForTurn, rot + dfAr2, cx, cy, radAr2); // 1.
    [OATurnPathHelper arcQuadTo:pathForTurn angle0:rot radius0:radEndOfArrow angle:rot + dfAr2 radius:radArrowTriangle2 angle2:rot + dfAr radius2:radArrowTriangle1 dl:4.5f * scaleTriangle cx:cx cy:cy];
    [OATurnPathHelper arcLineTo:pathForTurn angle:rot + dfAr cx:cx cy:cy radius:radArrowTriangle1];
}

@end

@implementation OATurnPathHelper

// angle - bottom is zero, right is -90, left is 90
+ (float) getX:(double)angle radius:(double)radius
{
    return cosf(angle + M_PI / 2) * radius;
}

+ (float) getY:(double)angle radius:(double)radius
{
    return sinf(angle + M_PI / 2) * radius;
}

+ (float) getProjX:(double)angle cx:(float)cx cy:(float)cy radius:(double)radius
{
    return [self.class getX:angle radius:radius] + cx;
}

+ (float) getProjY:(double)angle cx:(float)cx cy:(float)cy radius:(double)radius
{
    return [self.class getY:angle radius:radius] + cy;
}


+ (float) alignRotation:(float)t leftSide:(BOOL)leftSide minDelta:(double)minDelta out:(int)out
{
    // t between ]-180, 180]
    while (t > 180) {
        t -= 360;
    }
    while (t <= -180) {
        t += 360;
    }
    // rot left - ] 0, 360], right ] -360,0]
    float rot = leftSide ? (t + 180) : (t - 180) ;
    if (rot == 0) {
        rot = leftSide ? 360 : -360;
    }
    float delta = (float) minDelta;
    if (rot > 360 - delta && rot <= 360) {
        rot = 360 - delta;
        if(out < 2) {
            rot = delta;
        }
    } else if (rot < -360 + delta && rot >= -360) {
        rot = -360 + delta;
        if(out < 2) {
            rot = -delta;
        }
    } else if (rot >= 0 && rot < delta) {
        rot = delta;
        if (out > 2) {
            rot = 360 - delta;
        }
    } else if (rot <= 0 && rot > -delta) {
        rot = -delta;
        if (out > 2) {
            rot = -360 + delta;
        }
    }
    return rot;
}

+ (void) arcLineTo:(UIBezierPath *)pathForTurn angle:(double)angle cx:(float)cx cy:(float)cy radius:(float)radius
{
    [pathForTurn addLineToPoint:CGPointMake([self.class getProjX:angle cx:cx cy:cy radius:radius], [self.class getProjY:angle cx:cx cy:cy radius:radius])];
}

+ (void) arcQuadTo:(UIBezierPath *)pathForTurn angle0:(double)angle0 radius0:(float)radius0 angle:(double)angle radius:(float)radius angle2:(double)angle2 radius2:(float)radius2 dl:(float)dl cx:(float)cx cy:(float)cy
{
    float X0 = [self.class getProjX:angle0 cx:cx cy:cy radius:radius0];
    float Y0 = [self.class getProjY:angle0 cx:cx cy:cy radius:radius0];
    float X = [self.class getProjX:angle cx:cx cy:cy radius:radius];
    float Y = [self.class getProjY:angle cx:cx cy:cy radius:radius];
    float X2 = [self.class getProjX:angle2 cx:cx cy:cy radius:radius2];
    float Y2 = [self.class getProjY:angle2 cx:cx cy:cy radius:radius2];
    float l2 = sqrtf((X-X2)*(X-X2) + (Y-Y2)*(Y-Y2));
    float l0 = sqrtf((X-X0)*(X-X0) + (Y-Y0)*(Y-Y0));
    float proc2 = (float) (dl / l2);
    float proc = (float) (dl / l0);
    [pathForTurn addLineToPoint:CGPointMake(X0 * proc + X * (1 - proc), Y0 * proc + Y * (1 - proc))];
    [pathForTurn addQuadCurveToPoint:CGPointMake(X, Y) controlPoint:CGPointMake(X2 * proc2 + X * (1 - proc2), Y2 * proc2 + Y * (1 - proc2))];
}

@end
