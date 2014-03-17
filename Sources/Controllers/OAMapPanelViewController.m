//
//  OAMapPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapPanelViewController.h"

#import "OAMapModeHudViewController.h"

@interface OAMapPanelViewController ()

@end

@implementation OAMapPanelViewController

@synthesize rendererViewController = _rendererViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    NSLog(@"Creating Map Panel views...");
    
    // Create root view
    UIView* rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view = rootView;
    
    // Instantiate map renderer
    _rendererViewController = [[OAMapRendererViewController alloc] init];
    [self addChildViewController:_rendererViewController];
    [_rendererViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_rendererViewController.view];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[view]|"
                               options:0
                               metrics:nil
                               views:@{@"view":_rendererViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[view]|"
                               options:0
                               metrics:nil
                               views:@{@"view":_rendererViewController.view}]];
    
    // Instantiate map HUD
    UIViewController* mapHudVC = [[OAMapModeHudViewController alloc] initWithNibName:@"MapModeHUD" bundle:nil];
    [self addChildViewController:mapHudVC];
    [mapHudVC.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:mapHudVC.view];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[view]|"
                               options:0
                               metrics:nil
                               views:@{@"view":mapHudVC.view}]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[view]|"
                               options:0
                               metrics:nil
                               views:@{@"view":mapHudVC.view}]];
}

@end
