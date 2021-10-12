//
//  OAMapSettingsMapillaryScreen.m
//  OsmAnd
//
//  Created by Paul on 31/05/19.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapSettingsMapillaryScreen.h"
#import "OAMapSettingsViewController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "Localization.h"
#import "OACustomSearchPoiFilter.h"
#import "OAUtilities.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAIconTitleButtonCell.h"
#import "OASettingSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "OATimeTableViewCell.h"
#import "OADateTimePickerTableViewCell.h"
#import "OAColors.h"
#import "OAMapLayers.h"
#import "OAMapillaryLayer.h"
#import "OADividerCell.h"
#import "OAUsernameFilterViewController.h"
#import "OATableViewCustomFooterView.h"

#define resetButtonTag 500
#define applyButtonTag 600

static const NSInteger visibilitySection = 0;
static const NSInteger nameFilterSection = 1;
static const NSInteger dateFilterSection = 2;
static const NSInteger panoImageFilterSection = 3;

@interface OAMapSettingsMapillaryScreen () <OAMapillaryScreenDelegate>

@end

@implementation OAMapSettingsMapillaryScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSArray *_data;
    
    NSIndexPath *_datePickerIndexPath;
    double _startDate;
    double _endDate;
    
    NSString *_userNames;
    NSString *_userKeys;
    
    BOOL _mapillaryEnabled;
    BOOL _panoOnly;
    
    BOOL _atLeastOneFilterChanged;
    
    UIView *_footerView;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        settingsScreen = EMapSettingsScreenMapillaryFilter;
        vwController = viewController;
        tblView = tableView;
        
        _mapillaryEnabled = _app.data.mapillary;
        _panoOnly = _settings.mapillaryFilterPano.get;
        
        NSString *usernames = _settings.mapillaryFilterUserName.get;
        NSString *userKeys = _settings.mapillaryFilterUserKey.get;
        _userNames = usernames ? usernames : @"";
        _userKeys = userKeys ? userKeys : @"";
        
        _startDate = _settings.mapillaryFilterStartDate.get;
        _endDate = _settings.mapillaryFilterEndDate.get;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
    [self.tblView.tableFooterView removeFromSuperview];
    self.tblView.tableFooterView = nil;
    [self.tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    [self buildFooterView];
    tblView.estimatedRowHeight = kEstimatedRowHeight;
}

- (void) onRotation
{
    [self.tblView reloadData];
}

- (void) deinit
{
}

- (void) initData
{
    _atLeastOneFilterChanged = NO;
    NSMutableArray *dataArr = [NSMutableArray new];
    
    // Visibility/cache section
    
    [dataArr addObject:@[
                         @{ @"type" : [OADividerCell getCellIdentifier]},
                         @{
                             @"type" : [OASettingSwitchCell getCellIdentifier],
                             @"title" : @"",
                             @"description" : @"",
                             @"img" : @"",
                             @"key" : @"mapillary_enabled"
                             },
                         @{
                             @"type" : [OAIconTitleButtonCell getCellIdentifier],
                             @"title" : OALocalizedString(@"tile_cache"),
                             @"btnTitle" : OALocalizedString(@"shared_string_reload"),
                             @"description" : @"",
                             @"img" : @"ic_custom_overlay_map.png"
                             },
                         @{ @"type" : [OADividerCell getCellIdentifier]}
                         ]];
    
    // Users filter
    [dataArr addObject:@[
                         @{ @"type" : [OADividerCell getCellIdentifier]},
                         @{
                             @"type" : [OAIconTitleValueCell getCellIdentifier],
                             @"img" : @"ic_custom_user.png",
                             @"key" : @"users_filter",
                             @"title" : OALocalizedString(@"mapil_usernames")
                             },
                         @{ @"type" : [OADividerCell getCellIdentifier]}]];
    // Date filter
    [dataArr addObject:@[
                         @{ @"type" : [OADividerCell getCellIdentifier]},
                         @{
                             @"type" : [OATimeTableViewCell getCellIdentifier],
                             @"title" : OALocalizedString(@"shared_string_start_date"),
                             @"key" : @"start_date_filter",
                             @"img" : @"ic_custom_date.png"
                             },
                         @{
                             @"type" : [OATimeTableViewCell getCellIdentifier],
                             @"title" : OALocalizedString(@"shared_string_end_date"),
                             @"key" : @"end_date_filter",
                             @"img" : @"ic_custom_date.png"
                             },
                         @{ @"type" : [OADividerCell getCellIdentifier]}
                         ]];
    
    // Pano filter
    [dataArr addObject:@[
                         @{ @"type" : [OADividerCell getCellIdentifier]},
                         @{
                             @"type" : [OASettingSwitchCell getCellIdentifier],
                             @"title" : OALocalizedString(@"mapil_pano_only"),
                             @"description" : @"",
                             @"img" : @"ic_custom_coordinates.png",
                             @"key" : @"pano_only"
                             },
                         @{ @"type" : [OADividerCell getCellIdentifier]}
                         ]];
    
    _data = [NSArray arrayWithArray:dataArr];
}

- (void) buildFooterView
{
    CGFloat distBetweenButtons = 21.0;
    CGFloat margin = [OAUtilities getLeftMargin];
    CGFloat width = self.tblView.frame.size.width;
    CGFloat height = 80.0;
    CGFloat buttonWidth = (width - 32 - distBetweenButtons) / 2;
    CGFloat buttonHeight = 44.0;
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    
    NSDictionary *applyAttrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                             NSForegroundColorAttributeName : [UIColor whiteColor] };
    NSDictionary *resetAttrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                                  NSForegroundColorAttributeName : UIColorFromRGB(color_menu_button) };
    NSAttributedString *resetText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_reset") attributes:resetAttrs];
    NSAttributedString *applyText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_apply") attributes:applyAttrs];
    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *apply = [UIButton buttonWithType:UIButtonTypeSystem];
    [reset setAttributedTitle:resetText forState:UIControlStateNormal];
    [apply setAttributedTitle:applyText forState:UIControlStateNormal];
    [reset addTarget:self action:@selector(resetPressed) forControlEvents:UIControlEventTouchUpInside];
    [apply addTarget:self action:@selector(applyPressed) forControlEvents:UIControlEventTouchUpInside];
    reset.backgroundColor = UIColorFromRGB(color_disabled_light);
    apply.backgroundColor = UIColorFromRGB(color_active_light);
    reset.layer.cornerRadius = 9;
    apply.layer.cornerRadius = 9;
    reset.tag = resetButtonTag;
    apply.tag = applyButtonTag;
    CGFloat buttonY = (height / 2) - (buttonHeight / 2);
    reset.frame = CGRectMake(16.0 + margin, buttonY, buttonWidth, buttonHeight);
    apply.frame = CGRectMake(16.0 + margin + buttonWidth + distBetweenButtons, buttonY, buttonWidth, buttonHeight);
    [_footerView addSubview:reset];
    [_footerView addSubview:apply];
}

- (void) adjustFooterView:(CGFloat)width
{
    UIButton *reset = [_footerView viewWithTag:resetButtonTag];
    UIButton *apply = [_footerView viewWithTag:applyButtonTag];
    CGFloat height = 80.0;
    CGFloat distBetweenButtons = 21.0;
    CGFloat margin = [OAUtilities getLeftMargin];
    CGFloat buttonWidth = (width - 32 - distBetweenButtons - margin) / 2;
    CGFloat buttonHeight = 44.0;
    CGFloat buttonY = (height / 2) - (buttonHeight / 2);
    _footerView.frame = CGRectMake(_footerView.frame.origin.x, _footerView.frame.origin.y, width, height);
    reset.frame = CGRectMake(16.0 + margin, buttonY, buttonWidth, buttonHeight);
    apply.frame = CGRectMake(16.0 + margin + buttonWidth + distBetweenButtons, buttonY, buttonWidth, buttonHeight);
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSArray *section = _data[indexPath.section];
    if (indexPath.section == dateFilterSection)
    {
        if ([self datePickerIsShown])
        {
            if ([indexPath isEqual:_datePickerIndexPath])
                    return [NSDictionary new];
            else if (indexPath.row < section.count - 1)
                return section[indexPath.row];
            else
                return section[indexPath.row - 1];
        }
    }
    return section[indexPath.row];
}

- (void) setupView
{
    title = OALocalizedString(@"street_level_imagery");
}

- (BOOL)datePickerIsShown
{
    return _datePickerIndexPath != nil;
}

- (void) resetPressed
{
    [_settings.mapillaryFilterPano set:NO];
    [_settings.mapillaryFilterUserKey set:nil];
    [_settings.mapillaryFilterUserName set:nil];
    [_settings.mapillaryFilterStartDate set:0];
    [_settings.mapillaryFilterEndDate set:0];
    [_settings.useMapillaryFilter set:NO];
    
    _panoOnly = _settings.mapillaryFilterPano.get;
    
    _userNames = @"";
    _userKeys = @"";
    
    _startDate = _settings.mapillaryFilterStartDate.get;
    _endDate = _settings.mapillaryFilterEndDate.get;
    
    _atLeastOneFilterChanged = YES;
    
    [self.tblView reloadData];
}

- (void) applyPressed
{
    [_settings.mapillaryFilterPano set:_panoOnly];
    [_settings.mapillaryFilterUserKey set:_userKeys];
    [_settings.mapillaryFilterUserName set:_userNames];
    [_settings.mapillaryFilterStartDate set:_startDate];
    [_settings.mapillaryFilterEndDate set:_endDate];
    [_settings.useMapillaryFilter set:(_userNames && _userNames.length > 0) || _startDate != 0 || _endDate != 0 || _panoOnly];
    
    if (_atLeastOneFilterChanged)
        [self reloadRasterCache];
    
    [vwController closeDashboard];
}

- (void) reloadCache
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapillaryLayer *layer = mapPanel.mapViewController.mapLayers.mapillaryLayer;
    [layer clearCacheAndUpdate:NO];
}

- (void) reloadRasterCache
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapillaryLayer *layer = mapPanel.mapViewController.mapLayers.mapillaryLayer;
    [layer clearCacheAndUpdate:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionItems = _data[section];
    if (section == dateFilterSection)
        return sectionItems.count + ([self datePickerIsShown] ? 1 : 0);
    
    return sectionItems.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *outCell;
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            NSString *key = item[@"key"];
            
            if ([key isEqualToString:@"mapillary_enabled"])
            {
                cell.textView.text = _mapillaryEnabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
                NSString *imgName = _mapillaryEnabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
                cell.imgView.image = [UIImage templateImageNamed:imgName];
                cell.imgView.tintColor = _mapillaryEnabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
                [cell.switchView setOn:_mapillaryEnabled];
            }
            else if ([key isEqualToString:@"pano_only"])
            {
                cell.imgView.image = [UIImage templateImageNamed:item[@"img"]];
                cell.imgView.tintColor = _panoOnly ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
                [cell.switchView setOn:_panoOnly];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleButtonCell getCellIdentifier]])
    {
        OAIconTitleButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            [cell setButtonText:item[@"btnTitle"]];
            [cell.buttonView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.buttonView addTarget:self action:@selector(reloadCache) forControlEvents:UIControlEventTouchUpInside];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
            if ([item[@"key"] isEqualToString:@"users_filter"])
            {
                NSString *usernames = [_userNames stringByReplacingOccurrencesOfString:@"$$$" withString:@", "];
                cell.descriptionView.text = !usernames || usernames.length == 0 ? OALocalizedString(@"shared_string_all") : usernames;
            }
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATimeTableViewCell getCellIdentifier]])
    {
        OATimeTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            [cell showLeftImageView:YES];
        }
        if (cell)
        {
            double dateVal = [item[@"key"] isEqualToString:@"start_date_filter"] ? _startDate : _endDate;
            BOOL isNotSet = dateVal == 0;
            cell.lbTitle.text = item[@"title"];
            UIImage *img = [UIImage templateImageNamed:item[@"img"]];
            if (img)
            {
                [cell showLeftImageView:YES];
                cell.leftImageView.image = img;
                cell.leftImageView.tintColor = isNotSet ? UIColorFromRGB(color_tint_gray) : UIColorFromRGB(color_dialog_buttons_dark);
            }
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:dateVal];
            NSString *dateStr = isNotSet ? OALocalizedString(@"shared_string_not_set") : [formatter stringFromDate:date];
            cell.lbTime.text = dateStr;
            [cell.lbTime setTextColor:isNotSet ? UIColorFromRGB(color_text_footer) : UIColorFromRGB(color_menu_button)];
        }
        outCell = cell;
    }
    else if ([self datePickerIsShown] && [_datePickerIndexPath isEqual:indexPath])
    {
        OADateTimePickerTableViewCell* cell;
        cell = (OADateTimePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OADateTimePickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADateTimePickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADateTimePickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dateTimePicker.datePickerMode = UIDatePickerModeDate;
        double currentDate = [[NSDate date] timeIntervalSince1970];
        double dateToShow = indexPath.row - 1 == 1 ? (_startDate == 0 ? currentDate : _startDate) : (_endDate == 0 ? currentDate : _endDate);
        cell.dateTimePicker.date = [NSDate dateWithTimeIntervalSince1970:dateToShow];
        [cell.dateTimePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        [cell.dateTimePicker addTarget:self action:@selector(timePickerChanged:) forControlEvents:UIControlEventValueChanged];
        
        outCell = cell;
    }
    if (outCell)
        [self applySeparatorLine:outCell indexPath:indexPath];
    
    return outCell;
}

- (void) applySeparatorLine:(UITableViewCell *)outCell indexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionItems = _data[indexPath.section];
    BOOL timePickerSection = indexPath.section == dateFilterSection;
    BOOL lastItem = indexPath.row == (sectionItems.count + (timePickerSection && [self datePickerIsShown] ? 1 : 0) - 2);
    outCell.separatorInset = UIEdgeInsetsMake(0.0, lastItem ? 0.0 : 62.0, 0.0, lastItem ? DeviceScreenWidth : 0.0);
}

-(void)timePickerChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDate *newDate = picker.date;
    if (_datePickerIndexPath.row == 2)
        _startDate = newDate.timeIntervalSince1970;
    else if (_datePickerIndexPath.row == 3)
        _endDate = newDate.timeIntervalSince1970;
    [self.tblView reloadData];
    
    _atLeastOneFilterChanged = YES;
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        NSString *key = item[@"key"];
        if (key)
        {
            BOOL isChecked = sw.on;
            if ([key isEqualToString:@"mapillary_enabled"])
            {
                _mapillaryEnabled = isChecked;
                [_app.data setMapillary:_mapillaryEnabled];
            }
            else if ([key isEqualToString:@"pano_only"])
            {
                _panoOnly = isChecked;
                _atLeastOneFilterChanged = YES;
            }
            [self.tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case nameFilterSection:
            return 30.0;
        default:
            return 0.01;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getFooterHeightForSection:section];
}

- (NSString *)getText:(NSInteger)section {
    NSString *text = @"";
    if (section == visibilitySection)
        text = OALocalizedString(@"mapil_reload_cache");
    else if (section == nameFilterSection)
        text = OALocalizedString(@"mapil_filter_user_descr");
    else
        text = OALocalizedString(@"mapil_filter_date");
    return text;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == panoImageFilterSection)
    {
        [self adjustFooterView:tableView.frame.size.width];
        return _footerView;
    }
    else
    {
        OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
        NSString * text = [self getText:section];
        vw.label.text = text;
        return vw;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == nameFilterSection)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat) getFooterHeightForSection:(NSInteger) section
{
    if (section == panoImageFilterSection)
    {
        return 80.0;
    }
    else
    {
        NSString *text = [self getText:section];
        return [OATableViewCustomFooterView getHeight:text width:tblView.frame.size.width];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case nameFilterSection:
            return OALocalizedString(@"shared_string_filter");
        default:
            return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]] || [item[@"type"] isEqualToString:[OAIconTitleButtonCell getCellIdentifier]] || [item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]] || [indexPath isEqual:_datePickerIndexPath])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    }
    return 44.0;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAIconTitleButtonCell getCellIdentifier]] || [type isEqualToString:[OASettingSwitchCell getCellIdentifier]])
        return nil;
    return indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:@"OATimeTableViewCell"])
    {
        [self.tblView beginUpdates];
        
        if ([self datePickerIsShown] && (_datePickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self datePickerIsShown])
                [self hideExistingPicker];
            
            [self showNewPickerAtIndex:newPickerIndexPath];
            _datePickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }
        
        [self.tblView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tblView endUpdates];
        [self.tblView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        [self.tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAUsernameFilterViewController *controller = [[OAUsernameFilterViewController alloc] initWithData:@[_userNames, _userKeys]];
        controller.delegate = self;
        [self.vwController.navigationController pushViewController:controller animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)hideExistingPicker {
    
    [self.tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_datePickerIndexPath.row inSection:_datePickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _datePickerIndexPath = nil;
}

- (void)showNewPickerAtIndex:(NSIndexPath *)indexPath {
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:dateFilterSection]];
    
    [self.tblView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (NSIndexPath *)calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath {
    NSIndexPath *newIndexPath;
    if (([self datePickerIsShown]) && (_datePickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:dateFilterSection];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:dateFilterSection];
    
    return newIndexPath;
}

#pragma mark - OAMapillaryScreenDelegate

- (void) setData:(NSArray<NSString*> *)data
{
    _userNames = data[0];
    _userKeys = data[1];
    _atLeastOneFilterChanged = YES;
    [self.tblView reloadData];
}

@end
