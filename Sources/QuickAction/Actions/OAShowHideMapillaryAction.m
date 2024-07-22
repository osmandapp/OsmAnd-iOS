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

static QuickActionType *TYPE;

@implementation OAShowHideMapillaryAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideMapillaryActionId
                                            stringId:@"mapillary.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"mapillary")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_mapillary_symbol"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
