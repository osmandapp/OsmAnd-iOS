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
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OANewAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAddQuickActionViewController *addActionController = [[OAAddQuickActionViewController alloc] init];
    [[OARootViewController instance].navigationController pushViewController:addActionController animated:YES];
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsNewActionId stringId:@"new" cl:self.class] name:OALocalizedString(@"quick_action_new_action")] iconName:@"ic_custom_add"] nonEditable];
    return TYPE;
}

@end
