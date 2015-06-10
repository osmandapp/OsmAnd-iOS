//
//  OAMapSettingsViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OACommonTypes.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"

typedef enum
{
    EMapSettingsScreenUndefined = -1,
    EMapSettingsScreenMain = 0,
    EMapSettingsScreenGpx,
    EMapSettingsScreenMapType,
    EMapSettingsScreenCategory,
    EMapSettingsScreenParameter,
    EMapSettingsScreenSetting,
    EMapSettingsScreenOverlay,
    EMapSettingsScreenUnderlay,
    EMapSettingsScreenLanguage,
    EMapSettingsScreenPreferredLanguage,
    
} EMapSettingsScreen;


@interface OAMapSettingsViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *navbarBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *navbarBackgroundImg;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) OAMapSettingsViewController *parentVC;

-(void)deleteParentVC:(BOOL)deleteAll;

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation;
-(CGRect)contentViewFrame;

-(void)show:(UIViewController *)rootViewController parentViewController:(OAMapSettingsViewController *)parentViewController animated:(BOOL)animated;
-(void)hide:(BOOL)hideAll animated:(BOOL)animated;

-(instancetype)init;

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen;
-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param;

@end
