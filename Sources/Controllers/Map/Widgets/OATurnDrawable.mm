//
//  OATurnDrawable.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATurnDrawable.h"
#import "OAUtilities.h"
#import "GeneratedAssetSymbols.h"

@implementation OATurnDrawable
{
    BOOL _mini;
    UIColor *_routeDirectionColor;
    UIBezierPath *_pathForTurnForDrawing;
    UIBezierPath *_pathForTurnOutlayForDrawing;
}

- (instancetype) initWithMini:(BOOL)mini
{
    self = [super init];
    if (self)
    {
        _mini = mini;
        _pathForTurn = [UIBezierPath bezierPath];
        _pathForTurnOutlay = [UIBezierPath bezierPath];
        _pathForTurnOutlay.lineWidth = _mini ? 1.f : 2.f;
        _pathForTurn.lineWidth = _mini ? 1.f : 2.f;
        _centerText = CGPointZero;

        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        [self setClr:[UIColor colorNamed:ACColorNameNavArrowColor]];
    }
    return self;
}

- (void) setClr:(UIColor *)clr
{
    if (![clr isEqual:_clr])
    {
        _clr = clr;
        _routeDirectionColor = clr;
    }
}

- (void) layoutSubviews
{
    float scaleX = self.bounds.size.width / 72.f;
    float scaleY = self.bounds.size.height / 72.f;
    CGAffineTransform m = CGAffineTransformMakeScale(scaleX, scaleY);
    _pathForTurnForDrawing = [_pathForTurn copy];
    [_pathForTurnForDrawing applyTransform:m];
    self.centerText = CGPointMake(scaleX * self.centerText.x, scaleY * self.centerText.y);
    _pathForTurnOutlayForDrawing = [_pathForTurnOutlay copy];
    [_pathForTurnOutlayForDrawing applyTransform:m];
}

- (void) setTurnImminent:(int)turnImminent deviatedFromRoute:(BOOL)deviatedFromRoute
{
    //if user deviates from route that we should draw grey arrow
    _turnImminent = turnImminent;
    _deviatedFromRoute = deviatedFromRoute;
    if (deviatedFromRoute)
        _routeDirectionColor = [UIColor colorNamed:ACColorNameNavArrowDistantColor];
    else if (turnImminent > 0)
        _routeDirectionColor = [UIColor colorNamed:ACColorNameNavArrowColor];
    else if (turnImminent == 0)
        _routeDirectionColor = [UIColor colorNamed:ACColorNameNavArrowImminentColor];
    else
        _routeDirectionColor = [UIColor colorNamed:ACColorNameNavArrowDistantColor];

    [self setNeedsDisplay];
}

- (BOOL) setTurnType:(std::shared_ptr<TurnType>)turnType
{
    if (turnType != _turnType)
    {
        _turnType = turnType;
        [OATurnPathHelper calcTurnPath:_pathForTurn outlay:_pathForTurnOutlay turnType:_turnType transform:CGAffineTransformIdentity center:&_centerText mini:_mini shortArrow:NO noOverlap:YES smallArrow:NO];
        [self setNeedsLayout];
        [self setNeedsDisplay];
        return true;
    }
    return false;
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);

    CGContextSetAllowsAntialiasing(context, true);
    //CGContextSetLineWidth(context, 2.5f);
    CGContextSetStrokeColorWithColor(context, [UIColor colorNamed:ACColorNameNavArrowStrokeColor].CGColor);

    if (_pathForTurnOutlayForDrawing)
    {
        CGContextSetFillColorWithColor(context, [UIColor colorNamed:ACColorNameNavArrowCircleColor].CGColor);
        [_pathForTurnOutlayForDrawing fill];
        [_pathForTurnOutlayForDrawing stroke];
    }

    CGContextSetFillColorWithColor(context, _routeDirectionColor.CGColor);
    //CGContextTranslateCTM(aRef, 50, 50);
    if (_pathForTurnForDrawing)
    {
        [_pathForTurnForDrawing fill];
        [_pathForTurnForDrawing stroke];
    }

    if (_turnType && !_mini && _turnType->getExitOut() > 0)
    {
        NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
        //NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        //paragraphStyle.alignment = NSTextAlignmentCenter;
        //attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        attributes[NSForegroundColorAttributeName] = _textColor;
        attributes[NSFontAttributeName] = _textFont;
        
        NSString *text = [NSString stringWithFormat:@"%d", _turnType->getExitOut()];
        CGSize size = [OAUtilities calculateTextBounds:text width:500 font:_textFont];
        CGPoint p = CGPointMake(self.centerText.x - size.width / 2, self.centerText.y - size.height / 2 + 1);
        [text drawAtPoint:p withAttributes:attributes];
    }
}

@end
