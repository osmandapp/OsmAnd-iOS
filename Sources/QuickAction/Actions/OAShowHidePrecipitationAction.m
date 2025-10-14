//
//  OAShowHidePrecipitationAction.h
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHidePrecipitationAction.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHidePrecipitationAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHidePrecipitationLayerActionId
                                            stringId:@"precipitation.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"precipitation_layer")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_precipitation"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

- (EOAWeatherBand)weatherBandIndex
{
    return WEATHER_BAND_PRECIPITATION;
}

@end
