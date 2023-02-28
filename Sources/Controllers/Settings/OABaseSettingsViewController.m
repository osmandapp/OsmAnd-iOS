//
//  OABaseSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAApplicationMode.h"
#import "Localization.h"

#define kSidePadding 20

@implementation OABaseSettingsViewController

#pragma mark - Initialization

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        [self postInit];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getSubtitle
{
    return [_appMode toHumanString];
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged
{
    [self.tableView reloadData];
}

@end
