//
//  OAShowHideCloudAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideCloudAction.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideCloudAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideCloudLayerActionId
                                            stringId:@"cloud.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"cloud_layer")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              category:QuickActionTypeCategoryConfigureMap]
             iconName:@"ic_custom_clouds"]
            nonEditable];
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

- (EOAWeatherBand)weatherBandIndex
{
    return WEATHER_BAND_CLOUD;
}

@end
