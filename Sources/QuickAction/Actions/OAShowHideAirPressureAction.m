//
//  OAShowHidePressureAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideAirPressureAction.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideAirPressureAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideAirPressureLayerActionId
                                            stringId:@"pressure.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"pressure_layer")]
               nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_air_pressure"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

- (EOAWeatherBand)weatherBandIndex
{
    return WEATHER_BAND_PRESSURE;
}

@end
