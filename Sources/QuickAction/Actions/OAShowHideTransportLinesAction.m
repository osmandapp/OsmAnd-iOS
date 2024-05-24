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
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideTransportLinesAction
{
    OAMapStyleSettings *_styleSettings;
}

+ (void)initialize
{
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideTransportLinesActionId
                                            stringId:@"transport.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_public_transport")]
              iconName:@"ic_custom_transport_bus"]
             category:EOAQuickActionTypeCategoryConfigureMap]
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

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
