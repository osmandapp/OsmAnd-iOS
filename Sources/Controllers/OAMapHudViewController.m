//
//  OAMapHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapHudViewController.h"
#import "UIViewController+JASidePanel.h"

@interface OAMapHudViewController ()

@end

@implementation OAMapHudViewController

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

- (IBAction)onMapModeButtonClicked:(id)sender {
}

- (IBAction)onOptionsMenuButtonClicked:(id)sender {
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (IBAction)onCompassButtonClicked:(id)sender {
}
@end
