//
//  OAEmissionHelper.m
//  OsmAnd
//
//  Created by Skalii on 16.12.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

/*
Here I considered the CO2 footprint of the use only, not the whole life cycle
I copied methodology of https://www.youtube.com/watch?v=zjaUqUozwdc&t=3000s
which is to take the average consumption of all "automobile" of all years that rode > 1500 km on
https://www.spritmonitor.de/en/overview/0-All_manufactures/0-All_models.html?powerunit=2
and multiply by the emission factor found at p.16 of
"Information GES des prestations de transport - Guide méthodologique" version September 2018
https://www.ecologie.gouv.fr/sites/default/files/Info%20GES_Guide%20m%C3%A9thodo.pdf
For electricity, the default CO2/kWh number is "Europe (except France)"
Specific number for France is at 7min25s in the video.
I took the kWh/100km number of the video because the spritmonitor average was very close
to the one used in the video for the Renault Clio.
For natural gas, I took 1 m^3 = 1.266 kg from  https://www.grdf.fr/acteurs-gnv/accompagnement-grdf-gnv/concevoir-projet/reservoir-gnc
Only fossil fuel are counted for hybrid cars since their consumption is given in liter
 */

#import "OAEmissionHelper.h"
#import "OARTargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OARoutingHelperUtils.h"
#import "OARoutePreferencesParameters.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"

#include <regex>

struct ListParameters
{
    vector<string> names;
    vector<string> values;

    int findIndexOfValue(string value)
    {
        if (!value.empty() && !values.empty())
        {
            for (int i = 0; i < values.size(); i++)
            {
                if (values[i].compare(value) == 0)
                    return i;
            }
        }
        return -1;
    }
};

static OAMotorType * PETROL;
static OAMotorType * DIESEL;
static OAMotorType * LPG;
static OAMotorType * GAS;
static OAMotorType * ELECTRIC;
static OAMotorType * HYBRID;

@implementation OAMotorType

- (instancetype)initWithFuelConsumption:(CGFloat)fuelConsumption fuelEmissionFactor:(CGFloat)fuelEmissionFactor
{
    self = [super init];
    if (self)
    {
        _fuelConsumption = fuelConsumption;
        _fuelEmissionFactor = fuelEmissionFactor;
    }
    return self;
}

- (BOOL)shouldCheckRegion
{
    return self == self.class.ELECTRIC;
}

+ (OAMotorType *)getMotorTypeByName:(NSString *)name
{
    if ([STR_PROP(PETROL) localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.PETROL;
    else if ([STR_PROP(DIESEL) localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.DIESEL;
    else if ([STR_PROP(LPG) localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.LPG;
    else if ([STR_PROP(GAS) localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.GAS;
    else if ([STR_PROP(ELECTRIC) localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.ELECTRIC;
    else if ([STR_PROP(HYBRID) localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.HYBRID;

    return nil;
}

+ (OAMotorType *)PETROL
{
    if (!PETROL)
        PETROL = [[OAMotorType alloc] initWithFuelConsumption:7.85f fuelEmissionFactor:2.80f];
    return PETROL;
}

+ (OAMotorType *)DIESEL
{
    if (!DIESEL)
        DIESEL = [[OAMotorType alloc] initWithFuelConsumption:6.59f fuelEmissionFactor:3.17f];
    return DIESEL;
}

+ (OAMotorType *)LPG
{
    if (!LPG)
        LPG = [[OAMotorType alloc] initWithFuelConsumption:10.60f fuelEmissionFactor:1.86f];
    return LPG;
}

+ (OAMotorType *)GAS
{
    if (!GAS)
        GAS = [[OAMotorType alloc] initWithFuelConsumption:4.90f fuelEmissionFactor:2.86f];
    return GAS;
}

+ (OAMotorType *)ELECTRIC
{
    if (!ELECTRIC)
        ELECTRIC = [[OAMotorType alloc] initWithFuelConsumption:21.1f fuelEmissionFactor:0.42f];
    return ELECTRIC;
}

+ (OAMotorType *)HYBRID
{
    if (!HYBRID)
        HYBRID = [[OAMotorType alloc] initWithFuelConsumption:5.61f fuelEmissionFactor:2.80f];
    return HYBRID;
}

@end

@implementation OAEmissionHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OATargetPointsHelper *_targetPointsHelper;
}

+ (OAEmissionHelper *)sharedInstance
{
    static OAEmissionHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAEmissionHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _targetPointsHelper = [OATargetPointsHelper sharedInstance];
    }
    return self;
}

- (OAMotorType *)getMotorTypeForMode:(OAApplicationMode *)mode
{
    std::shared_ptr<GeneralRouter> router = [_app getRouter:mode];
    if (router != nullptr && [mode getRouterService] == OSMAND)
    {
        RoutingParameter parameter = [OARoutingHelperUtils getParameterForDerivedProfile:@"motor_type" appMode:mode router:router];
        if (!parameter.id.empty())
        {
            OACommonString *pref = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:parameter.id.c_str()]
                                                          defaultValue:parameter.type == RoutingParameterType::NUMERIC ? kDefaultNumericValue : kDefaultSymbolicValue];

            ListParameters parameters = [self.class populateListParameters:parameter];
            int index = parameters.findIndexOfValue([pref get:mode].UTF8String);
            if (index != -1)
                return [OAMotorType getMotorTypeByName:[NSString stringWithUTF8String:parameters.names[index].c_str()]];
        }
    }
    return nil;
}

+ (ListParameters)populateListParameters:(RoutingParameter)parameter
{
    vector<double> vls = parameter.possibleValues;
    vector<string> sVls;
    for (int i = 0; i < vls.size(); i++)
    {
        double o = vls[i];
        sVls.push_back([NSString stringWithFormat:@"%.2f", o].UTF8String);
    }
    vector<string> descriptions = parameter.possibleValueDescriptions;
    vector<string> names;
    for (int j = 0; j < descriptions.size(); j++)
    {
        string name = descriptions[j];
        if (name.compare("-") == 0)
        {
            names.push_back(OALocalizedString(@"not_selected").UTF8String);
        }
        else
        {
            string key = name;
            transform(key.begin(), key.end(), key.begin(), ::tolower);
            regex_replace(key, regex(" "), "_");
            key = parameter.id + "_" + key;
            names.push_back([OAUtilities getRoutingStringPropertyName:[NSString stringWithUTF8String:key.c_str()]
                                                          defaultName:[NSString stringWithUTF8String:name.c_str()]].UTF8String);
        }
    }

    ListParameters lp{};
    lp.names = names;
    lp.values = sVls;
    return lp;
}

- (void)getEmission:(OAMotorType *)motorType meters:(CGFloat)meters listener:(id<OAEmissionHelperListener>)listener
{
    if ([motorType shouldCheckRegion])
    {
        CLLocation *latLon = [self getLatLon];
        if (latLon)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                OAWorldRegion *region = [_app.worldRegion findAtLat:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
                if (region)
                {
                    CGFloat emissionFactor = [self getEmissionFactorForRegion:region defaultEmissionFactor:motorType.fuelEmissionFactor];
                    NSString *result = [self getFormattedEmission:motorType meters:meters fuelEmissionFactor:emissionFactor];
                    if (listener)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [listener onSetupEmission:result];
                        });
                    }
                }
            });
        }
    }
    else if (listener)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *result = [self getFormattedEmission:motorType meters:meters fuelEmissionFactor:motorType.fuelEmissionFactor];
            [listener onSetupEmission:result];
        });
    }
}

- (NSString *)getFormattedEmission:(OAMotorType *)motorType meters:(CGFloat)meters fuelEmissionFactor:(float)fuelEmissionFactor
{
    CGFloat emissionsGramsByKm = motorType.fuelConsumption * fuelEmissionFactor * 10;
    double totalEmissionsKg = meters / 1000 * emissionsGramsByKm / 1000;
    NSString *emission = [NSString stringWithFormat:!fmod(round(totalEmissionsKg * 10) / 10, 1.0) ? @"%.0f" : @"%.1f", totalEmissionsKg];
    NSString *text = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), emission, OALocalizedString(@"kg")];
    text = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), @"~", text];
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), text, OALocalizedString(@"co2_mission")];
}

- (CGFloat)getEmissionFactorForRegion:(OAWorldRegion *)region defaultEmissionFactor:(float)defaultEmissionFactor
{
    if (region)
    {
        NSString *regionId = region.regionId;
        if ([regionId isEqualToString:kFranceRegionId])
            return 0.055f;
        else if ([regionId isEqualToString:kGermanyRegionId])
            return 0.4f;

        OAWorldRegion *parent = region.superregion;
        if (![parent isContinent])
            return [self getEmissionFactorForRegion:parent defaultEmissionFactor:defaultEmissionFactor];
    }
    return defaultEmissionFactor;
}

- (CLLocation *)getLatLon
{
    OARTargetPoint *targetPoint = [_targetPointsHelper getPointToStart];
//    if (!targetPoint)
//        targetPoint = [_targetPointsHelper getMyLocationToStart]
    return targetPoint != nil ? targetPoint.point : nil;
}

@end
