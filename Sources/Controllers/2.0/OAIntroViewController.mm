//
//  OAIntroViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIntroViewController.h"
#import "Localization.h"
#import "OAInitViewPanel.h"
#import "OsmAndApp.h"
#import "OAResourcesBaseViewController.h"
#import "OAManageResourcesViewController.h"




@interface OAIntroViewController ()

@end

@implementation OAIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.navigationController.navigationBarHidden = YES;
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated {

    OAInitViewPanel *panel1 = [[OAInitViewPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"OAInitViewPanel"];
    panel1.nextButton.layer.cornerRadius = 5;
    [panel1.nextButton setAlpha:1];
    
    OAInitViewPanel *panel2 = [[OAInitViewPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"OAInitViewPanel"];
    panel2.nextButton.layer.cornerRadius = 5;
    [panel2.nextButton setAlpha:1];
    [panel2.nextButton setTitle:@"Skip" forState:UIControlStateNormal];
    CGRect frame = panel2.labelView.frame;
    [panel2.labelView setFrame:frame];
    [panel2.labelView setText:@"Download Map"];
    [panel2.descriptionView setText:@""];
    [panel2.countryName setHidden:NO];
    UIImageView* searchImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    [searchImage setContentMode:UIViewContentModeCenter];
    [searchImage setImage:[UIImage imageNamed:@"search_icon"]];
    [panel2.countryName setLeftView: searchImage];
    [panel2.countryName setLeftViewMode:UITextFieldViewModeAlways];
    panel2.countryName.layer.cornerRadius = 5;
    panel2.countryName.delegate = self;
    
    NSArray *panels = @[panel1, panel2];
    //Create the introduction view and set its delegate
    MYBlurIntroductionView *introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, DeviceScreenWidth, DeviceScreenHeight)];
    [introductionView buildIntroductionWithPanels:panels];
    [introductionView setBackgroundColor:[UIColor orangeColor]];
    introductionView.delegate = self;
    [introductionView.RightSkipButton setTitle:@"" forState:UIControlStateNormal];
    introductionView.RightSkipButton = nil;
    
    //Add the introduction to your view
    [self.view addSubview:introductionView];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType {
    
    if (finishType == MYFinishTypeSwipeOut) {
        OAManageResourcesViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
        resourcesViewController.openFromSplash = YES;
        [self.navigationController pushViewController:resourcesViewController animated:YES];
        
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}



@end
