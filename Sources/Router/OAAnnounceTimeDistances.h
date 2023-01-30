//
//  OAAnnounceTimeDistances.h
//  OsmAnd
//
//  Created by Skalii on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kStateTurnNow 0
#define kStateTurnIn 1
#define kStatePrepareTurn 2
#define kStateLongPrepareTurn 3
#define kStateShortAlarmAnnounce 4
#define kStateLongAlarmAnnounce 5
#define kStateShortPntApproach 6
#define kStateLongPntApproach 7

@class OAApplicationMode;

@interface OAAnnounceTimeDistances : NSObject

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode;

- (void)setArrivalDistances:(float)arrivalDistanceFactor;
- (int)getImminentTurnStatus:(float)dist loc:(CLLocation *)loc;
- (BOOL)isTurnStateActive:(float)currentSpeed dist:(double)dist turnType:(int)turnType;
- (BOOL)isTurnStateNotPassed:(float)currentSpeed dist:(double)dist turnType:(int)turnType;
- (float)getSpeed:(CLLocation *)loc;
- (float)getOffRouteDistance;
- (int)calcDistanceWithoutDelay:(float)speed dist:(int)dist;
- (NSAttributedString *)getIntervalsDescription;

@end
