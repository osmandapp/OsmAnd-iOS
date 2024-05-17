//
//  OAZoom.h
//  OsmAnd
//
//  Created by Max Kojin on 15/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAZoom : NSObject

- (instancetype) initWitZoom:(float)zoom minZoom:(int)minZoom maxZoom:(int)maxZoom;
- (instancetype) initWithBaseZoom:(int)baseZoom zoomFloatPart:(float)zoomFloatPart minZoom:(int)minZoom maxZoom:(int)maxZoom;

- (int) getBaseZoom;
- (float) getZoomFloatPart;
- (float) getZoomAnimation;
- (BOOL) isZoomInAllowed;
- (BOOL) isZoomOutAllowed;

- (void) zoomIn;
- (void) zoomOut;
- (void) changeZoom:(int)step;

- (void) calculateAnimatedZoom:(int)currentBaseZoom deltaZoom:(float)deltaZoom;

+ (OAZoom *) checkZoomBoundsWithZoom:(float)zoom minZoom:(int)minZoom maxZoom:(int)maxZoom;
+ (OAZoom *) checkZoomBoundsWithBaseZoom:(int)baseZoom floatZoomPart:(float)floatZoomPart minZoom:(int)minZoom maxZoom:(int)maxZoom;

+ (float) getDistanceAfterZoom:(float)distance startZoom:(float)startZoom endZoom:(float)endZoom;
+ (float) fromDistanceRatio:(double)startDistance endDistance:(double)endDistance startZoom:(float)startZoom;

+ (float) floatPartToVisual:(float)zoomFloatPart;
+ (float) visualToFloatPart:(float)visualZoom;

@end


@interface OAComplexZoom : NSObject

@property (nonatomic) int base;
@property (nonatomic) float floatPart;

- (instancetype) initWithZoom:(float)zoom;
- (instancetype) initWithBase:(int)base floatPart:(float)floatPart;

- (float) fullZoom;
+ (OAComplexZoom *) fromPreferredBase:(float)zoom preferredZoomBase:(int)preferredZoomBase;

@end
