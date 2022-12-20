//
//  OARoutingHelperUtils.m
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OARoutingHelperUtils.h"
#import "OARoutePreferencesParameters.h"
#import "OAApplicationMode.h"

#define CACHE_RADIUS 100000

@implementation OARoutingHelperUtils

+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards
{
    NSMutableString *formattedStreetName = [NSMutableString string];
    if (ref != nil && ref.length > 0)
        [formattedStreetName appendString:ref];
    if (name != nil && name.length > 0)
    {
        if (formattedStreetName.length > 0)
            [formattedStreetName appendString:@" "];
        [formattedStreetName appendString:name];
    }
    if (destination != nil && destination.length > 0)
    {
        if (formattedStreetName.length > 0)
            [formattedStreetName appendString:@" "];
        [formattedStreetName appendFormat:@"%@ %@", towards, destination];
    }
    [formattedStreetName replaceOccurrencesOfString:@";" withString:@", " options:0 range:NSMakeRange(0, formattedStreetName.length)];
    return formattedStreetName;
}


+ (RoutingParameter)getParameterForDerivedProfile:(NSString *)key appMode:(OAApplicationMode *)appMode router:(std::shared_ptr<GeneralRouter>)router
{
    return [self getParametersForDerivedProfile:appMode router:router][key.UTF8String];
}

+ (map<string, RoutingParameter>) getParametersForDerivedProfile:(OAApplicationMode *)appMode router:(std::shared_ptr<GeneralRouter>)router
{
    NSString *derivedProfile = [appMode getDerivedProfile];
    map<string, RoutingParameter> parameters;
    auto& params = router->getParameters();
    for (auto it = params.begin(); it != params.end(); ++it)
    {
        vector<string> profiles = it->second.profiles;
        if (profiles.empty() || std::find(profiles.begin(), profiles.end(), derivedProfile.UTF8String) != profiles.end())
            parameters[it->first] = it->second;
    }

    return parameters;
}

@end
