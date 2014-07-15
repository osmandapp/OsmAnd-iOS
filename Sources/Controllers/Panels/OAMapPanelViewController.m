//
//  OAMapPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapPanelViewController.h"

#import "OABrowseMapModeHudViewController.h"
#import "OALog.h"

#define _(name) OAMapPanelViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OAMapPanelViewController ()

@end

@implementation OAMapPanelViewController

@synthesize mapViewController = _mapViewController;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    OALog(@"Creating Map Panel views...");
    
    // Create root view
    UIView* rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view = rootView;
    
    // Instantiate map renderer
    _mapViewController = [[OAMapViewController alloc] init];
    [self addChildViewController:_mapViewController];
    [_mapViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_mapViewController.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
    
    // Instantiate map HUD
    UIViewController* mapHudVC = [[OABrowseMapModeHudViewController alloc] initWithNibName:@"BrowseMapModeHUD"
                                                                              bundle:nil];
    [self addChildViewController:mapHudVC];
    [mapHudVC.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:mapHudVC.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":mapHudVC.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":mapHudVC.view}]];
}

@end
