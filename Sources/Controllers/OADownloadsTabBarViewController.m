//
//  OADownloadsTabBarViewController.m
//  OsmAnd
//
//  Created by Feschenko Fedor on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsTabBarViewController.h"
#include "Localization.h"

@interface OADownloadsTabBarViewController ()

@end

@implementation OADownloadsTabBarViewController
{
    UIBarButtonItem* _refreshBarButton;
    NSUInteger _currentTabIndex;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _currentTabIndex = 0;
    
    // Do any additional setup after loading the view.
    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(refreshButtonClicked)];
    
    self.navigationItem.rightBarButtonItem = _refreshBarButton;
    
    self.title = OALocalizedString(@"Regions");
    
    UITabBarItem *tab = [self.tabBar.items objectAtIndex:0];
    tab.image = [UIImage imageNamed:@"tab_regions_icon.png"];
    tab.selectedImage = [UIImage imageNamed:@"tab_regions_icon_filled.png"];
    tab.title = OALocalizedString(@"Regions");
    
    tab = [self.tabBar.items objectAtIndex:1];
    tab.image = [UIImage imageNamed:@"tab_downloads_icon.png"];
    tab.selectedImage = [UIImage imageNamed:@"tab_downloads_icon_filled.png"];
    tab.title = OALocalizedString(@"Downloads");
    
    tab = [self.tabBar.items objectAtIndex:2];
    tab.image = [UIImage imageNamed:@"tab_updates_icon.png"];
    tab.selectedImage = [UIImage imageNamed:@"tab_updates_icon_filled.png"];
    tab.title = OALocalizedString(@"Updates");
    
    [self.refreshBtnDelegate onViewDidLoadAction:_refreshBarButton forTabBar:_currentTabIndex];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    self.title = item.title;
    
    _currentTabIndex = item.tag;
}

- (void)refreshButtonClicked
{
    [self.refreshBtnDelegate clickedOnRefreshButton:_refreshBarButton forTabBar:_currentTabIndex];
}

@end
