//
//  OAApplicationMode.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define OAMapVariantDefaultStr @"type_default"
#define OAMapVariantCarStr @"type_car"
#define OAMapVariantPedestrianStr @"type_pedestrian"
#define OAMapVariantBicycleStr @"type_bicycle"

#define OAMapAppModeDefault @"default"
#define OAMapAppModeCar @"car"
#define OAMapAppModePedestrian @"pedestrian"
#define OAMapAppModeBicycle @"bicycle"

typedef NS_ENUM(NSInteger, OAMapVariantType)
{
    OAMapVariantDefault = 0,
    OAMapVariantCar,
    OAMapVariantPedestrian,
    OAMapVariantBicycle,
};

@interface OAApplicationMode : NSObject

+ (OAMapVariantType) getVariantType:(NSString *) variantStr;
+ (NSString *) getVariantStr:(OAMapVariantType) variantType;
+ (NSString *) getAppModeByVariantType:(OAMapVariantType) variantType;
+ (NSString *) getAppModeByVariantTypeStr:(NSString *) variantStr;

+ (float) getDefaultSpeedByVariantType:(OAMapVariantType) variantType;
+ (int) getMinDistanceForTurnByVariantType:(OAMapVariantType) variantType;
+ (int) getArrivalDistanceByVariantType:(OAMapVariantType) variantType;
+ (BOOL) hasFastSpeedByVariantType:(OAMapVariantType) variantType;
+ (NSString *)getVariantTypeIconName:(OAMapVariantType) variantType;
+ (NSString *)getVariantTypeMyLocationIconName:(OAMapVariantType) variantType;
+ (NSString *)getVariantTypeMyLocationBearingIconName:(OAMapVariantType) variantType;

@end
