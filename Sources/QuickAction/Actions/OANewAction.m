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

@implementation OANewAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeNew];
}

- (void)execute
{
    OAAddQuickActionViewController *addActionController = [[OAAddQuickActionViewController alloc] init];
    [[OARootViewController instance].navigationController pushViewController:addActionController animated:YES];
}

@end
