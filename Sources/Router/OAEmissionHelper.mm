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
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"

@interface OAListParameters : NSObject

@property (nonatomic, readonly) NSArray<NSString *> *names;
@property (nonatomic, readonly) NSArray<NSString *> *values;

- (instancetype)initWithNames:(NSArray<NSString *> *)names values:(NSArray<NSString *> *)values;

@end

@implementation OAListParameters

- (instancetype)initWithNames:(NSArray<NSString *> *)names values:(NSArray<NSString *> *)values
{
    self = [super init];
    if (self)
    {
        _names = names;
        _values = values;
    }
    return self;
}

- (NSInteger)findIndexOfValue:(NSString *)value
{
    if (value && value.length > 0 && _values.count > 0)
    {
        for (NSInteger i = 0; i < _values.count; i++)
        {
            if ([_values[i] isEqualToString:value])
                return i;
        }
    }
    return -1;
}

@end

static OAMotorType * PETROL;
static OAMotorType * DIESEL;
static OAMotorType * LPG;
static OAMotorType * GAS;
static OAMotorType * ELECTRIC;
static OAMotorType * HYBRID;

@implementation OAMotorType

- (instancetype)initWithName:(NSString *)name fuelConsumption:(CGFloat)fuelConsumption fuelEmissionFactor:(CGFloat)fuelEmissionFactor
{
    self = [super init];
    if (self)
    {
        _name = name;
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
    if ([PETROL.name localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.PETROL;
    else if ([DIESEL.name localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.DIESEL;
    else if ([LPG.name localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.LPG;
    else if ([GAS.name localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.GAS;
    else if ([ELECTRIC.name localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.ELECTRIC;
    else if ([HYBRID.name localizedCaseInsensitiveCompare:name] == NSOrderedSame)
        return self.class.HYBRID;

    return nil;
}

+ (OAMotorType *)PETROL
{
    if (!PETROL)
        PETROL = [[OAMotorType alloc] initWithName:@"petrol" fuelConsumption:7.85f fuelEmissionFactor:2.80f];
    return PETROL;
}

+ (OAMotorType *)DIESEL
{
    if (!DIESEL)
        DIESEL = [[OAMotorType alloc] initWithName:@"diesel" fuelConsumption:6.59f fuelEmissionFactor:3.17f];
    return DIESEL;
}

+ (OAMotorType *)LPG
{
    if (!LPG)
        LPG = [[OAMotorType alloc] initWithName:@"lpg" fuelConsumption:10.60f fuelEmissionFactor:1.86f];
    return LPG;
}

+ (OAMotorType *)GAS
{
    if (!GAS)
        GAS = [[OAMotorType alloc] initWithName:@"gas" fuelConsumption:4.90f fuelEmissionFactor:2.86f];
    return GAS;
}

+ (OAMotorType *)ELECTRIC
{
    if (!ELECTRIC)
        ELECTRIC = [[OAMotorType alloc] initWithName:@"electric" fuelConsumption:21.1f fuelEmissionFactor:0.42f];
    return ELECTRIC;
}

+ (OAMotorType *)HYBRID
{
    if (!HYBRID)
        HYBRID = [[OAMotorType alloc] initWithName:@"hybrid" fuelConsumption:5.61f fuelEmissionFactor:2.80f];
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

            OAListParameters *parameters = [self.class populateListParameters:parameter];
            NSInteger index = [parameters findIndexOfValue:[pref get:mode]];
            if (index != -1)
                return [OAMotorType getMotorTypeByName:parameters.names[index]];
        }
    }
    return nil;
}

+ (OAListParameters *)populateListParameters:(RoutingParameter)parameter
{
    vector<double> vls = parameter.possibleValues;
    NSMutableArray<NSString *> *sVls = [NSMutableArray array];
    for (int i = 0; i < vls.size(); i++)
    {
        double o = vls[i];
        [sVls addObject:[NSString stringWithFormat:@"%.2f", o]];
    }

    vector<string> descriptions = parameter.possibleValueDescriptions;
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (int j = 0; j < descriptions.size(); j++)
    {
        NSString *name = [NSString stringWithUTF8String:descriptions[j].c_str()];
        if ([name containsString:@"-"])
        {
            [names addObject:OALocalizedString(@"shared_string_not_selected")];
        }
        else
        {
            NSString *key = [NSString stringWithFormat:@"%@_%@",
                             [NSString stringWithUTF8String:parameter.id.c_str()],
                             [name.lowercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
            [names addObject:[OAUtilities getRoutingStringPropertyName:key defaultName:name]];
        }
    }

    return [[OAListParameters alloc] initWithNames:names values:sVls];
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
    return targetPoint != nil ? targetPoint.point : nil;
}

@end
