//
//  OAApplicationMode.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OANavigationIcon.h"
#import "OALocationIcon.h"

@class OAApplicationModeBuilder;

@interface OAApplicationModeBean : NSObject

@property (nonatomic) NSString *stringKey;
@property (nonatomic) NSString *userProfileName;
@property (nonatomic) NSString *parent;
@property (nonatomic) NSString *iconName;
@property (nonatomic) int iconColor;
@property (nonatomic) NSString *routingProfile;
@property (nonatomic) NSInteger routeService;
@property (nonatomic) EOALocationIcon locIcon;
@property (nonatomic) EOANavigationIcon navIcon;
@property (nonatomic) int order;

+ (OAApplicationModeBean *) fromJson:(NSDictionary *)jsonData;

@end

@interface OAApplicationMode : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *stringKey;
@property (nonatomic, readonly) NSString *variantKey;

@property (nonatomic) NSString *descr;
@property (nonatomic) CGFloat baseMinSpeed;
@property (nonatomic) CGFloat baseMaxSpeed;

@property (nonatomic, readonly) OAApplicationMode *parent;

+ (OAApplicationModeBuilder *) fromModeBean:(OAApplicationModeBean *)modeBean;

+ (OAApplicationMode *) DEFAULT;
+ (OAApplicationMode *) CAR;
+ (OAApplicationMode *) BICYCLE;
+ (OAApplicationMode *) PEDESTRIAN;
+ (OAApplicationMode *) AIRCRAFT;
+ (OAApplicationMode *) BOAT;
+ (OAApplicationMode *) PUBLIC_TRANSPORT;
+ (OAApplicationMode *) SKI;
+ (OAApplicationMode *) CARPLAY;

+ (NSArray<OAApplicationMode *> *) values;
+ (NSArray<OAApplicationMode *> *) allPossibleValues;
+ (NSArray<OAApplicationMode *> *) getModesDerivedFrom:(OAApplicationMode *)am;
+ (OAApplicationMode *) valueOfStringKey:(NSString *)key def:(OAApplicationMode *)def;

+ (void) onApplicationStart;
+ (OAApplicationMode *) saveProfile:(OAApplicationModeBuilder *)appMode;
+ (void) changeProfileAvailability:(OAApplicationMode *) mode isSelected:(BOOL) isSelected;
+ (BOOL) isProfileNameAvailable:(NSString *)profileName;

- (instancetype)initWithName:(NSString *)name stringKey:(NSString *)stringKey;

- (NSDictionary *) toJson;

- (BOOL) hasFastSpeed;
- (BOOL) isDerivedRoutingFrom:(OAApplicationMode *)mode;

+ (NSSet<OAApplicationMode *> *) regWidgetVisibility:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am;
- (BOOL) isWidgetCollapsible:(NSString *)key;
- (BOOL) isWidgetVisible:(NSString *)key;

- (NSInteger) getOffRouteDistance;
- (NSInteger) getMinDistanceForTurn;
- (double) getDefaultSpeed;

- (NSString *) toHumanString;

- (void) setParent:(OAApplicationMode *)parent;
- (UIImage *) getIcon;
- (NSString *) getIconName;
- (void) setIconName:(NSString *)iconName;
- (void) setDefaultSpeed:(double) defaultSpeed;
- (void) resetDefaultSpeed;
- (double) getMinSpeed;
- (void) setMinSpeed:(double) minSpeed;
- (double) getMaxSpeed;
- (void) setMaxSpeed:(double) maxSpeed;
- (double) getStrAngle;
- (void) setStrAngle:(double) straightAngle;
- (NSString *) getUserProfileName;
- (void) setUserProfileName:(NSString *)userProfileName;
- (void) setRoutingProfile:(NSString *) routingProfile;
- (NSInteger) getRouterService;
- (void) setRouterService:(NSInteger) routerService;
- (EOANavigationIcon) getNavigationIcon;
- (void) setNavigationIcon:(EOANavigationIcon) navIcon;
- (EOALocationIcon) getLocationIcon;
- (void) setLocationIcon:(EOALocationIcon) locIcon;
- (int) getIconColor;
- (void) setIconColor:(int)iconColor;
- (int) getOrder;
- (void) setOrder:(int)order;
- (NSString *) getRoutingProfile;
- (NSString *) getProfileDescription;

- (BOOL) isCustomProfile;

- (OAApplicationModeBean *) toModeBean;

+ (void) reorderAppModes;
+ (void) deleteCustomModes:(NSArray<OAApplicationMode *> *) modes;
+ (NSSet<OAApplicationMode *> *) regWidgetAvailability:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am;
- (BOOL) isWidgetAvailable:(NSString *)key;
+ (OAApplicationModeBuilder *) createBase:(NSString *) stringKey;
+ (OAApplicationModeBuilder *) createCustomMode:(OAApplicationMode *) parent stringKey:(NSString *) stringKey;

@end

@interface OAApplicationModeBuilder : NSObject

@property (nonatomic) OAApplicationMode *am;
@property (nonatomic) NSString *userProfileName;
@property (nonatomic) NSInteger routeService;
@property (nonatomic) NSString *routingProfile;
@property (nonatomic) NSString *iconResName;
@property (nonatomic) NSInteger iconColor;
@property (nonatomic) EOALocationIcon locationIcon;
@property (nonatomic) EOANavigationIcon navigationIcon;
@property (nonatomic) NSInteger order;

- (OAApplicationMode *) customReg;

@end
