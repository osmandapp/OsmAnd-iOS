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
#import "OAQuickActionType.h"

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
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:1 stringId:@"new" class:self.class name:OALocalizedString(@"add_action") category:-1 iconName:@"ic_custom_add" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
