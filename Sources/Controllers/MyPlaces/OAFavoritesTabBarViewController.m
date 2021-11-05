//
//  OAFavoritesTabBarViewController.m
//  OsmAnd
//
//  Created by Paul on 4/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAFavoritesTabBarViewController.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@implementation OAFavoritesTabBarViewController

- (void)viewDidLoad
{
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    if (!iapHelper.osmEditing.isActive)
    {
        NSMutableArray *newTabs = [NSMutableArray arrayWithArray:self.viewControllers];
        [newTabs removeObjectAtIndex: 2];
        [self setViewControllers:newTabs];
    }
    [self applyLocalization];
    [super viewDidLoad];
}

-(void)applyLocalization
{
    [[self.viewControllers objectAtIndex:0] setTitle:OALocalizedString(@"favorites")];
    [[self.viewControllers objectAtIndex:1] setTitle: OALocalizedString(@"tracks")];
    if (self.viewControllers.count > 2)
        [[self.viewControllers objectAtIndex:2] setTitle: OALocalizedString(@"osm_edits_title")];
    
}

@end
