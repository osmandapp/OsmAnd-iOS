//
//  OAAutoZoomBySpeedHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 14/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

const static float kZoomPerSecond = 0.1;
const static float kZoomPerMillis = kZoomPerSecond / 1000.0;
const static int kZoomDurationMillis = 1500;

@class OAZoom, OAComplexZoom, OAMapRendererView, OANextDirectionInfo;


@interface OAAutoZoomDTO : NSObject

@property (nonatomic) OAComplexZoom *zoomValue;
@property (nonatomic) float floatValue;
- (instancetype) initWithZoom:(OAComplexZoom *)zoomValue floatValue:(float)floatValue;

@end


@interface OAAutoZoomBySpeedHelper : NSObject

- (double) calculateAutoZoomBySpeedV1:(float)speed mapView:(OAMapRendererView *)mapView;

- (OAComplexZoom *) calculateZoomBySpeedToAnimate:(OAMapRendererView *)mapRenderer myLocation:(CLLocation *)myLocation rotationToAnimate:(float)rotationToAnimate nextTurn:(OANextDirectionInfo *)nextTurn;

- (OAAutoZoomDTO *) getAnimatedZoomParamsForChart:(OAMapRendererView *)mapRenderer currentZoom:(float)currentZoom lat:(double)lat lon:(double)lon heading:(float)heading speed:(float)speed;

- (OAComplexZoom *) calculateRawZoomBySpeedForChart:(OAMapRendererView *)mapRenderer currentZoom:(float)currentZoom lat:(double)lat lon:(double)lon rotation:(float)rotation speed:(float)speed;

- (OAAutoZoomDTO *) getAutoZoomParams:(float)currentZoom autoZoom:(OAComplexZoom *)autoZoom fixedDurationMillis:(float)fixedDurationMillis;

@end
