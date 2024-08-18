//
//  OAShowHideTransportLinesAction.m
//  OsmAnd Maps
//
//  Created by nnngrach on 21.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAShowHideTransportLinesAction.h"
#import "OAPublicTransportOptionsBottomSheet.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideTransportLinesAction
{
    OAMapStyleSettings *_styleSettings;
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideTransportLinesActionId
                                            stringId:@"transport.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"poi_filter_public_transport")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_transport_bus"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)commonInit
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
}

- (void)execute
{
    BOOL wasCategoryEnabled = [_styleSettings isCategoryEnabled:TRANSPORT_CATEGORY];
    [_styleSettings setCategoryEnabled:!wasCategoryEnabled categoryName:TRANSPORT_CATEGORY];
    if (!wasCategoryEnabled && ![_styleSettings isCategoryEnabled:TRANSPORT_CATEGORY])
        [self showDashboardMenu];
}

- (void)showDashboardMenu
{
    [[[OAPublicTransportOptionsBottomSheetViewController alloc] init] show];
}

- (BOOL)isActionWithSlash
{
    return [_styleSettings isCategoryEnabled:TRANSPORT_CATEGORY];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"public_transport_hide") : OALocalizedString(@"public_transport_show");
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_transport_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
