//
//  OAZoom.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 15/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAZoom.h"

@implementation OAZoom
{
    int _baseZoom;
    float _zoomFloatPart;
    int _minZoom;
    int _maxZoom;
}

- (instancetype) initWithBaseZoom:(int)baseZoom zoomFloatPart:(float)zoomFloatPart minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    self = [super init];
    if (self)
    {
        _baseZoom = baseZoom;
        _zoomFloatPart = zoomFloatPart;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
    }
    return self;
}

- (int) getBaseZoom
{
    return _baseZoom;
}

- (int) getZoomFloatPart
{
    return _zoomFloatPart;
}

- (BOOL) isZoomInAllowed
{
    return _baseZoom < _maxZoom || (_baseZoom == _maxZoom && _zoomFloatPart < 0);
}

- (BOOL) isZoomOutAllowed
{
    return _baseZoom > _minZoom || (_baseZoom == _minZoom && _zoomFloatPart > 0);
}

- (void) zoomIn
{
    [self changeZoom:1];
}
- (void) zoomOut
{
    [self changeZoom:-1];
}

- (void) changeZoom:(int)step
{
    _baseZoom += step;
    [self checkZoomBounds];
}

- (void) calculateAnimatedZoom:(int)currentBaseZoom deltaZoom:(float)deltaZoom
{
    //TODO implement ?
}

- (void) checkZoomBounds
{
    //TODO implement
}

+ (void) checkZoomBoundsWithZoom:(float)zoom minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    //TODO implement
}

+ (void) checkZoomBoundsWithBaseZoom:(int)baseZoom floatZoomPart:(float)floatZoomPart minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    //TODO implement
}

+ (float) getDistanceAfterZoom:(float)distance startZoom:(float)startZoom endZoom:(float)endZoom
{
    //TODO implement
    return 0;
}

+ (float) fromDistanceRatio:(double)startDistance endDistance:(double)endDistance startZoom:(float)startZoom
{
    //TODO implement
    return 0;
}

+ (float) floatPartToVisual:(float)zoomFloatPart
{
    //TODO implement
    return 0;
}

+ (float) visualToFloatPart:(float)visualZoom
{
    //TODO implement
    return 0;
}

@end



@implementation OAComplexZoom

@end
