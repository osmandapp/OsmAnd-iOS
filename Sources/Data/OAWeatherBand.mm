//
//  OAWeatherBand.m
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherBand.h"
#import "OsmAndApp.h"
#import "OAMapPresentationEnvironment.h"
#import "Localization.h"

#include <OsmAndCore/Map/WeatherDataConverter.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/MapStyleEvaluator.h>
#include <OsmAndCore/Map/MapStyleEvaluationResult.h>
#include <OsmAndCore/Map/MapStyleBuiltinValueDefinitions.h>
#include <OsmAndCore/Data/MapObject.h>

typedef NS_ENUM(NSInteger, EOAContourValueType)
{
    CONTOUR_VALUE_LEVELS = 0,
    CONTOUR_VALUE_TYPES = 1
};

@interface OAWeatherBand()

@property (nonatomic) EOAWeatherBand bandIndex;

@end

static NSArray<NSUnit *> *kTempUnits;
static NSArray<NSUnit *> *kPressureUnits;
static NSArray<NSUnit *> *kCloudUnits;
static NSArray<NSUnit *> *kWindSpeedUnits;
static NSArray<NSUnit *> *kPrecipUnits;

static NSDictionary<NSString *, NSString *> *kGeneralUnitFormats;
static NSDictionary<NSString *, NSString *> *kPreciseUnitFormats;

static NSUnitTemperature *kDefaultTempUnit;
static NSUnitPressure *kDefaultPressureUnit;
static NSUnitCloud *kDefaultCloudUnit;
static NSUnitSpeed *kDefaultWindSpeedUnit;
static NSUnitLength *kDefaultPrecipUnit;

static NSString *kInternalTempUnit;
static NSString *kInternalPressureUnit;
static NSString *kInternalCloudUnit;
static NSString *kInternalWindSpeedUnit;
static NSString *kInternalPrecipUnit;

static NSString *kCloudContourStyleName;
static NSString *kTempContourStyleName;
static NSString *kPressureContourStyleName;
static NSString *kWindSpeedContourStyleName;
static NSString *kPrecipContourStyleName;


@implementation OAWeatherBand
{
    OsmAndAppInstance _app;
}

+ (void) initialize
{
    kTempUnits = @[NSUnitTemperature.celsius, NSUnitTemperature.fahrenheit];
    kPressureUnits = @[NSUnitPressure.hectopascals, NSUnitPressure.millimetersOfMercury, NSUnitPressure.inchesOfMercury];
    kCloudUnits = @[NSUnitCloud.percent];
    kWindSpeedUnits = @[NSUnitSpeed.metersPerSecond, NSUnitSpeed.kilometersPerHour, NSUnitSpeed.milesPerHour, NSUnitSpeed.knots];
    kPrecipUnits = @[NSUnitLength.millimeters, NSUnitLength.inches];

    kGeneralUnitFormats = @{
        NSUnitCloud.percent.symbol: @"%d",
        NSUnitTemperature.celsius.symbol: @"%d",
        NSUnitTemperature.fahrenheit.symbol: @"%d",
        NSUnitPressure.hectopascals.symbol: @"%d",
        NSUnitPressure.millimetersOfMercury.symbol: @"%d",
        NSUnitPressure.inchesOfMercury.symbol: @"%d",
        NSUnitSpeed.metersPerSecond.symbol: @"%d",
        NSUnitSpeed.kilometersPerHour.symbol: @"%d",
        NSUnitSpeed.milesPerHour.symbol: @"%d",
        NSUnitSpeed.knots.symbol: @"%d",
        NSUnitLength.millimeters.symbol: @"%d",
        NSUnitLength.inches.symbol: @"%d"
    };

    kPreciseUnitFormats = @{
        NSUnitCloud.percent.symbol: @"%d",
        NSUnitTemperature.celsius.symbol: @"%.1f",
        NSUnitTemperature.fahrenheit.symbol: @"%d",
        NSUnitPressure.hectopascals.symbol: @"%d",
        NSUnitPressure.millimetersOfMercury.symbol: @"%d",
        NSUnitPressure.inchesOfMercury.symbol: @"%.1f",
        NSUnitSpeed.metersPerSecond.symbol: @"%d",
        NSUnitSpeed.kilometersPerHour.symbol: @"%d",
        NSUnitSpeed.milesPerHour.symbol: @"%d",
        NSUnitSpeed.knots.symbol: @"%d",
        NSUnitLength.millimeters.symbol: @"%.1f",
        NSUnitLength.inches.symbol: @"%.1f"
    };

    kDefaultCloudUnit = [NSUnitCloud current];
    kDefaultTempUnit = [NSUnitTemperature current];
    kDefaultWindSpeedUnit = [NSUnitSpeed current];
    kDefaultPressureUnit = [NSUnitPressure current];
    kDefaultPrecipUnit = [NSUnitLength current];

    kInternalTempUnit = @"C";
    kInternalPressureUnit = @"Pa";
    kInternalCloudUnit = @"%";
    kInternalWindSpeedUnit = @"m/s";
    kInternalPrecipUnit = @"kg/(m^2 s)";

    kCloudContourStyleName = @"cloud";
    kTempContourStyleName = @"temperature";
    kPressureContourStyleName = @"pressure";
    kWindSpeedContourStyleName = @"windSpeed";
    kPrecipContourStyleName = @"precipitation";
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
    }
    return self;
}

+ (instancetype) withWeatherBand:(EOAWeatherBand)bandIndex
{
    OAWeatherBand *obj = [[OAWeatherBand alloc] init];
    if (obj)
    {
        obj.bandIndex = bandIndex;
    }
    return obj;
}

- (BOOL) isBandVisible
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return _app.data.weatherCloud;
        case WEATHER_BAND_TEMPERATURE:
            return _app.data.weatherTemp;
        case WEATHER_BAND_PRESSURE:
            return _app.data.weatherPressure;
        case WEATHER_BAND_WIND_SPEED:
            return _app.data.weatherWind;
        case WEATHER_BAND_PRECIPITATION:
            return _app.data.weatherPrecip;
        case WEATHER_BAND_UNDEFINED:
            return NO;
    }
    return NO;
}

- (NSUnit *) getBandUnit
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return _app.data.weatherCloudUnit;
        case WEATHER_BAND_TEMPERATURE:
            return _app.data.weatherTempUnit;
        case WEATHER_BAND_PRESSURE:
            return _app.data.weatherPressureUnit;
        case WEATHER_BAND_WIND_SPEED:
            return _app.data.weatherWindUnit;
        case WEATHER_BAND_PRECIPITATION:
            return _app.data.weatherPrecipUnit;
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (BOOL) setBandUnit:(NSUnit *)unit
{
    if (![[self getAvailableBandUnits] containsObject:unit])
        return NO;

    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            _app.data.weatherCloudUnit = (NSUnitCloud *) unit;
            break;
        case WEATHER_BAND_TEMPERATURE:
            _app.data.weatherTempUnit = (NSUnitTemperature *) unit;
            break;
        case WEATHER_BAND_PRESSURE:
            _app.data.weatherPressureUnit = (NSUnitPressure *) unit;
            break;
        case WEATHER_BAND_WIND_SPEED:
            _app.data.weatherWindUnit = (NSUnitSpeed *) unit;
            break;
        case WEATHER_BAND_PRECIPITATION:
            _app.data.weatherPrecipUnit = (NSUnitLength *) unit;
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
    return YES;
}

- (BOOL) isBandUnitAuto
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return _app.data.weatherCloudUnitAuto;
        case WEATHER_BAND_TEMPERATURE:
            return _app.data.weatherTempUnitAuto;
        case WEATHER_BAND_PRESSURE:
            return _app.data.weatherPressureUnitAuto;
        case WEATHER_BAND_WIND_SPEED:
            return _app.data.weatherWindUnitAuto;
        case WEATHER_BAND_PRECIPITATION:
            return _app.data.weatherPrecipUnitAuto;
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (void) setBandUnitAuto:(BOOL)unitAuto
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            _app.data.weatherCloudUnitAuto = unitAuto;
            break;
        case WEATHER_BAND_TEMPERATURE:
            _app.data.weatherTempUnitAuto = unitAuto;
            break;
        case WEATHER_BAND_PRESSURE:
            _app.data.weatherPressureUnitAuto = unitAuto;
            break;
        case WEATHER_BAND_WIND_SPEED:
            _app.data.weatherWindUnitAuto = unitAuto;
            break;
        case WEATHER_BAND_PRECIPITATION:
            _app.data.weatherPrecipUnitAuto = unitAuto;
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
}

- (NSString *)getIcon
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return @"ic_custom_clouds";
        case WEATHER_BAND_TEMPERATURE:
            return @"ic_custom_thermometer";
        case WEATHER_BAND_PRESSURE:
            return @"ic_custom_air_pressure";
        case WEATHER_BAND_WIND_SPEED:
            return @"ic_custom_wind";
        case WEATHER_BAND_PRECIPITATION:
            return @"ic_custom_precipitation";
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (NSString *)getMeasurementName
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return OALocalizedString(@"map_settings_weather_cloud");
        case WEATHER_BAND_TEMPERATURE:
            return OALocalizedString(@"map_settings_weather_temp");
        case WEATHER_BAND_PRESSURE:
            return OALocalizedString(@"map_settings_weather_pressure");
        case WEATHER_BAND_WIND_SPEED:
            return OALocalizedString(@"map_settings_weather_wind");
        case WEATHER_BAND_PRECIPITATION:
            return OALocalizedString(@"map_settings_weather_precip");
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (NSString *) getBandGeneralUnitFormat
{
    return kGeneralUnitFormats[[self getBandUnit].symbol];
}

- (NSString *) getBandPreciseUnitFormat
{
    return kPreciseUnitFormats[[self getBandUnit].symbol];
}

+ (NSUnit *) getDefaultBandUnit:(EOAWeatherBand)bandIndex
{
    switch (bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return kDefaultCloudUnit;
        case WEATHER_BAND_TEMPERATURE:
            return kDefaultTempUnit;
        case WEATHER_BAND_PRESSURE:
            return kDefaultPressureUnit;
        case WEATHER_BAND_WIND_SPEED:
            return kDefaultWindSpeedUnit;
        case WEATHER_BAND_PRECIPITATION:
            return kDefaultPrecipUnit;
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

+ (NSString *) getInternalBandUnit:(EOAWeatherBand)bandIndex
{
    switch (bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return kInternalCloudUnit;
        case WEATHER_BAND_TEMPERATURE:
            return kInternalTempUnit;
        case WEATHER_BAND_PRESSURE:
            return kInternalPressureUnit;
        case WEATHER_BAND_WIND_SPEED:
            return kInternalWindSpeedUnit;
        case WEATHER_BAND_PRECIPITATION:
            return kInternalPrecipUnit;
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (NSUnit *) getDefaultBandUnit
{
    return [self.class getDefaultBandUnit:self.bandIndex];
}

- (NSString *) getInternalBandUnit
{
    return [self.class getInternalBandUnit:self.bandIndex];
}

- (NSArray<NSUnit *> *) getAvailableBandUnits
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return kCloudUnits;
        case WEATHER_BAND_TEMPERATURE:
            return kTempUnits;
        case WEATHER_BAND_PRESSURE:
            return kPressureUnits;
        case WEATHER_BAND_WIND_SPEED:
            return kWindSpeedUnits;
        case WEATHER_BAND_PRECIPITATION:
            return kPrecipUnits;
        case WEATHER_BAND_UNDEFINED:
            return @[];
    }
    return @[];
}

- (double) getBandOpacity
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return _app.data.weatherCloudAlpha;
        case WEATHER_BAND_TEMPERATURE:
            return _app.data.weatherTempAlpha;
        case WEATHER_BAND_PRESSURE:
            return _app.data.weatherPressureAlpha;
        case WEATHER_BAND_WIND_SPEED:
            return _app.data.weatherWindAlpha;
        case WEATHER_BAND_PRECIPITATION:
            return _app.data.weatherPrecipAlpha;
        case WEATHER_BAND_UNDEFINED:
            return 0.0;
    }
    return 0.0;
}

- (NSString *) getColorFilePath
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return [[NSBundle mainBundle] pathForResource:@"cloud_color" ofType:@"txt"];
        case WEATHER_BAND_TEMPERATURE:
            return [[NSBundle mainBundle] pathForResource:@"temperature_color" ofType:@"txt"];
        case WEATHER_BAND_PRESSURE:
            return [[NSBundle mainBundle] pathForResource:@"pressure_color" ofType:@"txt"];
        case WEATHER_BAND_WIND_SPEED:
            return [[NSBundle mainBundle] pathForResource:@"wind_color" ofType:@"txt"];
        case WEATHER_BAND_PRECIPITATION:
            return [[NSBundle mainBundle] pathForResource:@"precip_color" ofType:@"txt"];
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (NSString *) getContourStyleName
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return kCloudContourStyleName;
        case WEATHER_BAND_TEMPERATURE:
            return kTempContourStyleName;
        case WEATHER_BAND_PRESSURE:
            return kPressureContourStyleName;
        case WEATHER_BAND_WIND_SPEED:
            return kWindSpeedContourStyleName;
        case WEATHER_BAND_PRECIPITATION:
            return kPrecipContourStyleName;
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) getContourLevels:(OAMapPresentationEnvironment *)mapPresentationEnvironment
{
    return [self getContourValuesType:CONTOUR_VALUE_LEVELS mapPresentationEnvironment:mapPresentationEnvironment];
}

- (NSDictionary<NSNumber *, NSArray<NSString *> *> *) getContourTypes:(OAMapPresentationEnvironment *)mapPresentationEnvironment
{
    NSDictionary<NSNumber *, NSArray<NSNumber *> *> *contourTypeValues = [self getContourValuesType:CONTOUR_VALUE_TYPES mapPresentationEnvironment:mapPresentationEnvironment];
    NSMutableDictionary<NSNumber *, NSArray<NSString *> *> *contourTypes = [NSMutableDictionary dictionary];
    NSString *unit = [self getBandUnit].symbol;
    [contourTypeValues enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull zoomNum, NSArray<NSNumber *> * _Nonnull values, BOOL * _Nonnull stop)
    {
        NSMutableArray<NSString *> *types = [NSMutableArray array];
        for (NSNumber *val in values)
             [types addObject:[NSString stringWithFormat:@"%d%@", (int)val.doubleValue, unit]];
        
        contourTypes[zoomNum] = [NSArray arrayWithArray:types];
    }];
    return contourTypes;
}

- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) getContourValuesType:(EOAContourValueType)valueType mapPresentationEnvironment:(OAMapPresentationEnvironment *)mapPresentationEnvironment
{
    if (!mapPresentationEnvironment)
        return @{};

    const auto& env = mapPresentationEnvironment.mapPresentationEnvironment;
    if (!env)
        return @{};

    auto minZoom = _app.resourcesManager->getWeatherResourcesManager()->getMinTileZoom(OsmAnd::WeatherType::Contour, OsmAnd::WeatherLayer::High);
    auto maxZoom = _app.resourcesManager->getWeatherResourcesManager()->getMaxTileZoom(OsmAnd::WeatherType::Contour, OsmAnd::WeatherLayer::High);
    EOAWeatherBand band = self.bandIndex;
    QString type;
    switch (band)
    {
        case WEATHER_BAND_CLOUD:
            type = QStringLiteral("cloud");
            break;
        case WEATHER_BAND_TEMPERATURE:
            type = QStringLiteral("temp");
            break;
        case WEATHER_BAND_PRESSURE:
            type = QStringLiteral("pressure");
            break;
        case WEATHER_BAND_WIND_SPEED:
            type = QStringLiteral("wind_speed");
            break;
        case WEATHER_BAND_PRECIPITATION:
            type = QStringLiteral("precip");
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
    
    if (type.isEmpty())
        return @{};
    
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    NSString *unit = [self getBandUnit].symbol;
    NSString *interalUnit = [self getInternalBandUnit];
    auto zoom = minZoom;
    while (zoom <= maxZoom)
    {
        const auto& result = valueType == CONTOUR_VALUE_LEVELS
            ? env->getWeatherContourLevels(QString::asprintf("%s_%s", qPrintable(type), qPrintable(QString::fromNSString(unit))), zoom)
            : env->getWeatherContourTypes(QString::asprintf("%s_%s", qPrintable(type), qPrintable(QString::fromNSString(unit))), zoom);
        
        if (!result.isEmpty())
        {
            NSMutableArray<NSNumber *> *levels = [NSMutableArray array];
            const auto params = result.split(',');
            for (const auto& p : params)
            {
                bool ok;
                double level = p.toDouble(&ok);
                if (!ok)
                    continue;
                
                if (![unit isEqualToString:interalUnit])
                {
                    switch (band)
                    {
                        case WEATHER_BAND_CLOUD:
                            // Assume cloud in % only
                            break;
                        case WEATHER_BAND_TEMPERATURE:
                        {
                            const auto unit_ = OsmAnd::WeatherDataConverter::Temperature::unitFromString(QString::fromNSString(unit));
                            const auto interalUnit_ = OsmAnd::WeatherDataConverter::Temperature::unitFromString(QString::fromNSString(interalUnit));
                            const auto *temp = new OsmAnd::WeatherDataConverter::Temperature(unit_, level);
                            level = temp->toUnit(interalUnit_);
                            delete temp;
                            break;
                        }
                        case WEATHER_BAND_PRESSURE:
                        {
                            const auto unit_ = OsmAnd::WeatherDataConverter::Pressure::unitFromString(QString::fromNSString(unit));
                            const auto interalUnit_ = OsmAnd::WeatherDataConverter::Pressure::unitFromString(QString::fromNSString(interalUnit));
                            const auto *pressure = new OsmAnd::WeatherDataConverter::Pressure(unit_, level);
                            level = pressure->toUnit(interalUnit_);
                            delete pressure;
                            break;
                        }
                        case WEATHER_BAND_WIND_SPEED:
                        {
                            const auto unit_ = OsmAnd::WeatherDataConverter::Speed::unitFromString(QString::fromNSString(unit));
                            const auto interalUnit_ = OsmAnd::WeatherDataConverter::Speed::unitFromString(QString::fromNSString(interalUnit));
                            const auto *speed = new OsmAnd::WeatherDataConverter::Speed(unit_, level);
                            level = speed->toUnit(interalUnit_);
                            delete speed;
                            break;
                        }
                        case WEATHER_BAND_PRECIPITATION:
                        {
                            const auto unit_ = OsmAnd::WeatherDataConverter::Precipitation::unitFromString(QString::fromNSString(unit));
                            const auto interalUnit_ = OsmAnd::WeatherDataConverter::Precipitation::unitFromString(QString::fromNSString(interalUnit));
                            const auto *precip = new OsmAnd::WeatherDataConverter::Precipitation(unit_, level);
                            level = precip->toUnit(interalUnit_);
                            delete precip;
                            break;
                        }
                        case WEATHER_BAND_UNDEFINED:
                            break;
                    }
                }
                [levels addObject:@(level)];
            }
            map[@(zoom)] = [NSArray arrayWithArray:levels];
        }
        zoom = (OsmAnd::ZoomLevel)((int)zoom + 1);
    }
    return [NSDictionary dictionaryWithDictionary:map];
}

- (OAAutoObserverProxy *) createSwitchObserver:(id)owner handler:(SEL)handler
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_TEMPERATURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherTempChangeObservable];
        case WEATHER_BAND_PRESSURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPressureChangeObservable];
        case WEATHER_BAND_WIND_SPEED:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherWindChangeObservable];
        case WEATHER_BAND_CLOUD:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherCloudChangeObservable];
        case WEATHER_BAND_PRECIPITATION:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPrecipChangeObservable];
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
}

- (OAAutoObserverProxy *) createAlphaObserver:(id)owner handler:(SEL)handler
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_TEMPERATURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherTempAlphaChangeObservable];
        case WEATHER_BAND_PRESSURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPressureAlphaChangeObservable];
        case WEATHER_BAND_WIND_SPEED:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherWindAlphaChangeObservable];
        case WEATHER_BAND_CLOUD:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherCloudAlphaChangeObservable];
        case WEATHER_BAND_PRECIPITATION:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPrecipAlphaChangeObservable];
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
}

@end
