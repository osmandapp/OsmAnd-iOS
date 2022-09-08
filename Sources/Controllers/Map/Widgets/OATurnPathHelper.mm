//
//  OATurnPathHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATurnPathHelper.h"
#import "OAUtilities.h"
#import "OATurnResource.h"

@interface OATurnPathHelper ()

+ (float) getX:(double)angle radius:(double)radius;
+ (float) getY:(double)angle radius:(double)radius;
+ (float) alignRotation:(float)t leftSide:(BOOL)leftSide minDelta:(double)minDelta out:(int)out;

+ (void) arcLineTo:(UIBezierPath *)pathForTurn angle:(double)angle cx:(float)cx cy:(float)cy radius:(float)radius;
+ (void) arcQuadTo:(UIBezierPath *)pathForTurn angle0:(double)angle0 radius0:(float)radius0 angle:(double)angle radius:(float)radius angle2:(double)angle2 radius2:(float)radius2 dl:(float)dl cx:(float)cx cy:(float)cy;

@end

@interface OATurnVariables : NSObject

@property (nonatomic, assign) float radEndOfArrow;
@property (nonatomic, assign) float radInnerCircle;
@property (nonatomic, assign) float radOuterCircle;
    
@property (nonatomic, assign) float radBottom;
@property (nonatomic, assign) float radStepInter;
@property (nonatomic, assign) float radArrowTriangle1;
    
@property (nonatomic, assign) float widthStepIn;
@property (nonatomic, assign) float widthStepInter;
@property (nonatomic, assign) float widthArrow;
@property (nonatomic, assign) float radArrowTriangle2;
@property (nonatomic, assign) double dfL;
@property (nonatomic, assign) double dfAr2;
@property (nonatomic, assign) double dfStepInter;
@property (nonatomic, assign) double dfAr;
@property (nonatomic, assign) double dfOut;
@property (nonatomic, assign) double dfStepOut;
@property (nonatomic, assign) double dfIn;
@property (nonatomic, assign) double minDelta;
@property (nonatomic, assign) double rot;
@property (nonatomic, assign) float cx;
@property (nonatomic, assign) float cy;
@property (nonatomic, assign) float scaleTriangle;

@end

@implementation OATurnVariables

@synthesize radEndOfArrow, radInnerCircle, radOuterCircle;
@synthesize radBottom, radStepInter, radArrowTriangle1;
@synthesize widthStepIn, widthStepInter, widthArrow, radArrowTriangle2, dfL, dfAr2, dfStepInter, dfAr, dfOut, dfStepOut, dfIn, minDelta, rot, cx, cy, scaleTriangle;

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

+ (float) startArcAngle:(double)i
{
    return (float) (i * 180 / M_PI + 90);
}

+ (float) sweepArcAngle:(double)d
{
    return (float) (d * 180 / M_PI);
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
    [pathForTurn lineToX:[self.class getProjX:angle cx:cx cy:cy radius:radius] y:[self.class getProjY:angle cx:cx cy:cy radius:radius]];
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
    [pathForTurn lineToX:X0 * proc + X * (1 - proc) y:Y0 * proc + Y * (1 - proc)];
    [pathForTurn addQuadCurveToPoint:CGPointMake(X2 * proc2 + X * (1 - proc2), Y2 * proc2 + Y * (1 - proc2)) controlPoint:CGPointMake(X, Y)];
}

// 72x72
+ (void) calcTurnPath:(UIBezierPath *)pathForTurn outlay:(UIBezierPath *)outlay turnType:(std::shared_ptr<TurnType>)turnType transform:(CGAffineTransform)transform center:(CGPoint *)center mini:(BOOL)mini shortArrow:(BOOL)shortArrow noOverlap:(BOOL)noOverlap smallArrow:(BOOL)smallArrow
{
    if (!turnType)
        return;
    
    [pathForTurn removeAllPoints];
    if (outlay)
        [outlay removeAllPoints];
    
    int ha = 72;
    int wa = 72;
    int lowMargin = 6;
    float scaleTriangle = smallArrow ? 1.f : 1.5f;
    int turnTypeId = turnType->getValue();
    
    // TEST
    //if (TurnType::C != turnTypeId)
    //    turnTypeId = TurnType::TU;
    
    if (TurnType::C == turnTypeId)
    {
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:NO turnAngle:0 out:0 wa:wa ha:ha scaleTriangle:scaleTriangle];
        [pathForTurn moveToX:wa / 2 + tv.widthStepIn / 2 y:ha - lowMargin];
        [tv drawTriangle:pathForTurn];
        [pathForTurn lineToX:wa / 2 - tv.widthStepIn / 2 y:ha - lowMargin];
    }
    else if (TurnType::OFFR == turnTypeId)
    {
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:NO turnAngle:0 out:0 wa:wa ha:ha scaleTriangle:scaleTriangle];
        float rightX = wa / 2 + tv.widthStepIn / 2;
        float leftX = wa / 2 - tv.widthStepIn / 2;
        int step = 7;
        
        [pathForTurn moveToX:rightX y:ha - lowMargin];
        [pathForTurn rLineToX:0 y:-step];
        [pathForTurn rLineToX:-tv.widthStepIn y:0];
        [pathForTurn rLineToX:0 y:step];
        [pathForTurn rLineToX:tv.widthStepIn y:0];
        
        [pathForTurn moveToX:rightX y:ha - 2 * lowMargin - step];
        [pathForTurn rLineToX:0 y:-step];
        [pathForTurn rLineToX:-tv.widthStepIn y:0];
        [pathForTurn rLineToX:0 y:step];
        [pathForTurn rLineToX:tv.widthStepIn y:0];
        
        [pathForTurn moveToX:rightX y:ha - 3 * lowMargin - 2 * step];
        [pathForTurn rLineToX:0 y:-step];
        [pathForTurn rLineToX:-tv.widthStepIn y:0];
        [pathForTurn rLineToX:0 y:step];
        [pathForTurn rLineToX:tv.widthStepIn y:0];
        
        [pathForTurn moveToX:rightX y:ha - 4 * lowMargin - 3 * step];
        [tv drawTriangle:pathForTurn];
        [pathForTurn lineToX:leftX y:ha - 4 * lowMargin - 3 * step];
    }
    else if (TurnType::TR == turnTypeId || TurnType::TL == turnTypeId)
    {
        int b = TurnType::TR == turnTypeId ? 1 : -1;
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:b != 1 turnAngle:b == 1 ? 90 : -90 out:0 wa:wa ha:(shortArrow ? ha : ha / 2) scaleTriangle:scaleTriangle];
        // calculated
        float rDiv =  (shortArrow ? 4 : noOverlap ? 1 : 2);
        float r = (tv.cy - tv.widthStepIn / 2) / rDiv;
        float centerCurveX = wa / 2 + b * (noOverlap ? 4 : r + tv.widthStepIn / 2);
        float centerCurveY = ha / 2 + (shortArrow ? r + tv.widthStepIn / 2 : !noOverlap ? -r : 0);
        float h = ha - centerCurveY - lowMargin;
        float centerLineX = centerCurveX - b * (r + tv.widthStepIn / 2);
        CGRect innerOval = CGRectMake(centerCurveX - r, centerCurveY - r, r * 2, r * 2);
        CGRect outerOval = CGRectInset(innerOval, -tv.widthStepIn, -tv.widthStepIn);
        
        [pathForTurn moveToX:centerLineX + b * tv.widthStepIn / 2 y:ha - lowMargin];
        [pathForTurn rLineToX:0 y:-h];
        [pathForTurn arcTo:innerOval startAngle:b == 1 ? -180 : 0 sweepAngle:b * 90];
        [tv drawTriangle:pathForTurn];
        [pathForTurn arcTo:outerOval startAngle:-90 sweepAngle:-b * 90];
        [pathForTurn rLineToX:0 y:h];
    }
    else if (TurnType::TSLR == turnTypeId || TurnType::TSLL == turnTypeId)
    {
        int b = TurnType::TSLR == turnTypeId ? 1 : -1;
        float angle = shortArrow ? 65 : 45;
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:b != 1 turnAngle:b == 1 ? angle : -angle out:0 wa:wa ha:ha scaleTriangle:scaleTriangle];
        tv.cx -= b * (shortArrow ? 0 : 7);
        tv.cy += shortArrow ? 12 : 0;
        float centerBottomX = wa / 2 - (noOverlap ? b * 6 : 0);
        float centerCurveY = shortArrow ? ha - 6 : ha / 2 + 8;
        float centerCurveX = centerBottomX + b * (wa / 2 - (shortArrow && noOverlap ? 6 : 0));
        // calculated
        float rx1 =  ABS(centerCurveX - centerBottomX) - tv.widthStepIn / 2;
        float rx2 =  ABS(centerCurveX - centerBottomX) + tv.widthStepIn / 2;
        double t1 = acosf(ABS([tv getTriangle1X] - centerCurveX) / rx1) ;
        float rb1 = (float) (ABS([tv getTriangle1Y] - centerCurveY) / sinf(t1));
        float ellipseAngle1 = (float) (t1 / M_PI * 180);
        double t2 = acosf(ABS([tv getTriangle2X] - centerCurveX) / rx2) ;
        float rb2 = (float) (ABS([tv getTriangle2Y] - centerCurveY) / sinf(t2));
        float ellipseAngle2 = (float) (t2 / M_PI * 180);
        
        CGRect innerOval = CGRectMake(centerCurveX - rx1, centerCurveY - rb1, rx1 * 2, rb1 * 2);
        CGRect outerOval = CGRectMake(centerCurveX - rx2, centerCurveY - rb2, rx2 * 2, rb2 * 2);
        
        [pathForTurn moveToX:centerBottomX + b * tv.widthStepIn / 2 y:ha - lowMargin];
        [pathForTurn arcTo:innerOval startAngle:-90 - b * 90 sweepAngle:b * (ellipseAngle1)];
        [tv drawTriangle:pathForTurn];
        [pathForTurn arcTo:outerOval startAngle:-90 - b * (90 - (ellipseAngle2)) sweepAngle:-b * (ellipseAngle2)];
        [pathForTurn lineToX:centerBottomX - b * tv.widthStepIn / 2 y:ha - lowMargin];
    }
    else if (TurnType::TSHR == turnTypeId || TurnType::TSHL == turnTypeId)
    {
        int b = TurnType::TSHR == turnTypeId ? 1 : -1;
        float centerCircleY = shortArrow ? ha / 2 : ha / 4;
        float centerCircleX = wa / 2 - (noOverlap ? b * (wa / 5) : 0);
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:b != 1 turnAngle:b == 1 ? 135 : -135 out:0 wa:wa ha:ha scaleTriangle:scaleTriangle];
        // calculated
        float angle = 45;
        float r = tv.widthStepIn / 2;
        tv.cx = centerCircleX;
        tv.cy = centerCircleY;
        if (shortArrow)
        {
            tv.cx -= b * 2;
            tv.cy -= 2;
        }
        CGRect innerOval = CGRectMake(centerCircleX - r, centerCircleY - r, r * 2, r * 2);
        [pathForTurn moveToX:centerCircleX + b * tv.widthStepIn / 2 y:ha - lowMargin];
        [pathForTurn lineToX:centerCircleX + b * tv.widthStepIn / 2 y:(float) (centerCircleY + 2 * r)];
        //            [pathForTurn arcTo:innerOval, -90 - b * 90, b * 45);
        [tv drawTriangle:pathForTurn];
        //            [pathForTurn lineToX:centerCircleX - b * tv.widthStepIn / 2, (float) (centerCircleY - 2 *r));
        [pathForTurn arcTo:innerOval startAngle:-90  + b * angle sweepAngle:- b * (90 + angle)];
        [pathForTurn lineToX:centerCircleX - b * tv.widthStepIn / 2 y:ha - lowMargin];
    }
    else if (TurnType::TU == turnTypeId || TurnType::TRU == turnTypeId)
    {
        int b = TurnType::TU == turnTypeId ? -1 : 1;
        float radius = shortArrow ? 10 : 16;
        float centerRadiusY = ha / 2 + (shortArrow ? 10 : -10);
        float extraMarginBottom = shortArrow ? 0 : 5;
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:b != 1 turnAngle:180 out:0 wa:wa ha:ha scaleTriangle:scaleTriangle];
        // calculated
        float centerRadiusX = wa / 2 + (shortArrow ? b * radius : 0);
        tv.cx = centerRadiusX + b * radius;
        tv.cy = shortArrow ? ha - centerRadiusY : centerRadiusY - extraMarginBottom;
        lowMargin += extraMarginBottom;
        tv.rot = 0;
        
        float r = radius - tv.widthStepIn / 2;
        float r2 = radius + tv.widthStepIn / 2;
        CGRect innerOval = CGRectMake(centerRadiusX - r, centerRadiusY - r, r * 2, r * 2);
        CGRect outerOval = CGRectMake(centerRadiusX - r2, centerRadiusY - r2, r2 * 2, r2 * 2);
        
        [pathForTurn moveToX:centerRadiusX - b * (radius - tv.widthStepIn / 2) y:ha - lowMargin];
        [pathForTurn lineToX:centerRadiusX - b * (radius - tv.widthStepIn / 2) y:centerRadiusY];
        [pathForTurn arcTo:innerOval startAngle:-90 - b * 90 sweepAngle:b * 180];
        [tv drawTriangle:pathForTurn];
        [pathForTurn arcTo:outerOval startAngle:-90 + b * 90 sweepAngle:-b * 180];
        [pathForTurn lineToX:centerRadiusX - b * (radius + tv.widthStepIn / 2) y:ha - lowMargin];
    }
    else if (TurnType::KL == turnTypeId || TurnType::KR == turnTypeId)
    {
        int b = TurnType::KR == turnTypeId ? 1 : -1;
        float shiftX = shortArrow ? 12 : 8;
        float firstH = 18;
        float secondH = 20;
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:NO turnAngle:0 out:0 wa:wa ha:ha scaleTriangle:scaleTriangle];
        // calculated
        tv.cx += b * shiftX * (noOverlap ? 1 : 2);
        float dx = b * shiftX * (noOverlap ? 1 : 2);
        float mdx = -b * shiftX * (noOverlap ? 1 : 0);
        [pathForTurn moveToX:wa / 2 + tv.widthStepIn / 2 + mdx y:ha - lowMargin];
        [pathForTurn lineToX:wa / 2 + tv.widthStepIn / 2 + mdx y:ha - lowMargin - firstH];
        // [pathForTurn lineToX:wa / 2 + tv.widthStepIn / 2 + dx, ha - lowMargin - firstH - secondH);
        [pathForTurn cubicToX:wa / 2 + tv.widthStepIn / 2 + mdx y1:ha - lowMargin - firstH - secondH / 2 + b * 3
                           x2:wa / 2 + tv.widthStepIn / 2 + dx y2:ha - lowMargin - firstH - secondH / 2 + b * 3
                           x3:wa / 2 + tv.widthStepIn / 2 + dx y3:ha - lowMargin - firstH - secondH];
        [tv drawTriangle:pathForTurn];
        [pathForTurn lineToX:wa / 2 - tv.widthStepIn / 2 + dx y:ha - lowMargin - firstH - secondH];
        [pathForTurn cubicToX:wa / 2 - tv.widthStepIn / 2 + dx y1:ha - lowMargin - firstH - secondH / 2 - b * 2
                           x2:wa / 2 - tv.widthStepIn / 2 + mdx y2:ha - lowMargin - firstH - secondH / 2 - b * 2
                           x3:wa / 2 - tv.widthStepIn / 2 + mdx y3:ha - lowMargin - firstH];
        //            [pathForTurn lineToX:wa / 2 - tv.widthStepIn / 2 + mdx, ha - lowMargin - firstH);
        [pathForTurn lineToX:wa / 2 - tv.widthStepIn / 2 + mdx y:ha - lowMargin];
    }
    else if (turnType && turnType->isRoundAbout())
    {
        int out = turnType->getExitOut();
        BOOL leftSide = turnType->isLeftSide();
        BOOL showSteps = SHOW_STEPS && !mini;
        OATurnVariables *tv = [[OATurnVariables alloc] initWithLeftSide:leftSide turnAngle:turnType->getTurnAngle() out:out wa:wa ha:ha scaleTriangle:1];
        if (center)
        {
            center->x = tv.cx;
            center->y = tv.cy;
        }
        
        CGRect qrOut = CGRectMake(tv.cx - tv.radOuterCircle, tv.cy - tv.radOuterCircle,
                                  tv.radOuterCircle * 2, tv.radOuterCircle * 2);
        CGRect qrIn = CGRectMake(tv.cx - tv.radInnerCircle, tv.cy - tv.radInnerCircle,
                                 tv.radInnerCircle * 2, tv.radInnerCircle * 2);
        if (outlay && !mini)
        {
            [outlay addArc:qrOut startAngle:0 sweepAngle:360];
            [outlay addArc:qrIn startAngle:0 sweepAngle:-360];
            //                outlay.addOval(qrOut, Direction.CCW);
            //                outlay.addOval(qrIn, Direction.CW);
        }
        
        // move to bottom ring
        [pathForTurn moveToX:[tv getProjX:tv.dfOut radius:tv.radOuterCircle] y:[tv getProjY:tv.dfOut radius:tv.radOuterCircle]];
        if (out <= 1)
            showSteps = false;
        
        if (showSteps && outlay)
        {
            double totalStepInter = (out - 1) * tv.dfStepOut;
            double st = (tv.rot - 2 * tv.dfOut - totalStepInter) / out;
            if ((tv.rot > 0) != (st > 0)) {
                showSteps = false;
            }
            if (ABS(st) < M_PI / 60) {
                showSteps = false;
            }
            // double st = (rot - 2 * dfOut ) / (2 * out - 1);
            // dfStepOut = st;
            if (showSteps)
            {
                [outlay moveToX:[tv getProjX:tv.dfOut radius:tv.radOuterCircle] y:[tv getProjY:tv.dfOut radius:tv.radOuterCircle]];
                for (int i = 0; i < out - 1; i++)
                {
                    [outlay arcTo:qrOut startAngle:[self.class startArcAngle:tv.dfOut + i * (st + tv.dfStepOut)] sweepAngle:[self.class sweepArcAngle:st]];
                    [self.class arcLineTo:outlay
                                    angle:tv.dfOut + (i + 1) * (st + tv.dfStepOut) - tv.dfStepOut / 2 - tv.dfStepInter / 2
                                       cx:tv.cx
                                       cy:tv.cy
                                   radius:tv.radStepInter];
                    [self.class arcLineTo:outlay
                                    angle:tv.dfOut + (i + 1) * (st + tv.dfStepOut) - tv.dfStepOut / 2 + tv.dfStepInter / 2
                                       cx:tv.cx
                                       cy:tv.cy
                                   radius:tv.radStepInter];
                    [self.class arcLineTo:outlay
                                    angle:tv.dfOut + (i + 1) * (st + tv.dfStepOut)
                                       cx:tv.cx
                                       cy:tv.cy
                                   radius:tv.radOuterCircle];
                    // [pathForTurn arcTo:qr1, startArcAngle(dfOut), sweepArcAngle(rot - dfOut - dfOut));
                }
                [outlay arcTo:qrOut startAngle:[self.class startArcAngle:tv.rot - tv.dfOut - st] sweepAngle:[self.class sweepArcAngle:st]];
                // swipe back
                [self.class arcLineTo:outlay angle:tv.rot - tv.dfIn cx:tv.cx cy:tv.cy radius:tv.radInnerCircle];
                [outlay arcTo:qrIn startAngle:[self.class startArcAngle:tv.rot - tv.dfIn] sweepAngle:-[self.class sweepArcAngle:tv.rot - tv.dfIn - tv.dfIn]];
            }
        }
        //            if(!showSteps) {
        //                // arc
        //                [pathForTurn arcTo:qrOut, startArcAngle(dfOut), sweepArcAngle(rot - dfOut - dfOut));
        //            }
        [pathForTurn arcTo:qrOut startAngle:[self.class startArcAngle:tv.dfOut] sweepAngle:[self.class sweepArcAngle:tv.rot - tv.dfOut - tv.dfOut]];
        
        [tv drawTriangle:pathForTurn];
        // down to arc
        [self.class arcLineTo:pathForTurn angle:tv.rot + tv.dfIn cx:tv.cx cy:tv.cy radius:tv.radInnerCircle];
        // arc
        [pathForTurn arcTo:qrIn startAngle:[self.class startArcAngle:tv.rot + tv.dfIn] sweepAngle:[self.class sweepArcAngle:-tv.rot - tv.dfIn - tv.dfIn]];
        // down
        [self.class arcLineTo:pathForTurn angle:-tv.dfL cx:tv.cx cy:tv.cy radius:tv.radBottom];
        // left
        [self.class arcLineTo:pathForTurn angle:tv.dfL cx:tv.cx cy:tv.cy radius:tv.radBottom];
    }
    [pathForTurn closePath];
    if (!CGAffineTransformIsIdentity(transform))
        [pathForTurn applyTransform:transform];
}

+ (UIBezierPath *) getPathFromTurnType:(NSMapTable<OATurnResource *, UIBezierPath *> *)cache firstTurn:(int)firstTurn secondTurn:(int)secondTurn thirdTurn:(int)thirdTurn turnIndex:(int)turnIndex coef:(float)coef leftSide:(BOOL)leftSide smallArrow:(BOOL)smallArrow
{
    int firstTurnType = TurnType::valueOf(firstTurn, leftSide).getValue();
    int secondTurnType = TurnType::valueOf(secondTurn, leftSide).getValue();
    int thirdTurnType = TurnType::valueOf(thirdTurn, leftSide).getValue();
    
    OATurnResource *turnResource = nil;
    
    if (turnIndex == FIRST_TURN)
    {
        if (secondTurnType == 0)
        {
            turnResource = [[OATurnResource alloc] initWithTurnType:firstTurnType noOverlap:NO leftSide:leftSide];
        }
        else if (secondTurnType == TurnType::C || thirdTurnType == TurnType::C)
        {
            turnResource = [[OATurnResource alloc] initWithTurnTypeShort:firstTurnType leftSide:leftSide];
        }
        else
        {
            if (firstTurnType == TurnType::TU || firstTurnType == TurnType::TRU)
                turnResource = [[OATurnResource alloc] initWithTurnTypeShort:firstTurnType leftSide:leftSide];
            else
                turnResource = [[OATurnResource alloc] initWithTurnType:firstTurnType noOverlap:NO leftSide:leftSide];
        }
    }
    else if (turnIndex == SECOND_TURN)
    {
        if (TurnType::isLeftTurn(firstTurnType) && TurnType::isLeftTurn(secondTurnType))
            turnResource = nil;
        else if (TurnType::isRightTurn(firstTurnType) && TurnType::isRightTurn(secondTurnType))
            turnResource = nil;
        else if (firstTurnType == TurnType::C || thirdTurnType == TurnType::C)
            turnResource = [[OATurnResource alloc] initWithTurnTypeShort:secondTurnType leftSide:leftSide];
        else
            turnResource = [[OATurnResource alloc] initWithTurnType:secondTurnType noOverlap:NO leftSide:leftSide];
    }
    else if (turnIndex == THIRD_TURN)
    {
        if ((TurnType::isLeftTurn(firstTurnType) || TurnType::isLeftTurn(secondTurnType)) && TurnType::isLeftTurn(thirdTurnType))
            turnResource = nil;
        else if ((TurnType::isRightTurn(firstTurnType) || TurnType::isRightTurn(secondTurnType)) && TurnType::isRightTurn(thirdTurnType))
            turnResource = nil;
        else
            turnResource = [[OATurnResource alloc] initWithTurnTypeShort:thirdTurnType leftSide:leftSide];
    }
    if (!turnResource)
        return nil;
    
    UIBezierPath *path = [cache objectForKey:turnResource];
    if (!path)
    {
        path = [self.class getPathFromTurnResource:turnResource withSize:{LANE_IMG_SIZE, 18.} smallArrow:smallArrow];
        [cache setObject:path forKey:turnResource];
    }    
    return path;
}

+ (UIBezierPath *) getPathFromTurnResource:(OATurnResource *)turnResource withSize:(CGSize)size smallArrow:(BOOL)smallArrow
{
    CGFloat coef = size.width / 72.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 1.f;
    [self.class calcTurnPath:path outlay:nil turnType:TurnType::ptrValueOf(turnResource.turnType, turnResource.leftSide) transform:CGAffineTransformMakeScale(coef, coef) center:nil mini:NO shortArrow:turnResource.shortArrow noOverlap:turnResource.noOverlap smallArrow:smallArrow];
    
    return path;
}

@end
