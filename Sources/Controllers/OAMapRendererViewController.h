//
//  OAMapRendererController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAObservable.h"

@interface OAMapRendererViewController : UIViewController <UIGestureRecognizerDelegate>

+ (OAMapRendererViewController*)instance;

@property(readonly) OAObservable* azimuthObservable;
- (void)animatedAlignAzimuthToNorth;

@property(readonly) OAObservable* zoomObservable;
- (BOOL)canZoomIn;
- (void)animatedZoomIn;
- (BOOL)canZoomOut;
- (void)animatedZoomOut;

- (void)activateMapnik;
- (void)activateCyclemap;
- (void)activateOffline;

@end
