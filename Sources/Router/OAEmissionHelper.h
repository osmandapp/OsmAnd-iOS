//
//  OAEmissionHelper.h
//  OsmAnd
//
//  Created by Skalii on 16.12.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode;

@protocol OAEmissionHelperListener

- (void)onSetupEmission:(NSString *)result;

@end

@interface OAMotorType : NSObject

@property (nonatomic, readonly) CGFloat fuelConsumption; // unit (L/kwH/kg)/100km
@property (nonatomic, readonly) CGFloat fuelEmissionFactor; // kg CO2/unit (L/kwH/kg)

+ (OAMotorType *) PETROL; // L
+ (OAMotorType *) DIESEL; // L
+ (OAMotorType *) LPG; // L
+ (OAMotorType *) GAS; // kg
+ (OAMotorType *) ELECTRIC; // kWh fuelEmissionFactor "UE except France"
+ (OAMotorType *) HYBRID; // L, hybrid petrol

- (BOOL)shouldCheckRegion;

@end

@interface OAEmissionHelper : NSObject

+ (OAEmissionHelper *)sharedInstance;
- (OAMotorType *)getMotorTypeForMode:(OAApplicationMode *)mode;
- (void)getEmission:(OAMotorType *)motorType meters:(CGFloat)meters listener:(id<OAEmissionHelperListener>)listener;

@end
