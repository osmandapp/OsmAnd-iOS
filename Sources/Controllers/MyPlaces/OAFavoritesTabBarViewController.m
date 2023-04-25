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
#import "OAColors.h"

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
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    self.tabBar.standardAppearance = appearance;
    self.tabBar.scrollEdgeAppearance = appearance;
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColorFromRGB(color_primary_orange_navbar_background);
    appearance.shadowColor = UIColorFromRGB(color_primary_orange_navbar_background);
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : UIColor.whiteColor
    };
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.searchController = nil;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)applyLocalization
{
    [[self.viewControllers objectAtIndex:0] setTitle:OALocalizedString(@"favorites_item")];
    [[self.viewControllers objectAtIndex:1] setTitle: OALocalizedString(@"shared_string_gpx_tracks")];
    if (self.viewControllers.count > 2)
        [[self.viewControllers objectAtIndex:2] setTitle: OALocalizedString(@"osm_edits_title")];
}

@end
