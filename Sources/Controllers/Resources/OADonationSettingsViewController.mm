//
//  OADonationSettingsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADonationSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAWorldRegion.h"
#import "OAIAPHelper.h"
#import "OANetworkUtilities.h"
#import "OALog.h"
#import <MBProgressHUD.h>

#include <OsmAndCore/WorldRegions.h>

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeTextInput @"text_input_cell"
#define kCellTypeCheck @"check"

@implementation OACountryItem

- (instancetype)initWithLocalName:(NSString *)localName downloadName:(NSString *) downloadName
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
    OAInputTableViewCell *_emailCell;
    OAInputTableViewCell *_userNameCell;
    
    MBProgressHUD *_progressHUD;
    UITextField *_textFieldBeingEdited;

    OAAppSettings *_settings;
    
    OADonationSettingsViewController *_parentController;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _settingsType = EDonationSettingsScreenMain;
    }
    return self;
}

- (instancetype)initWithSettingsType:(EDonationSettingsScreen)settingsType parentController:(OADonationSettingsViewController *)parentController
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
        _parentController = parentController;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    _progressHUD.minShowTime = .5f;
    [self.view addSubview:_progressHUD];

    if (_settingsType == EDonationSettingsScreenMain)
        [self setupTableViewCells];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    switch (_settingsType)
    {
        case EDonationSettingsScreenMain:
            return OALocalizedString(@"donations");
        case EDonationSettingsScreenRegion:
            return OALocalizedString(@"osm_live_support_region");
        case EDonationSettingsScreenUndefined:
            break;
    }
    return @"";
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getBottomButtonTitle
{
    return _settingsType == EDonationSettingsScreenMain ? OALocalizedString(@"shared_string_save") : @"";
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemePurple;
}

#pragma mark - Table data

- (void)generateData
{
    [self initCountries];

    NSString *countryDownloadName = _settings.billingUserCountryDownloadName.get;
    if (countryDownloadName.length == 0 || [countryDownloadName isEqualToString:kBillingUserDonationNone])
        _selectedCountryItem = _countryItems[0];
    else
        _selectedCountryItem = [self getCountryItem:countryDownloadName];
    
    _donation = ![countryDownloadName isEqualToString:kBillingUserDonationNone];
    
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
            NSString *countryName = [_selectedCountryItem.downloadName isEqualToString:kBillingUserDonationNone] ? OALocalizedString(@"shared_string_none") : _selectedCountryItem.localName;
            [dataArr addObject:
                 @[@{
                     @"name" : @"support_region",
                     @"title" : OALocalizedString(@"osm_live_support_region"),
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

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSInteger)sectionsCount
{
    return _settingsType == EDonationSettingsScreenMain ? _data.count : 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (_settingsType == EDonationSettingsScreenMain)
        return _headers[section][@"header"];
    
    return nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (_settingsType == EDonationSettingsScreenMain)
        return _headers[section][@"footer"];
    
    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data[section] count];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
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
        OAValueTableViewCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (cell)
        {
            [cell.titleLabel setText: item[@"title"]];
            [cell.valueLabel setText: item[@"value"]];
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
        OASimpleTableViewCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        
        if (cell)
        {
            [cell.titleLabel setText: item[@"title"]];
            if ([item[@"img"] length] > 0)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
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

#pragma mark - Additions

- (void)setupTableViewCells
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
    _donationSwitch = (OASwitchTableViewCell *) nib[0];
    [_donationSwitch leftIconVisibility:NO];
    [_donationSwitch descriptionVisibility:NO];
    _donationSwitch.titleLabel.numberOfLines = 0;
    _donationSwitch.titleLabel.text = OALocalizedString(@"osmand_live_donation_switch_title");
    _donationSwitch.switchView.on = _donation;
    [_donationSwitch.switchView addTarget:self action:@selector(donationSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
    _hideNameSwitch = (OASwitchTableViewCell *) nib[0];
    [_hideNameSwitch leftIconVisibility:NO];
    [_hideNameSwitch descriptionVisibility:NO];
    _hideNameSwitch.titleLabel.numberOfLines = 0;
    _hideNameSwitch.titleLabel.text = OALocalizedString(@"osm_live_hide_user_name");
    _hideNameSwitch.switchView.on = _settings.billingHideUserName.get;
    
    nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
    _emailCell = (OAInputTableViewCell *) nib[0];
    [_emailCell leftIconVisibility:NO];
    [_emailCell titleVisibility:NO];
    [_emailCell clearButtonVisibility:NO];
    _emailCell.inputField.textAlignment = NSTextAlignmentNatural;
    _emailCell.inputField.text = _settings.billingUserEmail.get;
    _emailCell.inputField.placeholder = OALocalizedString(@"osmand_live_donations_enter_email");
    _emailCell.inputField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailCell.inputField.delegate = self;

    nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
    _userNameCell = (OAInputTableViewCell *) nib[0];
    [_userNameCell leftIconVisibility:NO];
    [_userNameCell titleVisibility:NO];
    [_userNameCell clearButtonVisibility:NO];
    _userNameCell.inputField.textAlignment = NSTextAlignmentNatural;
    _userNameCell.inputField.text = _settings.billingUserName.get;
    _userNameCell.inputField.placeholder = OALocalizedString(@"osmand_live_public_name");
    _userNameCell.inputField.delegate = self;
}

- (void)initCountries
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

- (void)processGroups:(OAWorldRegion *)group nameList:(NSMutableArray<OAWorldRegion *> *)nameList
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

- (OACountryItem *)getCountryItem:(NSString *)downloadName
{
    if (downloadName.length > 0)
        for (OACountryItem *item in _countryItems)
            if ([downloadName isEqualToString:item.downloadName])
                return item;
    
    return nil;
}

- (NSString *)getHumanReadableName:(OAWorldRegion *)region
{
    OAWorldRegion *worldRegion = [OsmAndApp instance].worldRegion;
    NSString *name = @"";
    if (region == worldRegion)
        name = OALocalizedString(@"shared_string_world");
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

- (BOOL)applySettings:(NSString *)userName email:(NSString *)email hideUserName:(BOOL)hideUserName
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
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:nil
                                                                   message:OALocalizedString(@"osm_live_enter_email")
                                                            preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                          style:UIAlertActionStyleDefault
                        handler:nil];
            [alertController addAction:okAction];

            [self presentViewController:alertController animated:YES completion:nil];
            return NO;
        }
        if (userName.length == 0 && !_settings.billingHideUserName.get)
        {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:nil
                                                                   message:OALocalizedString(@"osm_live_enter_user_name")
                                                            preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                          style:UIAlertActionStyleDefault
                        handler:nil];
            [alertController addAction:okAction];

            [self presentViewController:alertController animated:YES completion:nil];
            return NO;
        }
    }
    
    [_settings.billingUserName set:userName];
    [_settings.billingUserEmail set:email];
    [_settings.billingUserCountry set:countryName];
    [_settings.billingUserCountryDownloadName set:countryDownloadName];
    [_settings.billingHideUserName set:hideUserName];
    
    return YES;
}

#pragma mark - Selectors

- (void)donationSwitchChanged:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    BOOL isChecked = sw.on;
    _donation = isChecked;
}

- (void)onBottomButtonPressed
{
    if ([self applySettings:_userNameCell.inputField.text email:_emailCell.inputField.text hideUserName:_hideNameSwitch.switchView.on])
    {
        if (_textFieldBeingEdited)
            [_textFieldBeingEdited resignFirstResponder];
        
        [_progressHUD show:YES];
        
        NSString *userId = _settings.billingUserId.get;
        if (userId.length != 0)
        {
            NSDictionary<NSString *, NSString *> *params = @{
                @"os" : @"ios",
                @"visibleName" : _settings.billingHideUserName.get ? @"" : _settings.billingUserName.get,
                @"preferredCountry" : _settings.billingUserCountryDownloadName.get,
                @"email" : _settings.billingUserEmail.get,
                @"userid" : userId,
                @"token" : _settings.billingUserToken.get,
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
                                    OALog(@"UserId = %@", userId);
                                    if (userId.length > 0)
                                    {
                                        [_settings.billingUserId set:userId];
                                        
                                        NSObject *email = [map objectForKey:@"email"];
                                        if (email)
                                            [_settings.billingUserEmail set:[email isKindOfClass:[NSString class]] ? (NSString *)email : @""];
                                        
                                        NSObject *visibleName = [map objectForKey:@"visibleName"];
                                        if (visibleName && [visibleName isKindOfClass:[NSString class]] && ((NSString *)visibleName).length > 0)
                                        {
                                            [_settings.billingUserName set:(NSString *)visibleName];
                                            [_settings.billingHideUserName set:NO];
                                        }
                                        else
                                        {
                                            [_settings.billingHideUserName set:YES];
                                        }
                                        NSObject *preferredCountryObj = [map objectForKey:@"preferredCountry"];
                                        if (preferredCountryObj && [preferredCountryObj isKindOfClass:[NSString class]])
                                            [_settings.billingUserCountryDownloadName set:(NSString *)preferredCountryObj];
                                    }
                                    hasError = NO;
                                    [self.navigationController popViewControllerAnimated:YES];
                                }
                                else
                                 {
                                     UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                          message:[NSString stringWithFormat:@"Error: %@", [map objectForKey:@"error"]]
                                                   preferredStyle:UIAlertControllerStyleAlert];
                                     
                                     UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                                   style:UIAlertActionStyleDefault handler:nil];
                                     [alertController addAction:okAction];
                                     
                                     [self presentViewController:alertController animated:YES completion:nil];
                                     
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
                         UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                              message:OALocalizedString(@"shared_string_io_error")
                                       preferredStyle:UIAlertControllerStyleAlert];

                         UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                       style:UIAlertActionStyleDefault
                                     handler:nil];
                         [alertController addAction:okAction];

                         [self presentViewController:alertController animated:YES completion:nil];
                     }
                 });
             }];
        }
        else
        {
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:nil
                                 message:OALocalizedString(@"shared_string_io_error")
                          preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                          style:UIAlertActionStyleDefault
                        handler:nil];
            [alertController addAction:okAction];

            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = keyboardHeight - [OAUtilities getBottomMargin];
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight + self.bottomButton.frame.size.height, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = 0;
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _textFieldBeingEdited = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _textFieldBeingEdited = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

@end
