//
//  OAShowHidePressureAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHidePressureAction.h"
#import "OAQuickActionType.h"
#import "OsmAndApp.h"

static OAQuickActionType *TYPE;

@implementation OAShowHidePressureAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OsmAndAppInstance app = [OsmAndApp instance];
    app.data.weatherPressure = !app.data.weatherPressure;
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.weatherPressure;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"pressure_hide") : OALocalizedString(@"pressure_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
    {
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:37
                                                    stringId:@"weather.pressure.showhide"
                                                       class:self.class
                                                        name:OALocalizedString(@"toggle_pressure")
                                                    category:CONFIGURE_MAP
                                                    iconName:@"ic_custom_air_pressure"
                                           secondaryIconName:nil
                                                    editable:NO];
    }

    return TYPE;
}

@end