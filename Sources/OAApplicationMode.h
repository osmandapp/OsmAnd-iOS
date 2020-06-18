//
//  OAApplicationMode.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAApplicationMode : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *stringKey;
@property (nonatomic, readonly) NSString *variantKey;

@property (nonatomic) NSString *descr;

@property (nonatomic, readonly) OAApplicationMode *parent;

@property (nonatomic, readonly) float defaultSpeed;

@property (nonatomic, readonly) NSString *mapIcon;
@property (nonatomic, readonly) NSString *smallIconDark;
@property (nonatomic, readonly) NSString *bearingIconDay;
@property (nonatomic, readonly) NSString *bearingIconNight;
@property (nonatomic, readonly) NSString *headingIconDay;
@property (nonatomic, readonly) NSString *headingIconNight;
@property (nonatomic, readonly) NSString *locationIconDay;
@property (nonatomic, readonly) NSString *locationIconNight;
@property (nonatomic, readonly) NSString *locationIconDayLost;
@property (nonatomic, readonly) NSString *locationIconNightLost;

+ (OAApplicationMode *) DEFAULT;
+ (OAApplicationMode *) CAR;
+ (OAApplicationMode *) BICYCLE;
+ (OAApplicationMode *) PEDESTRIAN;
+ (OAApplicationMode *) AIRCRAFT;
+ (OAApplicationMode *) BOAT;
+ (OAApplicationMode *) PUBLIC_TRANSPORT;
+ (OAApplicationMode *) SKI;

+ (NSArray<OAApplicationMode *> *) values;
+ (NSArray<OAApplicationMode *> *) allPossibleValues;
+ (NSArray<OAApplicationMode *> *) getModesDerivedFrom:(OAApplicationMode *)am;
+ (OAApplicationMode *) valueOfStringKey:(NSString *)key def:(OAApplicationMode *)def;

- (BOOL) hasFastSpeed;
- (BOOL) isDerivedRoutingFrom:(OAApplicationMode *)mode;

+ (NSSet<OAApplicationMode *> *) regWidgetVisibility:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am;
- (BOOL) isWidgetCollapsible:(NSString *)key;
- (BOOL) isWidgetVisible:(NSString *)key;

- (NSInteger) getOffRouteDistance;
- (NSInteger) getMinDistanceForTurn;
- (NSInteger) getDefaultSpeed;

- (NSString *) getRoutingProfile;
- (void) setRoutingProfile:(NSString *) routingProfile;

+ (NSSet<OAApplicationMode *> *) regWidgetAvailability:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am;
- (BOOL) isWidgetAvailable:(NSString *)key;

@end
