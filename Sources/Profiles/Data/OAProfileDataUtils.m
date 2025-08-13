//
//  OAProfileDataUtils.m
//  OsmAnd
//
//  Created by nnngrach on 28.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileDataUtils.h"
#import "OAProfileDataObject.h"
#import "OAApplicationMode.h"
#import "Localization.h"

@implementation OAProfileDataUtils

+ (NSArray<OAProfileDataObject *> *) getDataObjects:(NSArray<OAApplicationMode *> *)appModes
{
    NSMutableArray<OAProfileDataObject *> *profiles = [NSMutableArray new];
    for (OAApplicationMode *mode in appModes)
    {
        NSString *description = mode.descr;
        if (!description || description.length == 0)
            description = [self getAppModeDescription:mode];
        
        OAProfileDataObject *profile = [[OAProfileDataObject alloc] initWithStringKey:mode.stringKey name:[mode toHumanString] descr:description iconName:mode.getIconName isSelected:NO];
        profile.iconColor = mode.getIconColor;
        profile.customIconColor = mode.getCustomIconColor;
        [profiles addObject:profile];
    }
    return profiles;
}

+ (NSString *) getAppModeDescription:(OAApplicationMode *)mode
{
    return [mode isCustomProfile] ? OALocalizedString(@"profile_type_user_string") : OALocalizedString(@"profile_type_osmand_string");
}

@end
