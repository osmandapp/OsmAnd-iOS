//
//  OAMapRendererViewProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAObservable;

@protocol OAMapRendererViewProtocol <NSObject>

// Context-related:
- (void)createContext;
- (void)releaseContext:(BOOL)gpuContextLost;

// Rendering process:
@property(readonly) BOOL isRenderingSuspended;
- (BOOL)suspendRendering;
- (BOOL)resumeRendering;

// Settings-related:
@property(readonly) OAObservable* settingsObservable;

// State-related:
@property(nonatomic) float fieldOfView;
@property(nonatomic) float azimuth;
@property(nonatomic) float elevationAngle;
@property(nonatomic) float zoom;
@property(nonatomic) float flatZoom;
@property(nonatomic, readonly) float tileSizeOnScreenInPixels;
@property(nonatomic, readonly) float tileSizeOnScreenInMeters;
@property(readonly) OAObservable* stateObservable;

// Misc properties:
@property(nonatomic, readonly) float minZoom;
@property(nonatomic, readonly) float maxZoom;
@property CGFloat referenceTileSizeOnScreenInPixels;

@property(readonly) OAObservable* framePreparedObservable;

- (double) normalizeElevationAngle:(double)elevationAngle;

// Utilities:
- (void) dumpResourcesInfo;

@end
