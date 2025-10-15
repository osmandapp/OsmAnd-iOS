//
//  OAShowHideTemperatureAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideTemperatureAction.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideTemperatureAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideTemperatureLayerActionId
                                            stringId:@"temperature.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"temperature_layer")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_thermometer"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

- (EOAWeatherBand)weatherBandIndex
{
    return WEATHER_BAND_TEMPERATURE;
}

@end
