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
        [self ctor];
    }
    return self;
}

- (void)ctor
{
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

- (void)awakeFromNib
{
    // 80% of smallest device width in portait mode (320px)
    self.leftFixedWidth = 256;
    self.rightFixedWidth = 256;
    self.shouldResizeLeftPanel = YES;
    self.shouldResizeRightPanel = YES;
    
    // Disallow gestures to exclude interference with map
    self.recognizesPanGesture = NO;
    
    // Allow rotation, without respect to current active panel
    self.shouldDelegateAutorotateToVisiblePanel = NO;
    
    // Create panels
    [self setLeftPanel:
        [self.storyboard instantiateViewControllerWithIdentifier:@"optionsPanelViewController"]];
    [self setCenterPanel:
        [self.storyboard instantiateViewControllerWithIdentifier:@"mapPanelViewController"]];
    [self setRightPanel:
        [self.storyboard instantiateViewControllerWithIdentifier:@"contextPanelViewController"]];
}

@end
