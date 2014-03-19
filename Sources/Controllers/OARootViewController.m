//
//  OARootViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OARootViewController.h"

#import "JASidePanelController.h"
#import <QuartzCore/QuartzCore.h>

@interface OARootViewController ()

@end

@implementation OARootViewController
{
    UIStoryboard* _optionsPanelStoryboard;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {  
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    // Load storyboards
    _optionsPanelStoryboard = [UIStoryboard storyboardWithName:@"OptionsPanel" bundle:nil];
    
    // Create panels
    [self setLeftPanel:[_optionsPanelStoryboard instantiateInitialViewController]];
    [self setCenterPanel:[[OAMapPanelViewController alloc] init]];
    //[self setRightPanel:...];
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // 80% of smallest device width in portait mode (320 points)
    self.leftFixedWidth = 256;
    self.rightFixedWidth = 256;
    self.shouldResizeLeftPanel = YES;
    self.shouldResizeRightPanel = YES;
    
    // Initially disallow pan gesture to exclude interference with map
    // (it should be enabled after side panel is shown until it's not hidden)
    self.recognizesPanGesture = NO;
    
    // Allow rotation, without respect to current active panel
    self.shouldDelegateAutorotateToVisiblePanel = NO;
}

- (void)stylePanel:(UIView *)panel
{
    [super stylePanel:panel];
    
    // Setting corner radius on EGL layer will drop (or better to say, cap) framerate to 40 fps
    panel.layer.cornerRadius = 0.0f;
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
