//
//  OAShowHideWindAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideWindAction.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideWindAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideWindLayerActionId
                                            stringId:@"wind.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_wind")]
              iconName:@"ic_custom_wind"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
