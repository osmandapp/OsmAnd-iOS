//
//  OAShowHideTemperatureAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideTemperatureAction.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideTemperatureAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideTemperatureLayerActionId
                                            stringId:@"temperature.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_temperature")]
              iconName:@"ic_custom_thermometer"]
             category:EOAQuickActionTypeCategoryConfigureMap]
            nonEditable];
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
    return TYPE;
}

@end
