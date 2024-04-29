//
//  OAAppVersion.m
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAppVersion.h"

@implementation OAAppVersion

+ (NSString *) getVersion
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return version;
}

+ (NSString *) getBuildVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (float) getVersionNumber
{
    return [self getNumber:self.getVersion];
}

+ (float) getBuildVersionNumber
{
    return [self getNumber:self.getBuildVersion];
}

+ (float) getNumber:(NSString *)version
{
    NSArray<NSString *> *parts = [version componentsSeparatedByString:@"."];
    NSMutableString *versionStr = [NSMutableString string];
    for (int i = 0; i < parts.count; i++)
    {
        NSString *num = parts[i];
        [versionStr appendString:num];
        if (i == 0)
            [versionStr appendString:@"."];
    }
    return versionStr.length > 0 ? [versionStr floatValue] : [version floatValue];
}

+ (NSString *) getVersionWithSeparator:(NSString *)separator
{
    NSString *fullVersion = self.getVersion;
    NSArray *subversions = [fullVersion componentsSeparatedByString:@"."];

    if (subversions && subversions.count > 1)
    {
        return [NSString stringWithFormat:@"%@%@%@", subversions[0], separator, subversions[1]];
    }
    return fullVersion;
}

+ (NSString *) getFullVersionWithAppName
{
    NSString *appVersion = self.getVersion;
    NSString *buildVersion = self.getBuildVersion;
    return [NSString stringWithFormat:@"OsmAnd Maps %@ (%@)", appVersion, buildVersion];
}

+ (NSString *) getVersionForUrl
{
    return [[NSString stringWithFormat:@"OsmAndIOS_%@", self.getVersion] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
