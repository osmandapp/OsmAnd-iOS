//
//  OADownloadsTabBarController.m
//  OsmAnd
//
//  Created by Feschenko Fedor on 6/15/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "RDVTabBarItem.h"

#import "OADownloadsTabBarController.h"
#import "OAShowDownloadsViewController.h"
#import "OAShowUpdatesViewController.h"

#include "Localization.h"

@interface OADownloadsTabBarController ()

@end

@implementation OADownloadsTabBarController
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
    
    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(refreshButtonClicked)];
    
    [self.refreshBtnDelegate onViewDidLoadAction:_refreshBarButton forTabBar:_currentTabIndex];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    

    [self setupViewControllers];
    self.selectedIndex = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupViewControllers {
    
    UIViewController *firstViewController = [[UIStoryboard storyboardWithName:@"Downloads" bundle:nil] instantiateInitialViewController];
    firstViewController.view.frame = CGRectMake(0, 0, firstViewController.view.frame.size.width, 200);
    
    OAShowDownloadsViewController *secondViewController = [[OAShowDownloadsViewController alloc] init];
    
    secondViewController.view.frame = CGRectMake(0, 0, secondViewController.view.frame.size.width, 200);
    
    OAShowUpdatesViewController *thirdViewController = [[OAShowUpdatesViewController alloc] initWithNibName:@"OAShowUpdatesViewController" bundle:nil];

    [self setViewControllers:@[firstViewController, secondViewController,
                                           thirdViewController]];
    
    [self customizeTabBar];
}

- (void)customizeTabBar
{
    NSArray *tabBarItemImages = @[@"tab_regions_icon", @"tab_downloads_icon", @"tab_updates_icon"];
    NSArray *tabBarItemTitles = @[OALocalizedString(@"Regions"), OALocalizedString(@"Downloads"), OALocalizedString(@"Updates")];
    
    NSInteger index = 0;
    for (RDVTabBarItem *aTabBarItem in [[self tabBar] items])
    {
        [aTabBarItem setTitle:[tabBarItemTitles objectAtIndex:index]];
        UIImage *selectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_filled",
                                                      [tabBarItemImages objectAtIndex:index]]];
        UIImage *unselectedimage = [UIImage imageNamed:[tabBarItemImages objectAtIndex:index]];
        [aTabBarItem setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        
        aTabBarItem.tintColor = [UIColor blueColor];
        
        index++;
    }
}

- (void)refreshButtonClicked
{
    [self.refreshBtnDelegate clickedOnRefreshButton:_refreshBarButton forTabBar:_currentTabIndex];
}

#pragma mark - 

- (BOOL)tabBar:(RDVTabBar *)tabBar shouldSelectItemAtIndex:(NSInteger)index
{
    BOOL returnValue = [super tabBar:tabBar shouldSelectItemAtIndex:index];
    
    self.title = ((RDVTabBarItem *)[tabBar.items objectAtIndex:index]).title;
    
    return returnValue;
}

- (void)tabBar:(RDVTabBar *)tabBar didSelectItemAtIndex:(NSInteger)index
{
    [super tabBar:tabBar didSelectItemAtIndex:index];
    
    _currentTabIndex = index;
}

@end
