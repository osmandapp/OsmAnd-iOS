//
//  OAShowHideWindAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideWindAction.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideWindAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OsmAndAppInstance app = [OsmAndApp instance];
    app.data.weatherWind = !app.data.weatherWind;
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.weatherWind;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"wind_hide") : OALocalizedString(@"wind_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideWindLayerActionId stringId:@"wind.layer.showhide" cl:self.class] name:OALocalizedString(@"toggle_wind")] iconName:@"ic_custom_wind"] category:EOAQuickActionTypeCategoryConfigureMap] nonEditable];
    return TYPE;
}

@end
