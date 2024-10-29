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
    float _zoomAnimation;
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
        _minZoom = MAX([self.class getMinValidZoom], minZoom);
        _maxZoom = maxZoom;
    }
    return self;
}

- (instancetype) initWitZoom:(float)zoom minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    int baseZoom = floor(zoom);
    float zoomFloatPart = zoom - baseZoom;
    return [self initWithBaseZoom:baseZoom zoomFloatPart:zoomFloatPart minZoom:minZoom maxZoom:maxZoom];
}

- (int) getBaseZoom
{
    return _baseZoom;
}

- (float) getZoomFloatPart
{
    return _zoomFloatPart;
}

- (float) getZoomAnimation
{
    return _zoomAnimation;
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
    while (_zoomFloatPart + deltaZoom >= 0.5 && _baseZoom + 1 <= _maxZoom)
    {
        deltaZoom--;
        _baseZoom++;
    }
    
    while (_zoomFloatPart + deltaZoom < -0.5 && _baseZoom - 1 >= _minZoom)
    {
        deltaZoom++;
        _baseZoom--;
    }
    
    // Extend zoom float part from [-0.5 ... +0.5) to [-0.6 ... +0.6)
    // Example: previous zoom was 15 + 0.3f. With deltaZoom = 0.25f,
    // zoom will become 15 + 0.55f, not 16 - 0.45f
    if (_baseZoom + 1 == currentBaseZoom && _zoomFloatPart + deltaZoom >= 0.4f)
    {
        _baseZoom++;
        float invertedZoomFloatPart = (_zoomFloatPart + deltaZoom) - 1.0f;
        deltaZoom = invertedZoomFloatPart - _zoomFloatPart;
    }
    else if (_baseZoom - 1 == currentBaseZoom && _zoomFloatPart + deltaZoom < -0.4f)
    {
        _baseZoom--;
        float invertedZoomFloatPart = 1.0f + (_zoomFloatPart + deltaZoom);
        deltaZoom = invertedZoomFloatPart - _zoomFloatPart;
    }

    BOOL zoomInOverflow = _baseZoom == _maxZoom && _zoomFloatPart + deltaZoom > 0;
    BOOL zoomOutOverflow = _baseZoom == _minZoom && _zoomFloatPart + deltaZoom < 0;
    if (zoomInOverflow || zoomOutOverflow)
    {
        deltaZoom = -_zoomFloatPart;
    }

    _zoomAnimation = deltaZoom;
}

- (void) checkZoomBounds
{
    if (_baseZoom == _maxZoom)
    {
        _zoomFloatPart = MIN(0, _zoomFloatPart);
    }
    else if (_baseZoom > _maxZoom) 
    {
        _baseZoom = _maxZoom;
        _zoomFloatPart = 0;
    }

    if (_baseZoom == _minZoom)
    {
        _zoomFloatPart = MAX(0, _zoomFloatPart);
    }
    else if (_baseZoom < _minZoom)
    {
        _baseZoom = _minZoom;
        _zoomFloatPart = 0;
    }
}

+ (OAZoom *) checkZoomBoundsWithZoom:(float)zoom minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    return [self.class checkZoomBoundsWithBaseZoom:((int)zoom) floatZoomPart:zoom - ((int)zoom) minZoom:minZoom maxZoom:maxZoom];
}

+ (OAZoom *) checkZoomBoundsWithBaseZoom:(int)baseZoom floatZoomPart:(float)floatZoomPart minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    OAZoom *zoom = [[OAZoom alloc] initWithBaseZoom:baseZoom zoomFloatPart:floatZoomPart minZoom:minZoom maxZoom:maxZoom];
    [zoom checkZoomBounds];
    return zoom;
}

// Example: getDistanceAfterZoom(100, 10, 11) == 50
+ (float) getDistanceAfterZoom:(float)distance startZoom:(float)startZoom endZoom:(float)endZoom
{
    int startZoomBase = ((int) startZoom);
    float startZoomFloatPart = startZoom - startZoomBase;
    
    float distanceNoStartZoomFloatPart = distance * [self.class floatPartToVisual:startZoomFloatPart];
    
    float zoomDeltaFromStartZoomBase = endZoom - startZoomBase;
    float zoomFactorFromStartIntZoom = (1 << ((int) ABS(zoomDeltaFromStartZoomBase))) * (ABS(zoomDeltaFromStartZoomBase - ((int) zoomDeltaFromStartZoomBase)) + 1.0);
    
    if (zoomDeltaFromStartZoomBase < 0.0)
    {
        zoomFactorFromStartIntZoom = 1.0 / zoomFactorFromStartIntZoom;
    }
    
    return distanceNoStartZoomFloatPart / zoomFactorFromStartIntZoom;
}

// Example: fromDistanceRatio(100, 200, 15.5f) == 14.5f
+ (float) fromDistanceRatio:(double)startDistance endDistance:(double)endDistance startZoom:(float)startZoom
{
    int startIntZoom = ((int) startZoom);
    float startZoomFloatPart = startZoom - startIntZoom;
    double startDistanceIntZoom = startDistance * [self.class floatPartToVisual:startZoomFloatPart];
    double log2 = log(startDistanceIntZoom / endDistance) / log(2);
    int intZoomDelta = (int) log2;
    double startDistanceIntZoomed = intZoomDelta >= 0
        ? startDistanceIntZoom / (1 << intZoomDelta)
        : startDistanceIntZoom * (1 << -intZoomDelta);
    float zoomFloatPartDelta = [self visualToFloatPart:((float) (startDistanceIntZoomed / endDistance))];
    return startIntZoom + intZoomDelta + zoomFloatPartDelta;
}

+ (float) floatPartToVisual:(float)zoomFloatPart
{
    return zoomFloatPart >= 0
        ? 1.0 + zoomFloatPart
        : 1.0 + zoomFloatPart / 2.0;
}

+ (float) visualToFloatPart:(float)visualZoom
{
    return visualZoom >= 1.0
        ? visualZoom - 1.0
        : (visualZoom - 1.0) * 2.0;
}

+ (int) getMinValidZoom
{
    return MAX(ceil(log(ceil([OAUtilities calculateScreenHeight] / 256))), 1);
}

- (float) getValidZoomStep:(float)step
{
    float newZoomStep = step;
    float currentZoom = [self getBaseZoom] + [self getZoomFloatPart];
    float nextZoom = currentZoom + step;
    float minZoom = [OAZoom getMinValidZoom];
    
    if (nextZoom < minZoom)
        newZoomStep = - (currentZoom - minZoom);
    return newZoomStep;
}

@end



@implementation OAComplexZoom

- (instancetype) initWithZoom:(float)zoom
{
    return [[OAComplexZoom alloc] initWithBase:round(zoom) floatPart:zoom - round(zoom)];
}

- (instancetype) initWithBase:(int)base floatPart:(float)floatPart
{
    self = [super init];
    if (self)
    {
        _base = base;
        _floatPart = floatPart;
    }
    return self;
}

- (float) fullZoom
{
    return _base + _floatPart;
}

+ (OAComplexZoom *) fromPreferredBase:(float)zoom preferredZoomBase:(int)preferredZoomBase
{
    float floatPart = zoom - ((int) zoom);
    if (floatPart >= 0.4 && ((int) zoom) + 1 == preferredZoomBase)
    {
        return [[OAComplexZoom alloc] initWithBase:preferredZoomBase floatPart:zoom - preferredZoomBase];
    }
    else if (floatPart < 0.6 && ((int) zoom) == preferredZoomBase)
    {
        return [[OAComplexZoom alloc] initWithBase:preferredZoomBase floatPart:zoom - preferredZoomBase];
    } 
    else
    {
        return [[OAComplexZoom alloc] initWithZoom:zoom];
    }
}

@end
