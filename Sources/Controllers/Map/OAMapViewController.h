//
//  OAMapViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OACommonTypes.h"
#import "OAMapRendererViewProtocol.h"
#import "OAObservable.h"

@interface OAMapViewController : UIViewController <UIGestureRecognizerDelegate>

@property(weak, readonly) id<OAMapRendererViewProtocol> mapRendererView;
@property(readonly) OAObservable* stateObservable;
@property(readonly) OAObservable* settingsObservable;

@property(readonly) OAObservable* azimuthObservable;
- (void)animatedAlignAzimuthToNorth;

@property(readonly) OAObservable* zoomObservable;
- (BOOL)canZoomIn;
- (void)animatedZoomIn;
- (BOOL)canZoomOut;
- (void)animatedZoomOut;

- (void)goToPosition:(Point31)position31
            animated:(BOOL)animated;
- (void)goToPosition:(Point31)position31
             andZoom:(CGFloat)zoom
            animated:(BOOL)animated;

@end
