//
//  OAWeatherBand.h
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAAutoObserverProxy.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAWeatherBand)
{
    WEATHER_BAND_UNDEFINED = 0,
    WEATHER_BAND_CLOUD = 1,
    WEATHER_BAND_TEMPERATURE = 2,
    WEATHER_BAND_PRESSURE = 3,
    WEATHER_BAND_WIND_SPEED = 4,
    WEATHER_BAND_PRECIPITATION = 5
};

@class OAMapPresentationEnvironment;

@interface OAWeatherBand : NSObject

@property (nonatomic, readonly) EOAWeatherBand bandIndex;

+ (instancetype) withWeatherBand:(EOAWeatherBand)bandIndex;
+ (NSUnit *) getDefaultBandUnit:(EOAWeatherBand)bandIndex;
+ (NSString *) getInternalBandUnit:(EOAWeatherBand)bandIndex;

- (BOOL) isBandVisible;
- (NSUnit *) getBandUnit;
- (BOOL) setBandUnit:(NSUnit *)unit;
- (BOOL) isBandUnitAuto;
- (void) setBandUnitAuto:(BOOL)unitAuto;
- (NSString *)getIcon;
- (NSString *)getMeasurementName;
- (NSString *) getBandGeneralUnitFormat;
- (NSString *) getBandPreciseUnitFormat;
- (NSUnit *) getDefaultBandUnit;
- (NSString *) getInternalBandUnit;
- (NSArray<NSUnit *> *) getAvailableBandUnits;
- (double) getBandOpacity;
- (NSString *) getColorFilePath;
- (NSString *) getContourStyleName;
- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) getContourLevels:(OAMapPresentationEnvironment *)mapPresentationEnvironment;
- (NSDictionary<NSNumber *, NSArray<NSString *> *> *) getContourTypes:(OAMapPresentationEnvironment *)mapPresentationEnvironment;

- (OAAutoObserverProxy *) createSwitchObserver:(id)owner handler:(SEL)handler;
- (OAAutoObserverProxy *) createAlphaObserver:(id)owner handler:(SEL)handler;

@end

NS_ASSUME_NONNULL_END
