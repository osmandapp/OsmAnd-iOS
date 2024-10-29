//
//  OAColoringType.h
//  OsmAnd Maps
//
//  Created by Paul on 25.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OASGpxFile, OAGradientScaleType, OARouteCalculationResult;

@interface OAColoringType : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *iconName;

+ (OAColoringType *) DEFAULT;
+ (OAColoringType *) CUSTOM_COLOR;
+ (OAColoringType *) TRACK_SOLID;
+ (OAColoringType *) SPEED;
+ (OAColoringType *) ALTITUDE;
+ (OAColoringType *) SLOPE;
+ (OAColoringType *) ATTRIBUTE;

+ (NSArray<OAColoringType *> *) getRouteColoringTypes;
+ (NSArray<OAColoringType *> *) getTrackColoringTypes;

+ (OAColoringType *) getRouteColoringTypeByName:(NSString *)name;
+ (OAColoringType *) getNonNullTrackColoringTypeByName:(NSString *)name;

- (BOOL) isAvailableForDrawingRoute:(OARouteCalculationResult *)route attributeName:(NSString *)attributeName;
- (BOOL) isAvailableForDrawingTrack:(OASGpxFile *)selectedGpxFile attributeName:(NSString *)attributeName;
- (BOOL) isAvailableInSubscription;

- (OAGradientScaleType *) toGradientScaleType;
- (NSInteger) toColorizationType;

- (NSString *) getName:(NSString *)routeInfoAttribute;
- (BOOL) isCustomColor;
- (BOOL) isTrackSolid;
- (BOOL) isSolidSingleColor;
- (BOOL) isGradient;
- (BOOL) isRouteInfoAttribute;
- (BOOL)isSpeed;
- (BOOL)isAltitude;
- (BOOL)isSlope;

@end

