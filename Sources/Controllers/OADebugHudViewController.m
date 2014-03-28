//
//  OADebugHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugHudViewController.h"

@interface OADebugHudViewController ()

@property (weak, nonatomic) IBOutlet UIView *_overlayContainer;
@property (weak, nonatomic) IBOutlet UITextView *_stateTextview;
@property (weak, nonatomic) IBOutlet UITextView *_outputTextview;

@end

@implementation OADebugHudViewController

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

- (IBAction)onDebugActionsButtonClicked:(id)sender
{
}

- (IBAction)onDebugPinOverlayButtonClicked:(id)sender
{
    self._overlayContainer.userInteractionEnabled = !self._overlayContainer.userInteractionEnabled;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
