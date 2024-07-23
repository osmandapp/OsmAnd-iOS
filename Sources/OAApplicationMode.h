//
//  OAApplicationMode.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationModeBuilder, OALocationIcon;

@interface OAApplicationModeBean : NSObject

@property (nonatomic) NSString *stringKey;
@property (nonatomic) NSString *userProfileName;
@property (nonatomic) NSString *parent;
@property (nonatomic) NSString *iconName;
@property (nonatomic) int iconColor;
@property (nonatomic) int customIconColor;
@property (nonatomic) NSString *derivedProfile;
@property (nonatomic) NSString *routingProfile;
@property (nonatomic) NSInteger routeService;
@property (nonatomic) NSString *locIcon;
@property (nonatomic) NSString *navIcon;
@property (nonatomic) int order;

+ (OAApplicationModeBean *) fromJson:(NSDictionary *)jsonData;
- (UIColor *) getProfileColor;

@end

@interface OAApplicationMode : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *stringKey;
@property (nonatomic, readonly) NSString *variantKey;

@property (nonatomic) NSString *descr;

@property (nonatomic, readonly) OAApplicationMode *parent;

+ (OAApplicationModeBuilder *) fromModeBean:(OAApplicationModeBean *)modeBean;

+ (OAApplicationMode *) DEFAULT;
+ (OAApplicationMode *) CAR;
+ (OAApplicationMode *) BICYCLE;
+ (OAApplicationMode *) PEDESTRIAN;
+ (OAApplicationMode *) AIRCRAFT;
+ (OAApplicationMode *) TRUCK;
+ (OAApplicationMode *) MOTORCYCLE;
+ (OAApplicationMode *) MOPED;
+ (OAApplicationMode *) BOAT;
+ (OAApplicationMode *) PUBLIC_TRANSPORT;
+ (OAApplicationMode *) TRAIN;
+ (OAApplicationMode *) SKI;
+ (OAApplicationMode *) HORSE;

+ (NSArray<OAApplicationMode *> *) values;
+ (NSArray<OAApplicationMode *> *) allPossibleValues;
+ (NSArray<OAApplicationMode *> *) getModesDerivedFrom:(OAApplicationMode *)am;
+ (OAApplicationMode *) valueOfStringKey:(NSString *)key def:(OAApplicationMode *)def;

+ (void) onApplicationStart;
+ (OAApplicationMode *) saveProfile:(OAApplicationModeBuilder *)appMode;
+ (void) changeProfileAvailability:(OAApplicationMode *) mode isSelected:(BOOL) isSelected;
+ (BOOL) isProfileNameAvailable:(NSString *)profileName;
+ (OAApplicationMode *) getFirstAvailableNavigationMode;

- (instancetype)initWithName:(NSString *)name stringKey:(NSString *)stringKey;

- (NSDictionary *) toJson;

- (BOOL) hasFastSpeed;
- (int) getRouteTypeProfile;
- (BOOL) isDerivedRoutingFrom:(OAApplicationMode *)mode;

/**
 * @return Distance in meters to use as a filter when the app goes into the background during a track recording
 */
- (NSInteger) getBackgroundDistanceFilter;

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
- (OALocationIcon *) getNavigationIcon;
- (void) setNavigationIconName:(NSString *) navIcon;
- (OALocationIcon *) getLocationIcon;
- (void) setLocationIconName:(NSString *) locIcon;
- (UIColor *) getProfileColor;
- (int) getIconColor;
- (void) setIconColor:(int)iconColor;
- (int) getCustomIconColor;
- (void) setCustomIconColor:(int)iconColor;
- (int) getOrder;
- (void) setOrder:(int)order;
- (NSString *) getRoutingProfile;
- (NSString *) getDerivedProfile;
- (void) setDerivedProfile:(NSString *)derivedProfile;
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
@property (nonatomic) NSString *derivedProfile;
@property (nonatomic) NSString *routingProfile;
@property (nonatomic) NSString *iconResName;
@property (nonatomic) NSInteger iconColor;
@property (nonatomic) NSInteger customIconColor;
@property (nonatomic) NSString *locationIcon;
@property (nonatomic) NSString *navigationIcon;
@property (nonatomic) NSInteger order;

- (OAApplicationMode *) customReg;

@end
