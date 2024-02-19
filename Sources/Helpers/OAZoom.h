//
//  OAZoom.h
//  OsmAnd
//
//  Created by Max Kojin on 15/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAZoom : NSObject

- (int) getBaseZoom;
- (int) getZoomFloatPart;
- (BOOL) isZoomInAllowed;

- (void) zoomIn;
- (void) zoomOut;
- (void) changeZoom:(int)step;

- (void) calculateAnimatedZoom:(int)currentBaseZoom deltaZoom:(float)deltaZoom;

+ (void) checkZoomBoundsWithZoom:(float)zoom minZoom:(int)minZoom maxZoom:(int)maxZoom;
+ (void) checkZoomBoundsWithBaseZoom:(int)baseZoom floatZoomPart:(float)floatZoomPart minZoom:(int)minZoom maxZoom:(int)maxZoom;

+ (float) getDistanceAfterZoom:(float)distance startZoom:(float)startZoom endZoom:(float)endZoom;
+ (float) fromDistanceRatio:(double)startDistance endDistance:(double)endDistance startZoom:(float)startZoom;

+ (float) floatPartToVisual:(float)zoomFloatPart;
+ (float) visualToFloatPart:(float)visualZoom;

@end


@interface OAComplexZoom : NSObject

@end
