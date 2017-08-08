//
//  OAApplicationMode.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAApplicationMode.h"

@implementation OAApplicationMode

+ (OAMapVariantType)getVariantType:(NSString *) variantStr
{
    OAMapVariantType mapVariantType = OAMapVariantDefault;
    if ([variantStr isEqualToString:OAMapVariantCarStr])
        mapVariantType = OAMapVariantCar;
    else if ([variantStr isEqualToString:OAMapVariantPedestrianStr])
        mapVariantType = OAMapVariantPedestrian;
    else if ([variantStr isEqualToString:OAMapVariantBicycleStr])
        mapVariantType = OAMapVariantBicycle;
    
    return mapVariantType;
}

+ (NSString *)getVariantStr:(OAMapVariantType) variantType
{
    NSString *variant;
    if (variantType == OAMapVariantCar)
        variant = OAMapVariantCarStr;
    else if (variantType == OAMapVariantPedestrian)
        variant = OAMapVariantPedestrianStr;
    else if (variantType == OAMapVariantBicycle)
        variant = OAMapVariantBicycleStr;
    else
        variant = OAMapVariantDefaultStr;
    
    return variant;
}

+ (NSString *)getAppModeByVariantType:(OAMapVariantType) variantType
{
    NSString *appMode;
    if (variantType == OAMapVariantCar)
        appMode = OAMapAppModeCar;
    else if (variantType == OAMapVariantPedestrian)
        appMode = OAMapAppModePedestrian;
    else if (variantType == OAMapVariantBicycle)
        appMode = OAMapAppModeBicycle;
    else
        appMode = OAMapAppModeDefault;
    
    return appMode;
}

+ (NSString *)getAppModeByVariantTypeStr:(NSString *) variantStr
{
    NSString *appMode;
    if ([variantStr isEqualToString:OAMapVariantCarStr])
        appMode = OAMapAppModeCar;
    else if ([variantStr isEqualToString:OAMapVariantPedestrianStr])
        appMode = OAMapAppModePedestrian;
    else if ([variantStr isEqualToString:OAMapVariantBicycleStr])
        appMode = OAMapAppModeBicycle;
    else
        appMode = OAMapAppModeDefault;
    
    return appMode;
}

+ (float)getDefaultSpeedByVariantType:(OAMapVariantType) variantType
{
    switch (variantType)
    {
        case OAMapVariantDefault:
            return 1.5;
        case OAMapVariantCar:
            return 15.3;
        case OAMapVariantPedestrian:
            return 1.5;
        case OAMapVariantBicycle:
            return 5.5;
    }
}

+ (int)getMinDistanceForTurnByVariantType:(OAMapVariantType) variantType
{
    switch (variantType)
    {
        case OAMapVariantDefault:
            return 5;
        case OAMapVariantCar:
            return 35;
        case OAMapVariantPedestrian:
            return 5;
        case OAMapVariantBicycle:
            return 15;
    }
}

+ (int)getArrivalDistanceByVariantType:(OAMapVariantType) variantType
{
    switch (variantType)
    {
        case OAMapVariantDefault:
            return 90;
        case OAMapVariantCar:
            return 90;
        case OAMapVariantPedestrian:
            return 45;
        case OAMapVariantBicycle:
            return 60;
    }
}

+ (BOOL) hasFastSpeedByVariantType:(OAMapVariantType) variantType
{
    return [self.class getDefaultSpeedByVariantType:variantType] > 10;
}

@end
