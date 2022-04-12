//
//  OAShowHidePrecipitationAction.h
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHidePrecipitationAction.h"
#import "OAQuickActionType.h"
#import "OsmAndApp.h"

static OAQuickActionType *TYPE;

@implementation OAShowHidePrecipitationAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OsmAndAppInstance app = [OsmAndApp instance];
    app.data.weatherPrecip = !app.data.weatherPrecip;
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.weatherPrecip;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"precipitation_hide") : OALocalizedString(@"precipitation_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
    {
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:40
                                                    stringId:@"weather.precipitation.showhide"
                                                       class:self.class
                                                        name:OALocalizedString(@"toggle_precipitation")
                                                    category:CONFIGURE_MAP
                                                    iconName:@"ic_custom_precipitation"
                                           secondaryIconName:nil
                                                    editable:NO];
    }

    return TYPE;
}

@end
