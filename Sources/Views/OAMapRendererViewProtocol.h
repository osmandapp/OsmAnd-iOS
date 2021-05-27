//
//  OAMapRendererViewProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

@protocol OAMapRendererViewProtocol <NSObject>

// Context-related:
- (void)createContext;
- (void)releaseContext;

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
@property(nonatomic, readonly) float currentTileSizeOnScreenInPixels;
@property(nonatomic, readonly) float currentTileSizeOnScreenMeters;
@property(readonly) OAObservable* stateObservable;

// Misc properties:
@property(nonatomic, readonly) float minZoom;
@property(nonatomic, readonly) float maxZoom;
@property CGFloat referenceTileSizeOnScreenInPixels;

@property(readonly) OAObservable* framePreparedObservable;

// Utilities:
- (void)dumpResourcesInfo;

@end
