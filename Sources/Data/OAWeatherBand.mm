//
//  OAWeatherBand.m
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherBand.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapStyleSettings.h"
#import "OAMapPresentationEnvironment.h"
#import "OAMapRendererView.h"

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Map/WeatherDataConverter.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
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

static NSArray *kTempUnits;
static NSArray *kPressureUnits;
static NSArray *kCloudUnits;
static NSArray *kWindSpeedUnits;
static NSArray *kPrecipUnits;

static NSDictionary<NSString *, NSString *> *kGeneralUnitFormats;
static NSDictionary<NSString *, NSString *> *kPreciseUnitFormats;

static NSString *kDefaultTempUnit;
static NSString *kDefaultPressureUnit;
static NSString *kDefaultCloudUnit;
static NSString *kDefaultWindSpeedUnit;
static NSString *kDefaultPrecipUnit;

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
    kTempUnits = @[@"C", @"F"];
    kPressureUnits = @[@"hPa", @"mmHg", @"inHg"];
    kCloudUnits = @[@"%"];
    kWindSpeedUnits = @[@"m/s", @"km/h", @"mph", @"kt"];
    kPrecipUnits = @[@"mm", @"in"];

    kGeneralUnitFormats = @{
        @"%" : @"%d",
        @"C" : @"%d",
        @"F" : @"%d",
        @"hPa" : @"%d",
        @"mmHg" : @"%d",
        @"inHg" : @"%d",
        @"m/s" : @"%d",
        @"km/h" : @"%d",
        @"mph" : @"%d",
        @"kt" : @"%d",
        @"mm" : @"%d",
        @"in" : @"%d"
    };

    kPreciseUnitFormats = @{
        @"%" : @"%d",
        @"C" : @"%.1f",
        @"F" : @"%d",
        @"hPa" : @"%d",
        @"mmHg" : @"%d",
        @"inHg" : @"%.1f",
        @"m/s" : @"%d",
        @"km/h" : @"%d",
        @"mph" : @"%d",
        @"kt" : @"%d",
        @"mm" : @"%.1f",
        @"in" : @"%.1f"
    };
    
    kPressureUnits = @[@"hPa", @"mmHg", @"inHg"];
    kCloudUnits = @[@"%"];
    kWindSpeedUnits = @[@"m/s", @"km/h", @"mph", @"kt"];
    kPrecipUnits = @[@"mm", @"in"];

    kDefaultTempUnit = @"C";
    kDefaultPressureUnit = @"mmHg";
    kDefaultCloudUnit = @"%";
    kDefaultWindSpeedUnit = @"m/s";
    kDefaultPrecipUnit = @"mm";

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

- (NSString *) getBandUnit
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

- (BOOL) setBandUnit:(NSString *)unit
{
    if (![[self getAvailableBandUnits] containsObject:unit])
        return NO;
    
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            _app.data.weatherCloudUnit = unit;
            break;
        case WEATHER_BAND_TEMPERATURE:
            _app.data.weatherTempUnit = unit;
            break;
        case WEATHER_BAND_PRESSURE:
            _app.data.weatherPressureUnit = unit;
            break;
        case WEATHER_BAND_WIND_SPEED:
            _app.data.weatherWindUnit = unit;
            break;
        case WEATHER_BAND_PRECIPITATION:
            _app.data.weatherPrecipUnit = unit;
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
    return YES;
}

- (NSString *) getBandGeneralUnitFormat
{
    return kGeneralUnitFormats[[self getBandUnit]];
}

- (NSString *) getBandPreciseUnitFormat
{
    return kPreciseUnitFormats[[self getBandUnit]];
}

+ (NSString *) getDefaultBandUnit:(EOAWeatherBand)bandIndex
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

- (NSString *) getDefaultBandUnit
{
    return [self.class getDefaultBandUnit:self.bandIndex];
}

- (NSString *) getInternalBandUnit
{
    return [self.class getInternalBandUnit:self.bandIndex];
}

- (NSArray<NSString *> *) getAvailableBandUnits
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

- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) getContourLevels
{
    return [self getContourValuesType:CONTOUR_VALUE_LEVELS];
}

- (NSDictionary<NSNumber *, NSArray<NSString *> *> *) getContourTypes
{
    NSDictionary<NSNumber *, NSArray<NSNumber *> *> *contourTypeValues = [self getContourValuesType:CONTOUR_VALUE_TYPES];
    NSMutableDictionary<NSNumber *, NSArray<NSString *> *> *contourTypes = [NSMutableDictionary dictionary];
    NSString *unit = [self getBandUnit];
    [contourTypeValues enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull zoomNum, NSArray<NSNumber *> * _Nonnull values, BOOL * _Nonnull stop)
    {
        NSMutableArray<NSString *> *types = [NSMutableArray array];
        for (NSNumber *val in values)
             [types addObject:[NSString stringWithFormat:@"%d%@", (int)val.doubleValue, unit]];
        
        contourTypes[zoomNum] = [NSArray arrayWithArray:types];
    }];
    return contourTypes;
}

- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) getContourValuesType:(EOAContourValueType)valueType
{
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    OAMapPresentationEnvironment *mapPresentationEnv = mapViewController.mapPresentationEnv;
    const auto& env = mapPresentationEnv.mapPresentationEnvironment;
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
    NSString *unit = [self getBandUnit];
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
