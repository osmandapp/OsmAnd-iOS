//
//  OAOsmLoginMainViewController.m
//  OsmAnd
//
//  Created by Skalii on 01.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAOsmLoginMainViewController.h"
#import "OAOsmAccountSettingsViewController.h"
#import "Localization.h"

@interface OAOsmLoginMainViewController () <OAAccountSettingDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *cancelLabel;

@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIView *bottomButtonsContainerView;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@end

@implementation OAOsmLoginMainViewController

- (void)applyLocalization
{
    [self.cancelLabel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    self.titleLabel.text = OALocalizedString(@"login_open_street_map_org");
    self.descriptionLabel.text = OALocalizedString(@"open_street_map_login_mode");
    [self.topButton setTitle:OALocalizedString(@"sign_in_with_open_street_map") forState:UIControlStateNormal];
    [self.bottomButton setTitle:OALocalizedString(@"use_login_and_password") forState:UIControlStateNormal];
}

- (IBAction)onBottomButtonPressed:(id)sender
{
    OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
    accountSettings.accountDelegate = self;
    [self presentViewController:accountSettings animated:YES completion:nil];
}

#pragma mark - OAAccountSettingDelegate

- (void)onAccountInformationUpdated
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate)
            [self.delegate onAccountInformationUpdated];
    }];
}

@end
