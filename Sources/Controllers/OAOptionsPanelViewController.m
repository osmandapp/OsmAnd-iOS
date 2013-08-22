//
//  OAOptionsPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelViewController.h"

#import "UIViewController+OARootVC.h"

@interface OAOptionsPanelViewController ()

@end

@implementation OAOptionsPanelViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)activateMapnik:(id)sender {
    
    [self.rootViewController.mapPanel.rendererViewController activateMapnik];
    
}
- (IBAction)activateCyclemap:(id)sender {
    [self.rootViewController.mapPanel.rendererViewController activateCyclemap];
}
- (IBAction)activateOffline:(id)sender {
    [self.rootViewController.mapPanel.rendererViewController activateOffline];
}

@end
