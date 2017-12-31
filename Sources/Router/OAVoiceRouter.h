//
//  OAVoiceRouter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OARoutingHelper, OALocationPointWrapper, OAAlarmInfo;

@protocol OACommandPlayer;

@interface OAVoiceRouter : NSObject

@property (nonatomic, readonly) float DEFAULT_SPEED;
@property (nonatomic, readonly) float TURN_DEFAULT_SPEED;

@property (nonatomic, readonly) int PREPARE_LONG_DISTANCE;
@property (nonatomic, readonly) int PREPARE_LONG_DISTANCE_END;
@property (nonatomic, readonly) int PREPARE_DISTANCE;
@property (nonatomic, readonly) int PREPARE_DISTANCE_END;
@property (nonatomic, readonly) int TURN_IN_DISTANCE;
@property (nonatomic, readonly) int TURN_IN_DISTANCE_END;
@property (nonatomic, readonly) int TURN_DISTANCE;

- (instancetype)initWithHelper:(OARoutingHelper *)router;

- (void) setPlayer:(id<OACommandPlayer>)player;

- (id<OACommandPlayer>) getPlayer;
- (void) updateAppMode;
- (void) setMute:(BOOL)mute;
- (BOOL) isMute;

- (void) arrivedIntermediatePoint:(NSString *)name;
- (void) arrivedDestinationPoint:(NSString *)name;
- (void) updateStatus:(CLLocation *)currentLocation repeat:(BOOL)repeat;
- (void) interruptRouteCommands;
- (void) announceOffRoute:(double)dist;
- (void) newRouteIsCalculated:(BOOL)newRoute;
- (void) announceBackOnRoute;
- (void) announceCurrentDirection:(CLLocation *)currentLocation;
- (int) calculateImminent:(float)dist loc:(CLLocation *)loc;
- (BOOL) isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon defSpeed:(float)defSpeed;
- (void) gpsLocationLost;
- (void) gpsLocationRecover;

- (void) announceAlarm:(OAAlarmInfo *)info speed:(float)speed;
- (void) announceSpeedAlarm:(int)maxSpeed speed:(float)speed;
- (void) approachWaypoint:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points;
- (void) approachFavorite:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points;
- (void) approachPoi:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points;
- (void) announceWaypoint:(NSArray<OALocationPointWrapper *> *)points;
- (void) announceFavorite:(NSArray<OALocationPointWrapper *> *)points;
- (void) announcePoi:(NSArray<OALocationPointWrapper *> *)points;

- (void) notifyOnVoiceMessage;

@end
