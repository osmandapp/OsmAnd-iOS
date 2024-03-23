//
//  OALanesDrawable.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALanesDrawable.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OATurnResource.h"
#import "OATurnPathHelper.h"
#import "OAUtilities.h"
#import "GeneratedAssetSymbols.h"

#define IMG_BORDER 2.0
#define IMG_MIN_DELTA 16.0

@implementation OALanesDrawable
{
    vector<int> _lanes;
    NSMapTable<OATurnResource *, UIBezierPath *> *_pathsCache;
    UIColor *_routeDirectionColor;
    UIColor *_secondTurnColor;
}

- (instancetype) initWithScaleCoefficient:(float)scaleCoefficient
{
    self = [super init];
    if (self)
    {
        _pathsCache = [NSMapTable strongToStrongObjectsMapTable];
        _imminent = NO;
        _scaleCoefficient = scaleCoefficient;
        _miniCoeff = 2.f;
        _leftSide = [OADrivingRegion isLeftHandDriving:[[OAAppSettings sharedManager].drivingRegion get]];
        _routeDirectionColor = [UIColor colorNamed:ACColorNameNavArrowColor];
        _secondTurnColor = [UIColor colorNamed:ACColorNameNavArrowDistantColor];
        
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (std::vector<int>&) getLanes
{
    return _lanes;
}

- (void) setLanes:(std::vector<int>)lanes
{
    _lanes = lanes;
}

- (void) updateBounds
{
    CGFloat w = 0;
    CGFloat h = 0;
    CGFloat delta = IMG_MIN_DELTA;
    float coef = _scaleCoefficient / _miniCoeff;
    if (!_lanes.empty())
    {
        NSMutableArray *boundsArr = [NSMutableArray arrayWithCapacity:_lanes.size()];
        for (int i = 0; i < _lanes.size(); i++)
        {
            int turnType = TurnType::getPrimaryTurn(_lanes[i]);
            int secondTurnType = TurnType::getSecondaryTurn(_lanes[i]);
            int thirdTurnType = TurnType::getTertiaryTurn(_lanes[i]);
            
            CGRect imgBounds = CGRectZero;
            
            if (thirdTurnType > 0)
            {
                UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:THIRD_TURN coef:coef leftSide:_leftSide smallArrow:YES];
                if (!p.empty)
                    imgBounds = CGRectIsEmpty(imgBounds) ? p.bounds : CGRectUnion(imgBounds, p.bounds);
            }
            if (secondTurnType > 0)
            {
                UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:SECOND_TURN coef:coef leftSide:_leftSide smallArrow:YES];
                if (!p.empty)
                    imgBounds = CGRectIsEmpty(imgBounds) ? p.bounds : CGRectUnion(imgBounds, p.bounds);
            }
            UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:FIRST_TURN coef:coef leftSide:_leftSide smallArrow:YES];
            if (!p.empty)
                imgBounds = CGRectIsEmpty(imgBounds) ? p.bounds : CGRectUnion(imgBounds, p.bounds);

            if (imgBounds.size.width > 0)
            {
                [boundsArr addObject:[NSValue valueWithCGRect:imgBounds]];
                
                CGFloat imageHeight = imgBounds.origin.y + imgBounds.size.height;
                if (imageHeight > h)
                    h = imageHeight;
            }
        }

        if (boundsArr.count > 1)
        {
            for (int i = 1; i < boundsArr.count; i++)
            {
                CGRect b1 = [boundsArr[i - 1] CGRectValue];
                CGRect b2 = [boundsArr[i] CGRectValue];
                CGFloat d = CGRectGetMaxX(b1) + IMG_BORDER * 2 - CGRectGetMinX(b2);
                if (delta < d)
                    delta = d;
            }
            CGRect b1 = [boundsArr[0] CGRectValue];
            CGRect b2 = [boundsArr[boundsArr.count - 1] CGRectValue];
            w = -CGRectGetMinX(b1) + (boundsArr.count - 1) * delta + CGRectGetMaxX(b2);
        }
        else if (boundsArr.count > 0)
        {
            CGRect b1 = [boundsArr[0] CGRectValue];
            w = b1.size.width;
        }
        
        if (w > 0)
            w += 4.0;
        if (h > 0)
            h += 4.0;
    }
    _width = w;
    _height = h;
    _delta = delta;
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetStrokeColorWithColor(context, [UIColor colorNamed:ACColorNameNavArrowStrokeColor].CGColor);

    //to change color immediately when needed
    if (!_lanes.empty())
    {
        float coef = _scaleCoefficient / _miniCoeff;
        CGContextSaveGState(context);
        // canvas.translate((int) (16 * scaleCoefficient), 0);
        for (int i = 0; i < _lanes.size(); i++)
        {
            if ((_lanes[i] & 1) == 1)
                _routeDirectionColor = _imminent ? [UIColor colorNamed:ACColorNameNavArrowImminentColor] : [UIColor colorNamed:ACColorNameNavArrowColor];
            else
                _routeDirectionColor = [UIColor colorNamed:ACColorNameNavArrowDistantColor];

            int turnType = TurnType::getPrimaryTurn(_lanes[i]);
            int secondTurnType = TurnType::getSecondaryTurn(_lanes[i]);
            int thirdTurnType = TurnType::getTertiaryTurn(_lanes[i]);

            CGRect imgBounds = CGRectZero;
            UIBezierPath *thirdTurnPath;
            UIBezierPath *secondTurnPath;
            UIBezierPath *firstTurnPath;
            
            if (thirdTurnType > 0)
            {
                UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:THIRD_TURN coef:coef leftSide:_leftSide smallArrow:YES];
                if (!p.empty)
                {
                    imgBounds = CGRectIsEmpty(imgBounds) ? p.bounds : CGRectUnion(imgBounds, p.bounds);
                    thirdTurnPath = p;
                }
            }
            if (secondTurnType > 0)
            {
                UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:SECOND_TURN coef:coef leftSide:_leftSide smallArrow:YES];
                if (!p.empty)
                {
                    imgBounds = CGRectIsEmpty(imgBounds) ? p.bounds : CGRectUnion(imgBounds, p.bounds);
                    secondTurnPath = p;
                }
            }
            UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:FIRST_TURN coef:coef leftSide:_leftSide smallArrow:YES];
            if (!p.empty)
            {
                imgBounds = CGRectIsEmpty(imgBounds) ? p.bounds : CGRectUnion(imgBounds, p.bounds);
                firstTurnPath = p;
            }
            
            if (thirdTurnPath || secondTurnPath || firstTurnPath)
            {
                if (i == 0)
                {
                    imgBounds = CGRectMake(imgBounds.origin.x - 2, imgBounds.origin.y, imgBounds.size.width + 2, imgBounds.size.height);
                    CGContextTranslateCTM(context, -imgBounds.origin.x, 0);
                }
                else
                {
                    CGContextTranslateCTM(context, -LANE_IMG_HALF_SIZE, 0);
                }

                // 1st pass
                CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                if (thirdTurnPath)
                {
                    //[thirdTurnPath fill];
                    [thirdTurnPath stroke];
                }
                if (secondTurnPath)
                {
                    //[secondTurnPath fill];
                    [secondTurnPath stroke];
                }
                if (firstTurnPath)
                {
                    //[firstTurnPath fill];
                    [firstTurnPath stroke];
                }

                // 2nd pass
                if (thirdTurnPath)
                {
                    CGContextSetFillColorWithColor(context, _secondTurnColor.CGColor);
                    [thirdTurnPath fill];
                }
                if (secondTurnPath)
                {
                    CGContextSetFillColorWithColor(context, _secondTurnColor.CGColor);
                    [secondTurnPath fill];
                }
                if (firstTurnPath)
                {
                    CGContextSetFillColorWithColor(context, _routeDirectionColor.CGColor);
                    [firstTurnPath fill];
                }
                CGContextTranslateCTM(context, LANE_IMG_HALF_SIZE + _delta, 0);
            }
        }
        CGContextRestoreGState(context);
    }
}


@end
