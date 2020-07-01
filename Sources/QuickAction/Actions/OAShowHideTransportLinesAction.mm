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
#import "OAPublicTransportStyleSettingsHelper.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAQuickActionType.h"

#define KEY_DIALOG @"dialog"

static OAQuickActionType *TYPE;

@implementation OAShowHideTransportLinesAction
{
    OAPublicTransportStyleSettingsHelper* _transportSettings;
}

- (instancetype)init
{
    _transportSettings = [OAPublicTransportStyleSettingsHelper sharedInstance];
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    if ([_transportSettings isAllTransportStylesHidden])
    {
        [self showDashboardMenu];
        [_transportSettings setVisibilityForTransportLayer:YES];
        return;
    }

    [_transportSettings toggleVisibilityForTransportLayer];
}

- (void)showDashboardMenu
{
    OAPublicTransportOptionsBottomSheetViewController *bottomSheet = [[OAPublicTransportOptionsBottomSheetViewController alloc] init];
    [bottomSheet show];
}

- (BOOL)isActionWithSlash
{
    return [_transportSettings getVisibilityForTransportLayer] && ![_transportSettings isAllTransportStylesHidden];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"public_transport_hide") : OALocalizedString(@"public_transport_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:4 stringId:@"public_transport.showhide" class:self.class name:OALocalizedString(@"toggle_public_transport") category:CONFIGURE_MAP iconName:@"ic_custom_transport_bus" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
