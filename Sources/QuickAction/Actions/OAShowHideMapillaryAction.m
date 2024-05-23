//
//  OAShowHideMapillaryAction.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAShowHideMapillaryAction.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideMapillaryAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    if (OAIAPHelper.sharedInstance.mapillary.disabled)
        return;
    
    OAAppData *data = [OsmAndApp instance].data;
    [data setMapillary: !data.mapillary];
}

- (NSString *)getIconResName
{
    return @"ic_custom_mapillary_symbol";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_showhide_mapillary_descr");
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.mapillary;
}

- (NSString *)getActionStateName
{
    return [OsmAndApp instance].data.mapillary ? OALocalizedString(@"quick_action_mapillary_hide") : OALocalizedString(@"quick_action_mapillary_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideMapillaryActionId stringId:@"mapillary.showhide" cl:self.class] name:OALocalizedString(@"quick_action_showhide_mapillary_title")] iconName:@"ic_custom_mapillary_symbol"] category:EOAQuickActionTypeCategoryConfigureMap] nonEditable];
    return TYPE;
}

@end
