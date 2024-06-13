//
//  OAShowHidePressureAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideAirPressureAction.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideAirPressureAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideAirPressureLayerActionId
                                            stringId:@"pressure.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_pressure")]
              iconName:@"ic_custom_air_pressure"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
