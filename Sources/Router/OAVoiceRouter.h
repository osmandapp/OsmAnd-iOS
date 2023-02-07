//
//  OAVoiceRouter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
// Android version: 1eda59acc7a35cb9cd3bc7c30561fbce7bf396d2

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OARoutingHelper, OALocationPointWrapper, OAAlarmInfo, OAApplicationMode, OAAnnounceTimeDistances, OARouteDirectionInfo;

@protocol OACommandPlayer;

@interface OAVoiceRouter : NSObject

- (instancetype)initWithHelper:(OARoutingHelper *)router;

- (void) setPlayer:(id<OACommandPlayer>)player;

- (id<OACommandPlayer>) getPlayer;
- (void) updateAppMode;
- (void) setMute:(BOOL)mute;
- (void) setMute:(BOOL)mute mode:(OAApplicationMode *)mode;
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
- (BOOL) isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon;
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

- (OAAnnounceTimeDistances *)getAnnounceTimeDistances;
- (OARouteDirectionInfo *)getNextRouteDirection;

@end
