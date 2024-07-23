//
//  OANewAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANewAction.h"
#import "OAAddQuickActionViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAFloatingButtonsHudViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANewAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNewActionId
                                           stringId:@"new"
                                                 cl:self.class]
              name:OALocalizedString(@"quick_action_new_action")]
             iconName:@"ic_custom_add"]
            nonEditable];
}

- (void)execute
{
    QuickActionButtonState *quickActionButtonState = [[OARootViewController instance].mapPanel.hudViewController.floatingButtonsController getActiveButtonState];
    if (quickActionButtonState)
    {
        OAAddQuickActionViewController *addActionController = [[OAAddQuickActionViewController alloc] initWithButtonState:quickActionButtonState];
        [[OARootViewController instance].navigationController pushViewController:addActionController animated:YES];
    }
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
