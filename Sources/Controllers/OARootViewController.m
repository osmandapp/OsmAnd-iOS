//
//  OARootViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OARootViewController.h"

#import "JASidePanelController.h"

@interface OARootViewController ()

@end

@implementation OARootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {  
        // Create panels
        [self setLeftPanel:[[OAOptionsPanelViewController alloc] initWithNibName:@"OptionsPanel" bundle:nil]];
        [self setCenterPanel:[[OAMapPanelViewController alloc] init]];
        //[self setRightPanel:[[OAContextPanelViewController alloc] initWithNibName:@"ContextPanel" bundle:nil]];
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // 80% of smallest device width in portait mode (320px)
    self.leftFixedWidth = 256;
    self.rightFixedWidth = 256;
    self.shouldResizeLeftPanel = YES;
    self.shouldResizeRightPanel = YES;
    
    // Initially disallow pan gesture to exclude interference with map
    // (it should be enabled after side panel is shown until it's not hidden)
    self.recognizesPanGesture = NO;
    
    // Allow rotation, without respect to current active panel
    self.shouldDelegateAutorotateToVisiblePanel = NO;
        
    //TEST:
    [self showLeftPanelAnimated:NO];
}

- (OAOptionsPanelViewController*)optionsPanel
{
    return (OAOptionsPanelViewController*)self.leftPanel;
}

- (OAMapPanelViewController*)mapPanel
{
    return (OAMapPanelViewController*)self.centerPanel;
}

- (OAContextPanelViewController*)contextPanel
{
    return (OAContextPanelViewController*)self.rightPanel;
}

@end
