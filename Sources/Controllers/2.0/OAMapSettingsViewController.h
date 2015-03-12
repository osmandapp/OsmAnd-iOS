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
#import "OAGPXDocumentPrimitives.h"

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
    
} EMapSettingsScreen;


@interface OAMapSettingsViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *mapView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL goToMap;
@property (nonatomic, assign) OAGpxBounds goToBounds;
@property (nonatomic, readonly) BOOL isPopup;

@property (nonatomic) UIViewController *parentVC;

-(void)deleteParentVC:(BOOL)deleteAll;

-(CGRect)viewFramePopup;

-(void)showPopupAnimated:(UIViewController *)rootViewController parentViewController:(UIViewController *)parentViewController;
-(void)hidePopup:(BOOL)hideAll;

-(instancetype)initPopup;

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen popup:(BOOL)popup;
-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param popup:(BOOL)popup;

@end
