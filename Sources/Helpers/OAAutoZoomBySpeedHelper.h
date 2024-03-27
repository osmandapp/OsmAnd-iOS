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

@property (nonatomic, nonnull) OAComplexZoom *zoomValue;
@property (nonatomic) float durationValue;
- (instancetype _Nonnull) initWithZoom:(OAComplexZoom *_Nonnull)zoomValue durationValue:(float)durationValue;

@end


@interface OAAutoZoomBySpeedHelper : NSObject

- (OAComplexZoom *_Nullable) calculateZoomBySpeedToAnimate:(OAMapRendererView *_Nonnull)mapRenderer myLocation:(CLLocation *_Nonnull)myLocation rotationToAnimate:(float)rotationToAnimate nextTurn:(OANextDirectionInfo *_Nonnull)nextTurn;

- (OAAutoZoomDTO *_Nullable) getAnimatedZoomParamsForChart:(OAMapRendererView *_Nonnull)mapRenderer currentZoom:(float)currentZoom lat:(double)lat lon:(double)lon heading:(float)heading speed:(float)speed;

- (OAComplexZoom *_Nullable) calculateRawZoomBySpeedForChart:(OAMapRendererView *_Nonnull)mapRenderer currentZoom:(float)currentZoom lat:(double)lat lon:(double)lon rotation:(float)rotation speed:(float)speed;

- (OAAutoZoomDTO *_Nullable) getAutoZoomParams:(float)currentZoom autoZoom:(OAComplexZoom *_Nonnull)autoZoom fixedDurationMillis:(float)fixedDurationMillis;

- (void) onManualZoomChange;

@end
