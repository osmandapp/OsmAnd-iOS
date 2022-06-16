//
//  OAShowHideTemperatureAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideTemperatureAction.h"
#import "OAQuickActionType.h"
#import "OsmAndApp.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideTemperatureAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OsmAndAppInstance app = [OsmAndApp instance];
    app.data.weatherTemp = !app.data.weatherTemp;
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.weatherTemp;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"temperature_hide") : OALocalizedString(@"temperature_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
    {
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:36
                                                    stringId:@"weather.temperature.showhide"
                                                       class:self.class
                                                        name:OALocalizedString(@"toggle_temperature")
                                                    category:CONFIGURE_MAP
                                                    iconName:@"ic_custom_thermometer"
                                           secondaryIconName:nil
                                                    editable:NO];
    }

    return TYPE;
}

@end
