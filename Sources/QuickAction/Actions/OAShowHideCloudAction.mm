//
//  OAShowHideCloudAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideCloudAction.h"
#import "OAQuickActionType.h"
#import "OsmAndApp.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideCloudAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OsmAndAppInstance app = [OsmAndApp instance];
    app.data.weatherCloud = !app.data.weatherCloud;
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.weatherCloud;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"cloud_hide") : OALocalizedString(@"cloud_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
    {
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:39
                                                    stringId:@"weather.cloud.showhide"
                                                       class:self.class
                                                        name:OALocalizedString(@"toggle_cloud")
                                                    category:CONFIGURE_MAP
                                                    iconName:@"ic_custom_clouds"
                                           secondaryIconName:nil
                                                    editable:NO];
    }

    return TYPE;
}

@end
