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
#import "OAColors.h"

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
        _leftSide = [OADrivingRegion isLeftHandDriving:[OAAppSettings sharedManager].drivingRegion];
        _routeDirectionColor = UIColorFromRGB(color_nav_arrow);
        _secondTurnColor = UIColorFromRGB(color_nav_arrow_distant);
        
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
    float w = 0;
    int h = 0;
    float coef = _scaleCoefficient / _miniCoeff;
    if (!_lanes.empty())
    {
        for (int i = 0; i < _lanes.size(); i++)
        {
            int turnType = TurnType::getPrimaryTurn(_lanes[i]);
            int secondTurnType = TurnType::getSecondaryTurn(_lanes[i]);
            int thirdTurnType = TurnType::getTertiaryTurn(_lanes[i]);
            UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:FIRST_TURN coef:coef leftSide:_leftSide];
            if (p)
            {
                CGRect b = p.bounds;
                if (secondTurnType == 0 && thirdTurnType == 0)
                {
                    w += b.size.width;
                }
                else
                {
                    w += b.size.width;
                }
                int imageHeight = b.size.height;
                if (imageHeight > h)
                    h = imageHeight;
            }
        }
    }
    _width = (int) w;
    _height = h;
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetFillColorWithColor(context, _routeDirectionColor.CGColor);
            
    //to change color immediately when needed
    if (!_lanes.empty())
    {
        CGContextSaveGState(context);
        // canvas.translate((int) (16 * scaleCoefficient), 0);
        for (int i = 0; i < _lanes.size(); i++)
        {
            if ((_lanes[i] & 1) == 1)
                _routeDirectionColor = _imminent ? UIColorFromRGB(color_nav_arrow_imminent) : UIColorFromRGB(color_nav_arrow);
            else
                _routeDirectionColor = UIColorFromRGB(color_nav_arrow_distant);

            int turnType = TurnType::getPrimaryTurn(_lanes[i]);
            int secondTurnType = TurnType::getSecondaryTurn(_lanes[i]);
            int thirdTurnType = TurnType::getTertiaryTurn(_lanes[i]);
            
            float coef = _scaleCoefficient / _miniCoeff;
            if (thirdTurnType > 0)
            {
                UIBezierPath *bSecond = [UIBezierPath bezierPath];
                bSecond = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:THIRD_TURN coef:coef leftSide:_leftSide];
                if (!bSecond.empty)
                {
                    CGContextSetFillColorWithColor(context, _secondTurnColor.CGColor);
                    [bSecond fill];
                    [bSecond stroke];
                }
            }
            if (secondTurnType > 0)
            {
                UIBezierPath *bSecond = [UIBezierPath bezierPath];
                bSecond = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:SECOND_TURN coef:coef leftSide:_leftSide];
                if (!bSecond.empty)
                {
                    CGContextSetFillColorWithColor(context, _secondTurnColor.CGColor);
                    [bSecond fill];
                    [bSecond stroke];
                }
            }
            UIBezierPath *p = [OATurnPathHelper getPathFromTurnType:_pathsCache firstTurn:turnType secondTurn:secondTurnType thirdTurn:thirdTurnType turnIndex:FIRST_TURN coef:coef leftSide:_leftSide];
            if (!p.empty)
            {
                CGContextSetFillColorWithColor(context, _routeDirectionColor.CGColor);
                [p fill];
                [p stroke];
                CGContextTranslateCTM(context, p.bounds.size.width, 0);
            }
        }
        CGContextRestoreGState(context);
    }
}


@end
