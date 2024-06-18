//
//  UINavigationController+keyCommands.m
//  OsmAnd
//
//  Created by Skalii on 17.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "UINavigationController+keyCommands.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "OASuperViewController.h"
#import "OABaseBottomSheetViewController.h"
#import "OADashboardViewController.h"
#import "OAFloatingButtonsHudViewController.h"
#import "OAWeatherToolbar.h"
#import "OALog.h"

@implementation UINavigationController (keyCommands)

- (void)goBack
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == WUNDERLINQ_EXTERNAL_DEVICE)
    {
        //Launch WunderLINQ
        NSString *wunderlinqAppURL = @"wunderlinq://datagrid";
        BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:wunderlinqAppURL]];
        if (canOpenURL)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:wunderlinqAppURL] options:@{} completionHandler:nil];
    }
    else if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
    {
        UIViewController *vvc = self.visibleViewController;
        if ([vvc isKindOfClass:OASuperViewController.class])
        {
            [((OASuperViewController *) vvc) onLeftNavbarButtonPressed];
        }
        else if ([vvc isKindOfClass:OABaseBottomSheetViewController.class])
        {
            [((OABaseBottomSheetViewController *) vvc) hide:YES];
        }
        else if ([vvc isKindOfClass:OARootViewController.class])
        {
            OARootViewController *rvc = [OARootViewController instance];
            if (rvc.mapPanel.scrollableHudViewController)
                [rvc.mapPanel.scrollableHudViewController hide];
            else if ([rvc.mapPanel isDashboardVisible])
                [rvc.mapPanel closeDashboardLastScreen];
            else if ([rvc.mapPanel isRouteInfoVisible])
                [rvc.mapPanel closeRouteInfo];
            else if ([rvc.mapPanel.hudViewController.floatingButtonsController isActionSheetVisible])
                [rvc.mapPanel.hudViewController.floatingButtonsController hideActionsSheetAnimated:nil];
            else if ([rvc.mapPanel.hudViewController.mapInfoController weatherToolbarVisible])
                [rvc.mapPanel.hudViewController hideWeatherToolbarIfNeeded];
            else if ([rvc.mapPanel isContextMenuVisible])
                [rvc.mapPanel hideContextMenu];
        }
        else
        {
            if ([vvc presentingViewController])
                [self dismissViewControllerAnimated:YES completion:nil];
            else if ([[self presentingViewController] presentedViewController] == self)
                [self dismissViewControllerAnimated:YES completion:nil];
            else if ([[[vvc tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
                [self dismissViewControllerAnimated:YES completion:nil];
            else
                [self popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - UIResponder

- (NSArray<UIKeyCommand *> *)keyCommands
{
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(goBack)];
    command.wantsPriorityOverSystemBehavior = YES;
    return @[command];
}

@end
