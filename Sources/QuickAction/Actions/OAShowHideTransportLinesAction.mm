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
    if ([_styleSettings isAllParametersHiddenForCategoryName:@"transport"])
    {
        [self showDashboardMenu];
        [_styleSettings setVisibility:YES forCategoryName:@"transport"];
        return;
    }
    
    [_styleSettings setVisibility:![_styleSettings getVisibilityForCategoryName:@"transport"] forCategoryName:@"transport"];
}

- (void)showDashboardMenu
{
    OAPublicTransportOptionsBottomSheetViewController *bottomSheet = [[OAPublicTransportOptionsBottomSheetViewController alloc] init];
    [bottomSheet show];
}

- (BOOL)isActionWithSlash
{
    return [_styleSettings getVisibilityForCategoryName:@"transport"] && ![_styleSettings isAllParametersHiddenForCategoryName:@"transport"];
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
