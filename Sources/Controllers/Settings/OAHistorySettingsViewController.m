//
//  OAHistorySettingsViewController.m
//  OsmAnd Maps
//
//  Created by ДМИТРИЙ СВЕТЛИЧНЫЙ on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAHistorySettingsViewController.h"
#import "OAGlobalSettingsViewController.h"
#import "OAAppSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OATableViewCustomHeaderView.h"
#import "Localization.h"
#import "OAColors.h"

@interface OAHistorySettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAHistorySettingsViewController
{
    OAAppSettings *_settings;
    NSArray<NSDictionary *> *_data;
    NSMutableArray<NSIndexPath *> *_selectedIndexPaths;
    NSArray<OAApplicationMode *> * _profileList;
}

- (instancetype) initWithSettingsType:(EOAGlobalSettingsHistoryScreen)settingsType
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
//    [self generateData];
}

- (void) generateData
{
//    _profileList = [NSArray arrayWithArray:OAApplicationMode.values];
}

- (void) applyLocalization
{
    if (_settingsType == EOASearchHistoryProfile)
        self.titleView.text = OALocalizedString(@"search_history");
    else if (_settingsType == EOANavigationHistoryProfile)
        self.titleView.text = OALocalizedString(@"navigation_history");
    else if (_settingsType == EOAMarkersHistoryProfile)
        self.titleView.text = OALocalizedString(@"map_markers_history");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [self setupView];
    
    [self.cancelButton setHidden:YES];
    [self.selectAllButton setHidden:YES];
    [self.editToolbarView setHidden:YES];
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
        case EOASearchHistoryProfile:
        {
            _data = @[
                @{
                    @"header" : @"",
                    @"footer" : OALocalizedString(@"history_footer_text"),
                    @"rows": @[@{  @"name" : @"search_history",
                                   @"title" : OALocalizedString(@"search_history"),
                                   @"value" : [self getDialogsAndNotificationsValue],
                                   @"icon" : @"ic_custom_search",
                                   @"type" : [OAValueTableViewCell getCellIdentifier] },
                               @{
                                   @"name" : @"navigation_history",
                                   @"title" : OALocalizedString(@"navigation_history"),
                                   @"value" : [self getDialogsAndNotificationsValue],
                                   @"icon" : @"ic_custom_navigation",
                                   @"type" : [OAValueTableViewCell getCellIdentifier] },
                               @{
                                   @"name" : @"map_markers_history",
                                   @"title" : OALocalizedString(@"map_markers_history"),
                                   @"value" : [self getDialogsAndNotificationsValue],
                                   @"icon" : @"ic_custom_marker",
                                   @"type" : [OAValueTableViewCell getCellIdentifier] }]},
                @{
                    @"header" : [OALocalizedString(@"actions") upperCase],
                    @"footer" : OALocalizedString(@"history_actions_footer_text"),
                    @"rows": @[@{  @"name" : @"export_history",
                                   @"title" : OALocalizedString(@"export_history"),
                                   @"value" : @(_settings.sendAnonymousAppUsageData.get),
                                   @"icon" : @"ic_custom_export",
                                   @"type" : [OARightIconTableViewCell getCellIdentifier] },
                               @{
                                   @"name" : @"clear_history",
                                   @"title" : OALocalizedString(@"clear_history"),
                                   @"value" : [self getDialogsAndNotificationsValue],
                                   @"icon" : @"ic_custom_remove_outlined",
                                   @"type" : [OARightIconTableViewCell getCellIdentifier] }],
                }];
            break;
        }
        default:
            break;
    }
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == EOASearchHistoryProfile)
    {
        NSDictionary *section = _data[indexPath.section];
        NSArray *row = section[@"rows"];
        return row[indexPath.row];
    }
    else
        return _data[indexPath.row];
}

- (NSString *) getDialogsAndNotificationsValue
{
    BOOL showPromotions = _settings.settingDoNotShowPromotions.get;
    BOOL showDownloadMap = _settings.showDownloadMapDialog.get;
    if (showPromotions && showDownloadMap)
        return OALocalizedString(@"shared_string_all");
    else if (!showPromotions && !showDownloadMap)
        return OALocalizedString(@"shared_string_none");
    return @"1/2";
}

- (void) startEditing
{
    [self.tableView setEditing:YES animated:YES];
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    [_editToolbarView setHidden:NO];
    [UIView animateWithDuration:.3 animations:^{
//        self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
        [self applySafeAreaMargins];
    } completion:^(BOOL finished) {
//        [self.tabBarController.tabBar setHidden:YES];
    }];

    [self.editButton setHidden:YES];
    [self.backButton setHidden:YES];
    [self.cancelButton setHidden:NO];
    [self.selectAllButton setHidden:NO];
    [self.tableView reloadData];
}

- (void) finishEditing
{
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight - _editToolbarView.bounds.size.height, DeviceScreenWidth, _editToolbarView.bounds.size.height);
//    self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight + 1, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
    [UIView animateWithDuration:.3 animations:^{
//        [self.tabBarController.tabBar setHidden:NO];
//        self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight - self.tabBarController.tabBar.frame.size.height, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
        _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    } completion:^(BOOL finished) {
        _editToolbarView.hidden = YES;
        [self applySafeAreaMargins];
    }];

    [self.cancelButton setHidden:YES];
    [self.selectAllButton setHidden:YES];
    [self.editButton setHidden:NO];
    [self.backButton setHidden:NO];
    [self.tableView setEditing:NO animated:YES];
}

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
    if (![_selectedIndexPaths containsObject:indexPath])
    {
        [_selectedIndexPaths addObject:indexPath];
    }
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    if ([_selectedIndexPaths containsObject:indexPath])
    {
        [_selectedIndexPaths removeObject:indexPath];
    }
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedIndexPaths)
        if (itemPath.section == indexPath.section)
            [self.tableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - Actions

- (IBAction) backButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)editButtonClicked:(id)sender
{
    [self.tableView beginUpdates];
    if ([self.tableView isEditing])
        [self finishEditing];
    else
        [self startEditing];
    [self.tableView endUpdates];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    if ([self.tableView isEditing])
    {
        [self.tableView beginUpdates];
        [self finishEditing];
        [self.tableView endUpdates];
    }
}

- (IBAction) selectAllButtonClick:(id)sender
{

}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            NSString *iconName = item[@"icon"];
            cell.leftIconView.image = [UIImage templateImageNamed:iconName];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            if ([item[@"title"] isEqualToString:@"Clear all history"])
                cell.titleLabel.textColor = UIColorFromRGB(color_primary_red);
            else
                cell.titleLabel.textColor = UIColorFromRGB(color_primary_purple);

            cell.rightIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            if ([item[@"icon"] isEqualToString:@"ic_custom_remove_outlined"])
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_red);
            else
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);

        }
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

}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_settingsType == EOASearchHistoryProfile)
    {
        NSDictionary *sections = _data[section];
        NSArray *row = sections[@"rows"];
        return row.count;
    }
    else
        return _data.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_settingsType == EOASearchHistoryProfile)
        return _data.count;
    else
        return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == EOASearchHistoryProfile)
    {
        NSDictionary *sections = _data[section];
        return sections[@"header"];
    }
    else
        return @"";
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == EOASearchHistoryProfile)
    {
        NSDictionary *sections = _data[section];
        return sections[@"footer"];
    }
    else
    {
        return @"";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.label.text = title;
    vw.label.textColor = UIColorFromRGB(color_text_footer);
    return vw;
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
    if (_settingsType == EOASearchHistoryProfile)
    {
        NSString *title = [self tableView:tableView titleForHeaderInSection:section];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
    }
    else
        return section == 0 ? 18.0 : 16.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_settingsType == EOASearchHistoryProfile)
        return 44.0;
    return UITableViewAutomaticDimension;
}

#pragma mark - Switch

- (void) updateTableView
{
//    if (_settingsType == EOADefaultProfile)
//    {
//        if (!_isUsingLastAppMode)
//        {
//            [self.tableView beginUpdates];
//            for (NSInteger i = 1; i <= _profileList.count; i++)
//                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//            [self.tableView endUpdates];
//        }
//        else
//        {
//            [self.tableView beginUpdates];
//            for (NSInteger i = 1; i <= _profileList.count; i++)
//                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//            [self.tableView endUpdates];
//        }
//    }
//    else if (_settingsType == EOACarplayProfile)
//    {
//        if (!_isDefaultProfile)
//        {
//            [self.tableView beginUpdates];
//            for (NSInteger i = 1; i < _profileList.count; i++)
//                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//            [self.tableView endUpdates];
//        }
//        else
//        {
//            [self.tableView beginUpdates];
//            for (NSInteger i = 1; i < _profileList.count; i++)
//                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//            [self.tableView endUpdates];
//        }
//    }
}

- (void) applyParameter:(id)sender
{
//    if ([sender isKindOfClass:[UISwitch class]])
//    {
//        UISwitch *sw = (UISwitch *) sender;
//        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
//        NSDictionary *item = [self getItem:indexPath];
//        BOOL isChecked = ((UISwitch *) sender).on;
//        NSString *name = item[@"name"];
//        if (name)
//        {
//            if ([name isEqualToString:@"do_not_show_discount"])
//                [_settings.settingDoNotShowPromotions set:isChecked];
//            else if ([name isEqualToString:@"do_not_send_anonymous_data"])
//                [_settings.sendAnonymousAppUsageData set:isChecked];
//            else if ([name isEqualToString:@"download_map_dialog"])
//                [_settings.showDownloadMapDialog set:isChecked];
//            else if ([name isEqualToString:@"last_used"])
//            {
//                [_settings.useLastApplicationModeByDefault set:isChecked];
//                [self setupView];
//                [self updateTableView];
//            }
//            else if ([name isEqualToString:@"carplay_mode_is_default_string"])
//            {
//                [_settings.isCarPlayModeDefault set:isChecked];
//                [self setupView];
//                [self updateTableView];
//            }
//        }
//    }
}

@end

