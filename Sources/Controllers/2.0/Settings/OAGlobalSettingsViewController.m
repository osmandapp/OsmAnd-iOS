//
//  OAGlobalSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsViewController.h"
#import "OAAppSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAMultiIconTextDescCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeSwitch @"OASwitchCell"

@interface OAGlobalSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAGlobalSettingsViewController
{
    OAAppSettings *_settings;
    NSArray<NSDictionary *> *_data;
    NSArray<OAApplicationMode *> * _profileList;
}

- (instancetype) initWithSettingsType:(EOAGlobalSettingsScreen)settingsType
{
    self = [super init];
    if (self) {
        [self commonInit];
        _settings = [OAAppSettings sharedManager];
        _settingsType = settingsType;
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _profileList = [NSArray arrayWithArray:OAApplicationMode.values];
}

- (UIView *) getTopView
{
    return _navbarView;
}

- (void) applyLocalization
{
    self.titleLabel.text = _settingsType == EOAGlobalSettingsMain ? OALocalizedString(@"osmand_settings") : OALocalizedString(@"settings_preset");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    [self setupView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
        [self.tableView reloadData];
    } completion:nil];
}

- (void) setupView
{
    switch (_settingsType)
    {
        case EOAGlobalSettingsMain:
        {
            NSMutableArray *arr = [NSMutableArray arrayWithObjects:@{
                @"name" : @"settings_preset",
                @"title" : OALocalizedString(@"settings_preset"),
                @"value" : _settings.defaultApplicationMode.toHumanString,
                @"description" : OALocalizedString(@"default_profile_descr"),
                @"img" : @"menu_cell_pointer.png",
                @"type" : [OASettingsTableViewCell getCellIdentifier] },
                @{
                @"name" : @"do_not_show_discount",
                @"title" : OALocalizedString(@"do_not_show_discount"),
                @"description" : OALocalizedString(@"do_not_show_discount_desc"),
                @"value" : @(_settings.settingDoNotShowPromotions),
                @"img" : @"menu_cell_pointer.png",
                @"type" : kCellTypeSwitch },
                @{
                @"name" : @"do_not_send_anonymous_data",
                @"title" : OALocalizedString(@"send_anonymous_data"),
                @"description" : OALocalizedString(@"send_anonymous_data_desc"),
                @"value" : @(_settings.settingUseAnalytics),
                @"img" : @"menu_cell_pointer.png",
                @"type" : kCellTypeSwitch, }, nil
            ];
            _data = [NSArray arrayWithArray:arr];
            break;
        }
        case EOADefaultProfile:
        {
            NSMutableArray *arr = [NSMutableArray array];
            for (OAApplicationMode *mode in _profileList)
            {
                [arr addObject: @{
                    @"name" : mode.toHumanString,
                    @"descr" : mode.stringKey,
                    @"isSelected" : @(_settings.defaultApplicationMode == mode),
                    @"type" : [OAMultiIconTextDescCell getCellIdentifier] }];
            }
            _data = [NSArray arrayWithArray:arr];
            break;
        }
        default:
            break;
    }
}

- (IBAction) backButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == EOAGlobalSettingsMain)
        return _data[indexPath.section];
    else
        return _data[indexPath.row];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.descriptionView.numberOfLines = 1;
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = kCellTypeSwitch;
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
            [cell.overflowButton setImage:[[UIImage imageNamed:@"ic_checkmark_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            cell.overflowButton.tintColor = UIColorFromRGB(color_primary_purple);
            cell.textView.numberOfLines = 3;
            cell.textView.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        OAApplicationMode *am = _profileList[indexPath.row];
        UIImage *img = am.getIcon;
        cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
        cell.textView.text = _profileList[indexPath.row].toHumanString;
        cell.descView.text = _profileList[indexPath.row].getProfileDescription;
        [cell setOverflowVisibility:![item[@"isSelected"] boolValue]];
        return cell;
    }
    return nil;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *name = item[@"name"];
    if (name)
    {
        switch (self.settingsType)
        {
            case EOAGlobalSettingsMain:
            {
                OAGlobalSettingsViewController* settingsViewController = nil;
                if ([name isEqualToString:@"settings_preset"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADefaultProfile];
                [self.navigationController pushViewController:settingsViewController animated:YES];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            }
            case EOADefaultProfile:
            {
                _settings.defaultApplicationMode = _profileList[indexPath.row];
                _settings.applicationMode = _profileList[indexPath.row];
                [self backButtonClicked:nil];
                break;
            }
            default:
                break;
        }
    }
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain)
        return 1;
    else
        return _data.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_settingsType == EOAGlobalSettingsMain)
        return _data.count;
    else
        return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain)
    {
        NSDictionary *item = _data[section];
        return item[@"description"];
    }
    else
    {
        return @"";
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 18.0 : 16.0;
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        BOOL isChecked = ((UISwitch *) sender).on;
        NSString *name = item[@"name"];
        if (name)
        {
            if ([name isEqualToString:@"do_not_show_discount"])
                [_settings setSettingDoNotShowPromotions:isChecked];
            else if ([name isEqualToString:@"do_not_send_anonymous_data"])
                [_settings setSettingUseAnalytics:isChecked];
        }
    }
}

@end
