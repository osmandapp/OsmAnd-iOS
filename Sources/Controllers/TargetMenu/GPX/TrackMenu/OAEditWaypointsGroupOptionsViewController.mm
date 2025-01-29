//
//  OAEditWaypointsGroupOptionsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 21.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OAInputTableViewCell.h"
#import "OAColorsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OADefaultFavorite.h"
#import "OAFavoritesHelper.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAEditWaypointsGroupOptionsViewController() <UITextFieldDelegate, OAColorsTableViewCellDelegate>

@end

@implementation OAEditWaypointsGroupOptionsViewController
{
    EOAEditWaypointsGroupScreen _screenType;
    NSString *_groupName;
    NSString *_newGroupName;

    UIColor *_groupColor;
    OAFavoriteColor *_selectedColor;
    NSArray<NSNumber *> *_colors;

    OAGPXTableSectionData *_tableData;
    
    UIBarButtonItem *_doneBarButton;
}

#pragma mark - Initialization

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
        [self postInit];
    }
    return self;
}

- (void)postInit
{
    if (_groupColor)
    {
        _selectedColor = [OADefaultFavorite getFavoriteColor:_groupColor];
        NSMutableArray<NSNumber *> *tempColors = [NSMutableArray new];
        for (OAFavoriteColor *favColor in [OADefaultFavorite builtinColors])
        {
            [tempColors addObject:@([favColor.color toRGBNumber])];
        }
        _colors = tempColors;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self generateData];
    _newGroupName = _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen ? _groupName : @"";
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    switch (_screenType)
    {
        case EOAEditWaypointsGroupRenameScreen:
            return OALocalizedString(@"shared_string_rename");
        case EOAEditWaypointsGroupColorScreen:
            return OALocalizedString(@"select_color");
        case EOAEditWaypointsGroupVisibleScreen:
            return OALocalizedString(@"shared_string_show_on_map");
        case EOAEditWaypointsGroupCopyToFavoritesScreen:
            return OALocalizedString(@"add_destination");
        default:
            return @"";
    }
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    _doneBarButton = [self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                          iconName:nil
                                            action:@selector(onRightNavbarButtonPressed)
                                              menu:nil];
    [self changeButtonAvailability:_doneBarButton isEnabled:_screenType == EOAEditWaypointsGroupCopyToFavoritesScreen];
    return @[_doneBarButton];
}

#pragma mark - Table data

- (void)generateData
{
    if (_screenType == EOAEditWaypointsGroupRenameScreen || _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen)
    {
        _tableData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section",
            kTableSubjects: @[[OAGPXTableCellData withData:@{
                kTableKey: @"new_name",
                kCellType: [OAInputTableViewCell getCellIdentifier],
                kCellTitle: _groupName,
                kCellDesc: OALocalizedString(@"fav_enter_group_name")
            }]],
            kSectionHeader: _screenType == EOAEditWaypointsGroupRenameScreen ? OALocalizedString(@"shared_string_name") : OALocalizedString(@"favorite_group_name")
        }];
    }
    else if (_screenType == EOAEditWaypointsGroupColorScreen)
    {
        _tableData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section",
            kTableSubjects: @[[OAGPXTableCellData withData:@{
                kTableKey: @"color_grid",
                kCellType: [OAColorsTableViewCell getCellIdentifier],
                kTableValues: @{
                    @"int_value": @([_selectedColor.color toRGBNumber]),
                    @"array_value": _colors
                },
                kCellTitle: OALocalizedString(@"shared_string_color"),
                kCellDesc: _selectedColor.name
            }]],
            kSectionHeader: OALocalizedString(@"access_default_color"),
            kSectionFooter: OALocalizedString(@"default_color_descr")
        }];
    }
    else if (_screenType == EOAEditWaypointsGroupVisibleScreen)
    {
        NSArray<NSString *> *groups = self.delegate && [self.delegate respondsToSelector:@selector(getWaypointSortedGroups)]
        ? [self.delegate getWaypointSortedGroups]
        : [NSArray array];
        
        _tableData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section",
            kSectionHeader: OALocalizedString(@"shared_string_groups"),
            kTableValues: @{
                @"groups_count": @([groups containsObject:OALocalizedString(@"route_points")]
                    ? groups.count - 1
                    : groups.count),
                @"visible_groups_count": @(0)
            }
        }];
        
        if (groups && [_tableData.values[@"groups_count"] integerValue] > 0)
        {
            OAGPXTableCellData *hideShowAllCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"hide_show_all",
                kCellType: [OAValueTableViewCell getCellIdentifier],
                kCellTitle: [_tableData.values[@"visible_groups_count"] integerValue] == 0
                ? OALocalizedString(@"shared_string_show_all")
                : OALocalizedString(@"shared_string_hide_all"),
                kTableValues: @{ @"font_value": [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellRightIconName: [_tableData.values[@"visible_groups_count"] integerValue] == 0
                ? @"ic_custom_show" : @"ic_custom_hide",
                kCellTintColor:[UIColor colorNamed:ACColorNameIconColorActive]
            }];
            [_tableData.subjects addObject:hideShowAllCellData];

            for (NSString *groupName in groups)
            {
                if (self.delegate && [self.delegate isRteGroup:groupName])
                    continue;

                BOOL visible = NO;
                NSInteger color = [[OADefaultFavorite getDefaultColor] toRGBNumber];

                if (self.delegate)
                {
                    if ([self.delegate respondsToSelector:@selector(isWaypointsGroupVisible:)])
                        visible = [self.delegate isWaypointsGroupVisible:groupName];
                    if ([self.delegate respondsToSelector:@selector(getWaypointsGroupColor:)])
                        color = [self.delegate getWaypointsGroupColor:groupName];
                }

                if (visible)
                    _tableData.values[@"visible_groups_count"] = @([_tableData.values[@"visible_groups_count"] integerValue] + 1);

                OAGPXTableCellData *groupCellData = [OAGPXTableCellData withData:@{
                    kTableKey: [@"cell_waypoints_group_" stringByAppendingString:groupName],
                    kCellType: [OASwitchTableViewCell getCellIdentifier],
                    kCellTitle: groupName,
                    kCellLeftIcon: [UIImage templateImageNamed:visible ? @"ic_custom_folder" : @"ic_custom_folder_hidden"],
                    kCellTintColor: visible ? UIColorFromRGB(color) : [UIColor colorNamed:ACColorNameIconColorDisabled],
                    kTableValues: @{
                        @"visible": @(visible),
                        @"color": UIColorFromRGB(color)
                    }
                }];
                [_tableData.subjects addObject:groupCellData];
            }
        }
    }
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"color_grid"])
    {
        tableData.values[@"int_value"] = @([_selectedColor.color toRGBNumber]);
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
        [self changeButtonAvailability:_doneBarButton isEnabled:YES];
        [tableData setData:@{
            kCellLeftIcon: [UIImage templateImageNamed:[tableData.values[@"visible"] boolValue] ? @"ic_custom_folder" : @"ic_custom_folder_hidden"],
            kCellTintColor: [tableData.values[@"visible"] boolValue] ? tableData.values[@"color"] : [UIColor colorNamed:ACColorNameIconColorDisabled]
        }];
    }
    else if ([tableData.key isEqualToString:@"hide_show_all"])
    {
        OAGPXTableSectionData *sectionData = _tableData;
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

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData.subjects[indexPath.row];
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _tableData.header;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _tableData.footer;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _tableData.subjects.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.placeholder = cellData.desc;
            cell.inputField.textAlignment = NSTextAlignmentNatural;
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
        OAColorsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
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
            cell.valueLabel.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.currentColor = [arrayValue indexOfObject:cellData.values[@"int_value"]];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell =
        [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingOnSideOfContent, 0., 0.);
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            BOOL isOn = [self isOn:cellData];
            cell.switchView.on = isOn;
            cell.titleLabel.text = cellData.title;

            [cell leftIconVisibility:cellData.leftIcon != nil];
            cell.leftIconView.image = cellData.leftIcon;
            cell.leftIconView.tintColor = cellData.tintColor;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    if ([cellData.type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell valueVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = cellData.title;
            cell.titleLabel.textColor = cellData.tintColor;
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:cellData.rightIconName]];
            cell.accessoryView.tintColor = cellData.tintColor;
            if ([cellData.values.allKeys containsObject:@"font_value"])
                cell.titleLabel.font = cellData.values[@"font_value"];
        }
        outCell = cell;
    }
    return outCell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [self onButtonPressed:cellData];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((_screenType == EOAEditWaypointsGroupRenameScreen || _screenType == EOAEditWaypointsGroupCopyToFavoritesScreen) &&
        [[self getCellData:indexPath].type isEqualToString:[OAInputTableViewCell getCellIdentifier]])
        [((OAInputTableViewCell *) cell).inputField becomeFirstResponder];
}

#pragma mark - Additions

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
    {
        OAGPXTableSectionData *sectionData = _tableData;
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
            OAGPXTableCellData *hideShowAllCellData = [sectionData getSubject:@"hide_show_all"];
            if (hideShowAllCellData)
            {
                [self updateData:hideShowAllCellData];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
        return [tableData.values[@"visible"] boolValue];
    
    return NO;
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

- (void)onRightNavbarButtonPressed
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
            for (OAGPXTableCellData *cellData in _tableData.subjects)
            {
                if (![cellData.key isEqualToString:@"hide_show_all"])
                    [self.delegate setWaypointsGroupVisible:cellData.title show:[self isOn:cellData]];
            }
        }
    }
    [self dismissViewController];
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"hide_show_all"])
    {
        if (_tableData)
        {
            BOOL allHidden = [_tableData.values[@"visible_groups_count"] integerValue] == 0;
            for (OAGPXTableCellData *cellData in _tableData.subjects)
            {
                [self onSwitch:allHidden tableData:cellData];
            }
            [self updateData:tableData];
            
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                          withRowAnimation:UITableViewRowAnimationNone];
        }
    }
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
        [newGroupName isEqualToString:OALocalizedString(@"favorites_item")] ||
        [newGroupName isEqualToString:OALocalizedString(@"personal_category_name")] ||
        [newGroupName isEqualToString:kPersonalCategory] ||
        (_screenType != EOAEditWaypointsGroupCopyToFavoritesScreen && [newGroupName isEqualToString:_groupName]))
    {
        [self changeButtonAvailability:_doneBarButton isEnabled:NO];
    }
    else
    {
        _newGroupName = newGroupName;
        [self changeButtonAvailability:_doneBarButton isEnabled:YES];
    }
}

- (BOOL)isIncorrectFileName:(NSString *)fileName
{
    NSCharacterSet *illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:;.,"];
    return [fileName rangeOfCharacterFromSet:illegalFileNameCharacters].length != 0;
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColor = [OADefaultFavorite builtinColors][tag];
    [self changeButtonAvailability:_doneBarButton isEnabled:![_selectedColor.color isEqual:_groupColor]];

    [self updateData:_tableData];
    [UIView setAnimationsEnabled:NO];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
