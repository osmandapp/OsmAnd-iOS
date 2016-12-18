//
//  OAFirstUsageWelcomeController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/11/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAFirstUsageWelcomeController.h"
#import "OAFirstUsageWizardController.h"
#import "Localization.h"

@interface OAFirstUsageWelcomeController ()

@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;

@end

@implementation OAFirstUsageWelcomeController

- (void)viewDidLoad {
    [super viewDidLoad];

    _lbDescription.text = OALocalizedString(@"first_usage_greeting");
    [_btnStart setTitle:OALocalizedString(@"get_started") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)startPress:(id)sender
{
    OAFirstUsageWizardController* wizard = [[OAFirstUsageWizardController alloc] init];
    [self.navigationController pushViewController:wizard animated:YES];
}

@end
