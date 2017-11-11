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

#define IMG_BORDER 2.0
#define IMG_MIN_WIDTH 14.0

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
    float coef = _scaleCoefficient / _miniCoeff;
    if (!_lanes.empty())
    {
        for (int i = 0; i < _lanes.size(); i++)
        {
            int turnType = TurnType::getPrimaryTurn(_lanes[i]);
            int secondTurnType = TurnType::getSecondaryTurn(_lanes[i]);
            int thirdTurnType = TurnType::getTertiaryTurn(_lanes[i]);
            
            CGRect imgBounds = CGRectZero;
            
            float coef = _scaleCoefficient / _miniCoeff;
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
                if (imgBounds.size.width < IMG_MIN_WIDTH)
                    imgBounds = CGRectInset(imgBounds, -(IMG_MIN_WIDTH - imgBounds.size.width) / 2.f, 0);
                
                w += imgBounds.size.width + (i < _lanes.size() - 1 ? IMG_BORDER * 2 : 0);

                float imageHeight = imgBounds.origin.y + imgBounds.size.height;
                if (imageHeight > h)
                    h = imageHeight;
            }
        }
        if (w > 0)
            w += 4.0;
        if (h > 0)
            h += 4.0;
    }
    _width = w;
    _height = h;
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    //CGContextSetFillColorWithColor(context, _routeDirectionColor.CGColor);
    
    //CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    //CGContextFillRect(context, self.bounds);
    
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
            
            CGRect imgBounds = CGRectZero;
            UIBezierPath *thirdTurnPath;
            UIBezierPath *secondTurnPath;
            UIBezierPath *firstTurnPath;
            
            float coef = _scaleCoefficient / _miniCoeff;
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
                if (imgBounds.size.width < IMG_MIN_WIDTH)
                    imgBounds = CGRectInset(imgBounds, -(IMG_MIN_WIDTH - imgBounds.size.width) / 2.f, 0);

                if (i == 0)
                    imgBounds = CGRectMake(imgBounds.origin.x - 2, imgBounds.origin.y, imgBounds.size.width + 2 + IMG_BORDER, imgBounds.size.height);
                else
                    imgBounds = CGRectInset(imgBounds, -IMG_BORDER, 0);

                CGContextTranslateCTM(context, -imgBounds.origin.x, 0);
                if (thirdTurnPath)
                {
                    CGContextSetFillColorWithColor(context, _secondTurnColor.CGColor);
                    [thirdTurnPath fill];
                    [thirdTurnPath stroke];
                }
                if (secondTurnPath)
                {
                    CGContextSetFillColorWithColor(context, _secondTurnColor.CGColor);
                    [secondTurnPath fill];
                    [secondTurnPath stroke];
                }
                if (firstTurnPath)
                {
                    CGContextSetFillColorWithColor(context, _routeDirectionColor.CGColor);
                    [firstTurnPath fill];
                    [firstTurnPath stroke];
                }
                CGContextTranslateCTM(context, imgBounds.size.width + imgBounds.origin.x, 0);
            }
        }
        CGContextRestoreGState(context);
    }
}


@end
