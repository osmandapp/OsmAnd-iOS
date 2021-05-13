//
//  OADonationSettingsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADonationSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATextInputCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAWorldRegion.h"
#import "OAIAPHelper.h"
#import "OANetworkUtilities.h"
#import <MBProgressHUD.h>

#include <OsmAndCore/WorldRegions.h>

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeTextInput @"text_input_cell"
#define kCellTypeCheck @"check"

@implementation OACountryItem

- (id) initWithLocalName:(NSString *)localName downloadName:(NSString *) downloadName
{
    self = [super init];
    if (self)
    {
        _localName = localName ? localName : @"";
        _downloadName = downloadName ? downloadName : kBillingUserDonationNone;
    }
    return self;
}

@end

@interface OADonationSettingsViewController () <UITextFieldDelegate>

@end

@implementation OADonationSettingsViewController
{
    NSArray *_headers;
    NSArray *_data;
    BOOL _donation;
    
    OASwitchTableViewCell *_donationSwitch;
    OASwitchTableViewCell *_hideNameSwitch;
    OATextInputCell *_emailCell;
    OATextInputCell *_userNameCell;
    UIView *_footerView;
    
    MBProgressHUD *_progressHUD;
    UITextField *_textFieldBeingEdited;

    OAAppSettings *_settings;
    
    OADonationSettingsViewController *_parentController;
}

- (id) init
{
    self = [super init];
    if (self)
    {
        _settingsType = EDonationSettingsScreenMain;
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (id) initWithSettingsType:(EDonationSettingsScreen)settingsType parentController:(OADonationSettingsViewController *)parentController
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
        _settings = [OAAppSettings sharedManager];
        _parentController = parentController;
    }
    return self;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"osmand_live_donations");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    _progressHUD.minShowTime = .5f;
    [self.view addSubview:_progressHUD];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    
    [self initCountries];
    NSString *countryDownloadName = _settings.billingUserCountryDownloadName;
    if (countryDownloadName.length == 0 || [countryDownloadName isEqualToString:kBillingUserDonationNone])
        _selectedCountryItem = _countryItems[0];
    else
        _selectedCountryItem = [self getCountryItem:countryDownloadName];
    
    _donation = ![countryDownloadName isEqualToString:kBillingUserDonationNone];

    if (_settingsType == EDonationSettingsScreenMain)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
        _donationSwitch = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        _donationSwitch.textView.numberOfLines = 0;
        _donationSwitch.textView.text = OALocalizedString(@"osmand_live_donation_switch_title");
        _donationSwitch.switchView.on = _donation;
        [_donationSwitch.switchView addTarget:self action:@selector(donationSwitchChanged:) forControlEvents:UIControlEventValueChanged];

        nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
        _hideNameSwitch = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        _hideNameSwitch.textView.numberOfLines = 0;
        _hideNameSwitch.textView.text = OALocalizedString(@"osm_live_hide_user_name");
        _hideNameSwitch.switchView.on = _settings.billingHideUserName;
        
        nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
        _emailCell = (OATextInputCell *)[nib objectAtIndex:0];
        _emailCell.inputField.text = _settings.billingUserEmail;
        _emailCell.inputField.placeholder = OALocalizedString(@"osmand_live_donations_enter_email");
        _emailCell.inputField.keyboardType = UIKeyboardTypeEmailAddress;
        _emailCell.inputField.delegate = self;

        nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
        _userNameCell = (OATextInputCell *)[nib objectAtIndex:0];
        _userNameCell.inputField.text = _settings.billingUserName;
        _userNameCell.inputField.placeholder = OALocalizedString(@"osmand_live_public_name");
        _userNameCell.inputField.delegate = self;

        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 55.0)];
        NSDictionary *attrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:16.0],
                                 NSForegroundColorAttributeName : [UIColor whiteColor] };
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_save") attributes:attrs];
        UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
        saveButton.userInteractionEnabled = YES;
        [saveButton setAttributedTitle:text forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(saveChanges:) forControlEvents:UIControlEventTouchUpInside];
        saveButton.backgroundColor = UIColorFromRGB(color_active_light);
        saveButton.layer.cornerRadius = 5;
        saveButton.frame = CGRectMake(10, 0, _footerView.frame.size.width - 20.0, 44.0);
        [_footerView addSubview:saveButton];
        
        self.tableView.tableFooterView = _footerView;
    }
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat btnMargin = MAX(10, [OAUtilities getLeftMargin]);
    _footerView.subviews[0].frame = CGRectMake(btnMargin, 0, _footerView.frame.size.width - btnMargin * 2, 44.0);
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    
    NSMutableArray *dataArr = [NSMutableArray array];
    NSMutableArray *headersArr = [NSMutableArray array];
    switch (_settingsType)
    {
        case EDonationSettingsScreenMain:
        {
            [headersArr addObject: @{ @"footer" : OALocalizedString(@"osmand_live_donation_switch_descr") }];
            [dataArr addObject:
             @[@{
                   @"name" : @"donation_switch",
                   @"title" : OALocalizedString(@"osmand_live_donation_switch_title"),
                   @"type" : kCellTypeSwitch }]
             ];

            [headersArr addObject: @{ @"header" : OALocalizedString(@"osmand_live_donation_header"),
                                      @"footer" : OALocalizedString(@"osmand_live_support_reg_descr") }];
            NSString *countryName = [_selectedCountryItem.downloadName isEqualToString:kBillingUserDonationNone] ? OALocalizedString(@"map_settings_none") : _selectedCountryItem.localName;
            [dataArr addObject:
             @[@{
                   @"name" : @"support_region",
                   @"title" : OALocalizedString(@"osmand_live_support_reg_title"),
                   @"value" : countryName,
                   @"img" : @"menu_cell_pointer",
                   @"type" : kCellTypeSingleSelectionList }]
             ];
            
            [headersArr addObject: @{ @"footer" : OALocalizedString(@"osmand_live_donations_email_descr") }];
            [dataArr addObject:
             @[@{
                   @"name" : @"email_input",
                   @"type" : kCellTypeTextInput }]
             ];
            
            [headersArr addObject: @{}];
            [dataArr addObject:
             @[@{
                   @"name" : @"public_name",
                   @"type" : kCellTypeTextInput },
               @{
                   @"name" : @"hide_name_switch",
                   @"title" : OALocalizedString(@"osm_live_hide_user_name"),
                   @"type" : kCellTypeSwitch }]
             ];
            break;
        }
        case EDonationSettingsScreenRegion:
        {
            NSMutableArray *countryArr = [NSMutableArray array];
            for (OACountryItem *item in _countryItems)
            {
                [countryArr addObject:
                 @{
                   @"title" : item.localName,
                   @"img" : [_parentController.selectedCountryItem.downloadName isEqualToString:item.downloadName] ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            [dataArr addObject:countryArr];
            
            break;
        }
        case EDonationSettingsScreenUndefined:
            break;
    }
    
    _headers = [NSArray arrayWithArray:headersArr];
    _data = [NSArray arrayWithArray:dataArr];
    [self.tableView reloadData];
}

- (void) initCountries
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAWorldRegion *root = app.worldRegion;
    NSMutableArray<OAWorldRegion *> *groups = [NSMutableArray new];
    [self processGroups:root nameList:groups];
    [groups sortUsingComparator:^NSComparisonResult(OAWorldRegion *  _Nonnull obj1, OAWorldRegion *  _Nonnull obj2) {
        if (obj1 == root) {
            return NSOrderedAscending;
        }
        if (obj2 == root) {
            return NSOrderedDescending;
        }
        return [[self getHumanReadableName:obj1] compare:[self getHumanReadableName:obj2]];
    }];
    NSMutableArray<OACountryItem *> *items = [NSMutableArray new];
    for (OAWorldRegion *region in groups)
    {
        if (region == root)
            [items addObject:[[OACountryItem alloc] initWithLocalName:[self getHumanReadableName:region] downloadName:@""]];
        else
            [items addObject:[[OACountryItem alloc] initWithLocalName:[self getHumanReadableName:region] downloadName:region.regionId]];
    }
    _countryItems = [NSArray arrayWithArray:items];
}

- (void) processGroups:(OAWorldRegion *)group nameList:(NSMutableArray<OAWorldRegion *> *)nameList
{
    if ([group.resourceTypes containsObject:@((int)OsmAnd::ResourcesManager::ResourceType::MapRegion)])
        [nameList addObject:group];
    
    if (group.subregions)
    {
        for (OAWorldRegion *subregion in group.subregions)
        {
            [self processGroups:subregion nameList:nameList];
        }
    }
}

- (OACountryItem *) getCountryItem:(NSString *)downloadName
{
    if (downloadName.length > 0)
        for (OACountryItem *item in _countryItems)
            if ([downloadName isEqualToString:item.downloadName])
                return item;
    
    return nil;
}

- (NSString *) getHumanReadableName:(OAWorldRegion *)region
{
    OAWorldRegion *worldRegion = [OsmAndApp instance].worldRegion;
    NSString *name = @"";
    if (region == worldRegion)
        name = OALocalizedString(@"res_world_region");
    else if ([region getLevel] > 2 || ([region getLevel] == 2
                                      && [region.superregion.regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()]))
    {
        OAWorldRegion *parent = region.superregion;
        OAWorldRegion *parentsParent = region.superregion.superregion;
        if ([region getLevel] == 3)
        {
            if ([parentsParent.regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()])
                name = [NSString stringWithFormat:@"%@ %@", parentsParent.name, region.name];
            else
                name = [NSString stringWithFormat:@"%@ %@", parent.name, region.name];
        }
        else
            name = [NSString stringWithFormat:@"%@ %@", parent.name, region.name];
    }
    else
        name = region.name;
    
    if (!name)
        name = @"";
    
    return name;
}

- (IBAction) backButtonClicked:(id)sender
{
    [super backButtonClicked:sender];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) donationSwitchChanged:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    BOOL isChecked = sw.on;
    _donation = isChecked;
}

- (void) saveChanges:(id)sender
{
    if ([self applySettings:_userNameCell.inputField.text email:_emailCell.inputField.text hideUserName:_hideNameSwitch.switchView.on])
    {
        if (_textFieldBeingEdited)
            [_textFieldBeingEdited resignFirstResponder];
        
        [_progressHUD show:YES];
        
        NSString *userId = _settings.billingUserId;
        if (userId.length != 0)
        {
            NSDictionary<NSString *, NSString *> *params = @{
                                                             @"os" : @"ios",
                                                             @"visibleName" : _settings.billingHideUserName ? @"" : _settings.billingUserName,
                                                             @"preferredCountry" : _settings.billingUserCountryDownloadName,
                                                             @"email" : _settings.billingUserEmail,
                                                             @"userid" : userId,
                                                             @"token" : _settings.billingUserToken,
                                                             };
            [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/update" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [_progressHUD hide:YES];

                     BOOL hasError = YES;
                     BOOL alertDisplayed = NO;
                     if (response && data)
                     {
                         @try
                         {
                             NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                             if (map)
                             {
                                 if (![map objectForKey:@"error"])
                                 {
                                     NSString *userId = [map objectForKey:@"userid"];
                                     NSLog(@"UserId = %@", userId);
                                     if (userId.length > 0)
                                     {
                                         _settings.billingUserId = userId;

                                         NSObject *email = [map objectForKey:@"email"];
                                         if (email)
                                             _settings.billingUserEmail = [email isKindOfClass:[NSString class]] ? (NSString *)email : @"";

                                         NSObject *visibleName = [map objectForKey:@"visibleName"];
                                         if (visibleName && [visibleName isKindOfClass:[NSString class]] && ((NSString *)visibleName).length > 0)
                                         {
                                             _settings.billingUserName = (NSString *)visibleName;
                                             _settings.billingHideUserName = NO;
                                         }
                                         else
                                         {
                                             _settings.billingHideUserName = YES;
                                         }
                                         NSObject *preferredCountryObj = [map objectForKey:@"preferredCountry"];
                                         if (preferredCountryObj && [preferredCountryObj isKindOfClass:[NSString class]])
                                             _settings.billingUserCountryDownloadName = (NSString *)preferredCountryObj;
                                     }
                                     hasError = NO;
                                     [self.navigationController popViewControllerAnimated:YES];
                                 }
                                 else
                                 {
                                     [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Error: %@", [map objectForKey:@"error"]] delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
                                     alertDisplayed = YES;
                                 }
                             }
                         }
                         @catch (NSException *e)
                         {
                             // ignore
                         }
                     }
                     if (hasError && !alertDisplayed)
                     {
                         [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"shared_string_io_error") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
                     }
                 });
             }];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"shared_string_io_error") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
        }
    }
}

- (BOOL) applySettings:(NSString *)userName email:(NSString *)email hideUserName:(BOOL)hideUserName
{
    NSString *countryName;
    NSString *countryDownloadName;
    if (!_donation)
    {
        countryName = @"";
        countryDownloadName = kBillingUserDonationNone;
    }
    else
    {
        countryName = _selectedCountryItem.localName;
        countryDownloadName = _selectedCountryItem.downloadName;
        if (email.length == 0 || ![email isValidEmail])
        {
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"osm_live_enter_email") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            return NO;
        }
        if (userName.length == 0 && !_settings.billingHideUserName)
        {
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"osm_live_enter_user_name") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            return NO;
        }
    }
    
    [_settings setBillingUserName:userName];
    [_settings setBillingUserEmail:email];
    [_settings setBillingUserCountry:countryName];
    [_settings setBillingUserCountryDownloadName:countryDownloadName];
    [_settings setBillingHideUserName:hideUserName];
    
    return YES;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [_tableView reloadData];
        [self applySafeAreaMargins];
    } completion:nil];
}

#pragma mark - UITableViewDataSource

 - (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _settingsType == EDonationSettingsScreenMain ? _data.count : 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data[section] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];

    if ([type isEqualToString:kCellTypeSwitch])
    {
        if ([item[@"name"] isEqualToString:@"donation_switch"])
            return _donationSwitch;
        else if ([item[@"name"] isEqualToString:@"hide_name_switch"])
            return _hideNameSwitch;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList])
    {
        OASettingsTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeTextInput])
    {
        if ([item[@"name"] isEqualToString:@"email_input"])
            return _emailCell;
        if ([item[@"name"] isEqualToString:@"public_name"])
            return _userNameCell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        OASettingsTitleTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == EDonationSettingsScreenMain)
        return _headers[section][@"header"];
    
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == EDonationSettingsScreenMain)
        return _headers[section][@"footer"];
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"name"] isEqualToString:@"support_region"])
    {
        OADonationSettingsViewController *regionsScreen = [[OADonationSettingsViewController alloc] initWithSettingsType:EDonationSettingsScreenRegion parentController:self];
        [self.navigationController pushViewController:regionsScreen animated:YES];
    }
    else if ([item[@"type"] isEqualToString:kCellTypeCheck])
    {
        if (_parentController)
            _parentController.selectedCountryItem = _countryItems[indexPath.row];

        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    _textFieldBeingEdited = textField;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    _textFieldBeingEdited = nil;
}

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

@end
