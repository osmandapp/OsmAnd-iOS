//
//  OAEditWaypointsGroupOptionsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 21.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OATextInputCell.h"
#import "OAColorsTableViewCell.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OADefaultFavorite.h"
#import "OAFavoritesHelper.h"

@interface OAEditWaypointsGroupOptionsViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, OAColorsTableViewCellDelegate>

@end

@implementation OAEditWaypointsGroupOptionsViewController
{
    EOAEditWaypointsGroupScreen _screenType;
    NSString *_groupName;
    NSString *_newGroupName;

    UIColor *_groupColor;
    OAFavoriteColor *_selectedColor;
    NSArray<NSNumber *> *_colors;

    NSArray<OAGPXTableSectionData *> *_tableData;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    return self;
}

- (instancetype)initWithScreenType:(EOAEditWaypointsGroupScreen)screenType
                         groupName:(NSString *)groupName
                         groupColor:(UIColor *)groupColor
{
    self = [super init];
    if (self)
    {
        _screenType = screenType;
        _groupName = groupName;
        _groupColor = groupColor;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    if (_groupColor)
    {
        _selectedColor = [OADefaultFavorite getFavoriteColor:_groupColor];
        NSMutableArray<NSNumber *> *tempColors = [NSMutableArray new];
        for (OAFavoriteColor *favColor in [OADefaultFavorite builtinColors])
        {
            [tempColors addObject:@([OAUtilities colorToNumber:favColor.color])];
        }
        _colors = tempColors;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self generateData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.doneButton.hidden = NO;
    self.doneButton.enabled = _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen;
    _newGroupName = _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen ? _groupName : @"";
}

- (void)applyLocalization
{
    [super applyLocalization];
    if (_screenType == EOAEditWaypointsGroupRenameScreen)
    {
        self.titleLabel.text = OALocalizedString(@"fav_rename");
    }
    else if (_screenType == EOAEditWaypointsGroupColorScreen)
    {
        self.titleLabel.text = OALocalizedString(@"select_color");
    }
    else if (_screenType == EOAEditWaypointsGroupVisibleScreen)
    {
        self.titleLabel.text = OALocalizedString(@"map_settings_show");
    }
    else if (_screenType == EOAEditWaypointsGroupCopyToFavoritesScreen)
    {
        self.titleLabel.text = OALocalizedString(@"copy_to_map_favorites");
    }
}

- (void)generateData
{
    OAGPXTableSectionData *sectionData = [OAGPXTableSectionData new];

    if (_screenType == EOAEditWaypointsGroupRenameScreen || _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen)
    {
        sectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section",
                kTableSubjects: @[[OAGPXTableCellData withData:@{
                        kTableKey: @"new_name",
                        kCellType: [OATextInputCell getCellIdentifier],
                        kCellTitle: _groupName,
                        kCellDesc: OALocalizedString(@"fav_enter_group_name")
                }]],
                kSectionHeader: _screenType == EOAEditWaypointsGroupRenameScreen ? OALocalizedString(@"fav_name") : OALocalizedString(@"group_name")
        }];
    }
    else if (_screenType == EOAEditWaypointsGroupColorScreen)
    {
        OAGPXTableCellData *cellData = [OAGPXTableCellData withData:@{
                kTableKey: @"color_grid",
                kCellType: [OAColorsTableViewCell getCellIdentifier],
                kTableValues: @{
                        @"int_value": @([OAUtilities colorToNumber:_selectedColor.color]),
                        @"array_value": _colors
                },
                kCellTitle: OALocalizedString(@"fav_color"),
                kCellDesc: _selectedColor.name
        }];

        sectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section",
                kTableSubjects: @[cellData],
                kSectionHeader: OALocalizedString(@"default_color"),
                kSectionFooter: OALocalizedString(@"default_color_descr")
        }];
    }
    else if (_screenType == EOAEditWaypointsGroupVisibleScreen)
    {
        NSArray<NSString *> *groups = self.delegate && [self.delegate respondsToSelector:@selector(getWaypointSortedGroups)]
                ? [self.delegate getWaypointSortedGroups]
                : [NSArray array];

        NSMutableArray<OAGPXTableCellData *> *cellsData = [NSMutableArray array];
        sectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section",
                kTableSubjects: cellsData,
                kSectionHeader: OALocalizedString(@"groups"),
                kTableValues: @{
                        @"groups_count": @([groups containsObject:OALocalizedString(@"route_points")]
                                ? groups.count - 1
                                : groups.count),
                        @"visible_groups_count": @(0)
                }
        }];

        if (groups && [sectionData.values[@"groups_count"] integerValue] > 0)
        {
            for (NSString *groupName in groups)
            {
                if (self.delegate && [self.delegate isRteGroup:groupName])
                    continue;

                BOOL visible = NO;
                NSInteger color = [OAUtilities colorToNumber:[OADefaultFavorite getDefaultColor]];

                if (self.delegate)
                {
                    if ([self.delegate respondsToSelector:@selector(isWaypointsGroupVisible:)])
                        visible = [self.delegate isWaypointsGroupVisible:groupName];
                    if ([self.delegate respondsToSelector:@selector(getWaypointsGroupColor:)])
                        color = [self.delegate getWaypointsGroupColor:groupName];
                }

                if (visible)
                    sectionData.values[@"visible_groups_count"] = @([sectionData.values[@"visible_groups_count"] integerValue] + 1);

                OAGPXTableCellData *groupCellData = [OAGPXTableCellData withData:@{
                        kTableKey: [@"cell_waypoints_group_" stringByAppendingString:groupName],
                        kCellType: [OAIconTextDividerSwitchCell getCellIdentifier],
                        kCellTitle: groupName,
                        kCellLeftIcon: [UIImage templateImageNamed:visible ? @"ic_custom_folder" : @"ic_custom_folder_hidden"],
                        kCellTintColor: @(visible ? color : color_footer_icon_gray),
                        kTableValues: @{
                                @"visible": @(visible),
                                @"color": @(color)
                        }
                }];
                [cellsData addObject:groupCellData];
            }

            OAGPXTableCellData *hideShowAllCellData = [OAGPXTableCellData withData:@{
                    kTableKey: @"hide_show_all",
                    kCellType: [OAIconTitleValueCell getCellIdentifier],
                    kCellTitle: [sectionData.values[@"visible_groups_count"] integerValue] == 0
                            ? OALocalizedString(@"shared_string_show_all")
                            : OALocalizedString(@"shared_string_hide_all"),
                    kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                    kCellRightIconName: [sectionData.values[@"visible_groups_count"] integerValue] == 0
                            ? @"ic_custom_show" : @"ic_custom_hide",
                    kCellTintColor: @color_primary_purple
            }];
            [cellsData insertObject:hideShowAllCellData atIndex:0];
        }
    }

    _tableData = @[sectionData];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].subjects[indexPath.row];
}

- (void)onDoneButtonPressed
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(updateWaypointsGroup:color:)])
        {
            if (_screenType == EOAEditWaypointsGroupRenameScreen)
                [self.delegate updateWaypointsGroup:_newGroupName color:nil];
            else if (_screenType == EOAEditWaypointsGroupColorScreen)
                [self.delegate updateWaypointsGroup:nil color:_selectedColor.color];
            else if (_screenType == EOAEditWaypointsGroupCopyToFavoritesScreen)
                [self.delegate copyToFavorites:_newGroupName];
        }

        if (_screenType == EOAEditWaypointsGroupVisibleScreen
                && [self.delegate respondsToSelector:@selector(setWaypointsGroupVisible:show:)])
        {
            for (OAGPXTableCellData *cellData in _tableData.firstObject.subjects)
            {
                if (![cellData.key isEqualToString:@"hide_show_all"])
                    [self.delegate setWaypointsGroupVisible:cellData.title show:[self isOn:cellData]];
            }
        }
    }
}

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
    {
        OAGPXTableSectionData *sectionData = _tableData.firstObject;
        if (sectionData && [tableData.values[@"visible"] boolValue] != toggle)
        {
            if (toggle)
                sectionData.values[@"visible_groups_count"] = @([sectionData.values[@"visible_groups_count"] integerValue] + 1);
            else
                sectionData.values[@"visible_groups_count"] = @([sectionData.values[@"visible_groups_count"] integerValue] - 1);
        }
        tableData.values[@"visible"] = @(toggle);

        [self updateData:tableData];

        if (sectionData && [sectionData.values[@"visible_groups_count"] integerValue] != [sectionData.values[@"groups_count"] integerValue])
        {
            [self updateData:[sectionData getSubject:@"hide_show_all"]];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return NO;

    if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
    {
        return [tableData.values[@"visible"] boolValue];
    }

    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"color_grid"])
    {
        tableData.values[@"int_value"] = @([OAUtilities colorToNumber:_selectedColor.color]);
        tableData.values[@"array_value"] = _colors;
        [tableData setData:@{ kCellDesc: _selectedColor.name }];
    }
    else if ([tableData.key isEqualToString:@"section"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
    {
        self.doneButton.enabled = YES;
        [tableData setData:@{
                kCellLeftIcon: [UIImage templateImageNamed:[tableData.values[@"visible"] boolValue] ? @"ic_custom_folder" : @"ic_custom_folder_hidden"],
                kCellTintColor: @([tableData.values[@"visible"] boolValue] ? [tableData.values[@"color"] integerValue] : color_footer_icon_gray)
        }];
    }
    else if ([tableData.key isEqualToString:@"hide_show_all"])
    {
        OAGPXTableSectionData *sectionData = _tableData.firstObject;
        if (sectionData)
        {
            [tableData setData:@{
                    kCellTitle: [sectionData.values[@"visible_groups_count"] integerValue] == 0
                            ? OALocalizedString(@"shared_string_show_all")
                            : OALocalizedString(@"shared_string_hide_all"),
                    kCellRightIconName: [sectionData.values[@"visible_groups_count"] integerValue] == 0
                            ? @"ic_custom_show" : @"ic_custom_hide"
            }];
        }
    }
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"hide_show_all"])
    {
        OAGPXTableSectionData *sectionData = _tableData.firstObject;
        if (sectionData)
        {
            BOOL allHidden = [sectionData.values[@"visible_groups_count"] integerValue] == 0;
            for (OAGPXTableCellData *cellData in sectionData.subjects)
            {
                [self onSwitch:allHidden tableData:cellData];
            }
            [self updateData:tableData];

            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[_tableData indexOfObject:sectionData]]
                          withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData[section].subjects.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData[section].header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _tableData[section].footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OATextInputCell getCellIdentifier]])
    {
        OATextInputCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextInputCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextInputCell getCellIdentifier] owner:self options:nil];
            cell = (OATextInputCell *) nib[0];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.placeholder = cellData.desc;
        }
        if (cell)
        {
            cell.inputField.text = cellData.title;
            cell.inputField.delegate = self;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        NSArray<NSNumber *> *arrayValue = cellData.values[@"array_value"];
        OAColorsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OAColorsTableViewCell *) nib[0];
            cell.dataArray = arrayValue;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
            [cell showLabels:YES];
        }
        if (cell)
        {
            cell.titleLabel.text = cellData.title;
            cell.valueLabel.text = cellData.desc;
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            cell.currentColor = [arrayValue indexOfObject:cellData.values[@"int_value"]];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.dividerView.hidden = YES;
        }
        if (cell)
        {
            BOOL isOn = [self isOn:cellData];
            cell.switchView.on = isOn;
            cell.textView.text = cellData.title;

            [cell showIcon:cellData.leftIcon != nil];
            cell.iconView.image = cellData.leftIcon;
            cell.iconView.tintColor = UIColorFromRGB(cellData.tintColor);

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    if ([cellData.type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = cellData.title;
            cell.descriptionView.text = nil;
            cell.textView.textColor = UIColorFromRGB(cellData.tintColor);
            cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
            cell.rightIconView.tintColor = UIColorFromRGB(cellData.tintColor);
            if ([cellData.values.allKeys containsObject:@"font_value"])
                cell.textView.font = cellData.values[@"font_value"];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((_screenType == EOAEditWaypointsGroupRenameScreen || _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen) &&
            [[self getCellData:indexPath].type isEqualToString:[OATextInputCell getCellIdentifier]])
        [((OATextInputCell *) cell).inputField becomeFirstResponder];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [self onButtonPressed:cellData];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [self onSwitch:switchView.isOn tableData:cellData];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *newGroupName = [textView.text trim];
    if (newGroupName.length == 0 ||
            [self isIncorrectFileName:textView.text] ||
            [OAFavoritesHelper getGroupByName:newGroupName] ||
            [newGroupName isEqualToString:OALocalizedString(@"favorites")] ||
            [newGroupName isEqualToString:OALocalizedString(@"personal_category_name")] ||
            [newGroupName isEqualToString:kPersonalCategory] ||
            (_screenType != EOAEditWaypointsGroupCopyToFavoritesScreen && [newGroupName isEqualToString:_groupName]))
    {
        self.doneButton.enabled = NO;
    }
    else
    {
        _newGroupName = newGroupName;
        self.doneButton.enabled = YES;
    }
}

- (BOOL) isIncorrectFileName:(NSString *)fileName
{
    NSCharacterSet *illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:;.,"];
    return [fileName rangeOfCharacterFromSet:illegalFileNameCharacters].length != 0;
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColor = [OADefaultFavorite builtinColors][tag];
    self.doneButton.enabled = ![_selectedColor.color isEqual:_groupColor];

    [self updateData:_tableData.firstObject];
    [UIView setAnimationsEnabled:NO];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
