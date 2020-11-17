//
//  OAShowHideTransportLinesAction.m
//  OsmAnd Maps
//
//  Created by nnngrach on 21.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAShowHideTransportLinesAction.h"
#import "OAPublicTransportOptionsBottomSheet.h"
#import "OAMapStyleSettings.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAQuickActionType.h"

#define KEY_DIALOG @"dialog"

static OAQuickActionType *TYPE;

@implementation OAShowHideTransportLinesAction
{
    OAMapStyleSettings* _styleSettings;
}

- (instancetype)init
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    BOOL wasCategoryEnabled = [_styleSettings isCategoryEnabled:@"transport"];
    [_styleSettings setCategoryEnabled:!wasCategoryEnabled categoryName:@"transport"];
    if (!wasCategoryEnabled && ![_styleSettings isCategoryEnabled:@"transport"])
        [self showDashboardMenu];
}

- (void)showDashboardMenu
{
    [[[OAPublicTransportOptionsBottomSheetViewController alloc] init] show];
}

- (BOOL)isActionWithSlash
{
    return [_styleSettings isCategoryEnabled:@"transport"];
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
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:4 stringId:@"transport.showhide" class:self.class name:OALocalizedString(@"toggle_public_transport") category:CONFIGURE_MAP iconName:@"ic_custom_transport_bus" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
