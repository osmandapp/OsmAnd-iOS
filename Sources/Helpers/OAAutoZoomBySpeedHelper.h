//
//  OAAutoZoomBySpeedHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 14/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

const static float kZoomPerSecond = 0.1;
const static float kZoomPerMillis = kZoomPerSecond / 1000.0;
const static int kZoomDurationMillis = 1500;

@class OAZoom, OAComplexZoom, OAMapRendererView, OANextDirectionInfo;
@class CLLocation;

@interface OAAutoZoomDTO : NSObject

@property (nonatomic) OAComplexZoom *zoomValue;
@property (nonatomic) float durationValue;

- (instancetype)initWithZoom:(OAComplexZoom *)zoomValue durationValue:(float)durationValue;

@end

@interface OAAutoZoomBySpeedHelper : NSObject

- (OAComplexZoom * _Nullable)calculateZoomBySpeedToAnimate:(OAMapRendererView *)mapRenderer
                                                myLocation:(CLLocation *)myLocation
                                         rotationToAnimate:(float)rotationToAnimate
                                                  nextTurn:(OANextDirectionInfo *)nextTurn;

- (OAAutoZoomDTO * _Nullable)getAnimatedZoomParamsForChart:(OAMapRendererView *)mapRenderer
                                               currentZoom:(float)currentZoom
                                                       lat:(double)lat
                                                       lon:(double)lon
                                                   heading:(float)heading
                                                     speed:(float)speed;

- (OAComplexZoom * _Nullable)calculateRawZoomBySpeedForChart:(OAMapRendererView *)mapRenderer
                                                 currentZoom:(float)currentZoom
                                                         lat:(double)lat
                                                         lon:(double)lon
                                                    rotation:(float)rotation
                                                       speed:(float)speed;

- (OAAutoZoomDTO * _Nullable)getAutoZoomParams:(float)currentZoom
                                      autoZoom:(OAComplexZoom *)autoZoom
                           fixedDurationMillis:(float)fixedDurationMillis;

- (void)onManualZoomChange;

@end

NS_ASSUME_NONNULL_END
