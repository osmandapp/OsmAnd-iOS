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

- (void)createContext;
- (void)releaseContext;

@property(readonly) BOOL isRenderingSuspended;
- (BOOL)suspendRendering;
- (BOOL)resumeRendering;

@property(nonatomic) BOOL forcedRenderingOnEachFrame;
@property(readonly) OAObservable* settingsObservable;

@property(nonatomic) float fieldOfView;
@property(nonatomic) float azimuth;
@property(nonatomic) float elevationAngle;
@property(nonatomic) float zoom;
@property(nonatomic, readonly) float scaledTileSizeOnScreen;
@property(readonly) OAObservable* stateObservable;

@property(nonatomic, readonly) float minZoom;
@property(nonatomic, readonly) float maxZoom;

@end
