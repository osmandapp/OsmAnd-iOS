//
//  OAEditWaypointsGroupBottomSheetViewController.mm
//  OsmAnd
//
//  Created by Skalii on 20.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAEditWaypointsGroupBottomSheetViewController.h"
#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OATitleIconRoundCell.h"
#import "OATitleSwitchRoundCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OADefaultFavorite.h"

@interface OAEditWaypointsGroupBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource, OAEditWaypointsGroupOptionsDelegate>

@end

@implementation OAEditWaypointsGroupBottomSheetViewController
{
    NSArray<OAGPXTableSectionData *> *_tableData;

    BOOL _isShown;
    NSString *_groupName;
    UIColor *_groupColor;
}

- (instancetype)initWithGroupName:(NSString *)groupName

{
    self = [super init];
    if (self)
    {
        _groupName = groupName;
        [self generateData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isFullScreenAvailable = NO;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = kEstimatedRowHeight;

    _isShown = self.trackMenuDelegate
            ? [self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:_groupName] ? @"" : _groupName]
            : NO;

    _groupColor = self.trackMenuDelegate
            ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:_groupName])
            : [OADefaultFavorite getDefaultColor];

    self.titleView.text = _groupName;

    [self setLeftIcon];
    [self.sliderView removeFromSuperview];
    [self.rightButton removeFromSuperview];
    [self.closeButton removeFromSuperview];
    [self.headerDividerView removeFromSuperview];
    [self.buttonsSectionDividerView removeFromSuperview];
}

- (void)applyLocalization
{
    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];
    NSMutableArray<OAGPXTableCellData *> *controlCells = [NSMutableArray array];

    OAGPXTableCellData *showOnMap = [OAGPXTableCellData withData:@{
            kCellKey: @"control_show_on_map",
            kCellType: [OATitleSwitchRoundCell getCellIdentifier],
            kTableValues: @{ @"bool_value": @(_isShown) },
            kCellTitle: OALocalizedString(@"map_settings_show"),
            kCellOnSwitch: ^(BOOL toggle) { [self onShowHidePressed:nil]; },
            kCellIsOn: ^() { return _isShown; }
    }];

    [showOnMap setData:@{
            kTableUpdateData: ^() {
                [showOnMap setData:@{ kTableValues: @{@"bool_value": @(_isShown) } }];
            }
    }];
    [controlCells addObject:showOnMap];

    OAGPXTableSectionData *controlsSection = [OAGPXTableSectionData withData:@{ kSectionCells: controlCells }];
    [controlsSection setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cellData in controlsSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];
    [tableSections addObject:controlsSection];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"rename",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_edit",
                            kCellTitle: OALocalizedString(@"fav_rename")
                    }],
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"change_color",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_appearance",
                            kCellTitle: OALocalizedString(@"change_color")
                    }]
            ]
    }]];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"delete",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_remove_outlined",
                            kCellTitle: OALocalizedString(@"shared_string_delete"),
                            kCellTintColor: @color_primary_red
                    }]
            ]
    }]];

    _tableData = tableSections;
}

- (void)setLeftIcon
{
    UIImage *leftIcon = [UIImage templateImageNamed:_isShown ? @"ic_custom_folder" : @"ic_custom_folder_hidden"];
    UIColor *tintColor = _isShown ? _groupColor : UIColorFromRGB(color_footer_icon_gray);
    self.leftIconView.image = leftIcon;
    self.leftIconView.tintColor = tintColor;
}

- (CGFloat)initialHeight
{
    NSInteger sectionsCount = _tableData.count;
    NSInteger cellsCount = 0;
    for (NSInteger i = 0; i < sectionsCount; i++)
    {
        cellsCount += _tableData[i].cells.count;
    }

    return self.headerView.frame.size.height + (sectionsCount - 1) * 20. + 16.
            + cellsCount * kEstimatedRowHeight + self.buttonsView.frame.size.height;
}

- (BOOL)isDraggingUpAvailable
{
    return NO;
}

- (void)onBottomSheetDismissed
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate refreshLocationServices];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].cells[indexPath.row];
}

- (void)onShowHidePressed:(id)sender
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate setWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:_groupName] ? @"" : _groupName
                                                    show:_isShown = !_isShown];

    [self setLeftIcon];
}

#pragma mark - OAEditWaypointsGroupOptionsDelegate

- (void)updateWaypointsGroup:(NSString *)groupName
                  groupColor:(UIColor *)groupColor
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate changeWaypointsGroup:_groupName
                                        newGroupName:groupName
                                       newGroupColor:groupColor];
    if (groupName)
    {
        _groupName = groupName;
        self.titleView.text = _groupName;
    }

    if (groupColor)
    {
        _groupColor = groupColor;
        if (_isShown)
            self.leftIconView.tintColor = _groupColor;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData[section].cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        OATitleIconRoundCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OATitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconRoundCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OATitleIconRoundCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.separatorHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;
            cell.textColorNormal = cellData.tintColor > 0 ? UIColorFromRGB(cellData.tintColor) : UIColor.blackColor;

            cell.iconColorNormal = cellData.tintColor > 0
                    ? UIColorFromRGB(cellData.tintColor) : UIColorFromRGB(color_primary_purple);
            cell.iconView.image = [UIImage templateImageNamed:cellData.rightIconName];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]])
    {
        OATitleSwitchRoundCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OATitleSwitchRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSwitchRoundCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OATitleSwitchRoundCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
            cell.separatorHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;

            cell.switchView.on = cellData.isOn ? cellData.isOn() : NO;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UItableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section != 0 ? 20. : 0.001;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if ([cellData.key isEqualToString:@"rename"])
    {
        OAEditWaypointsGroupOptionsViewController * editWaypointsGroupOptions =
                [[OAEditWaypointsGroupOptionsViewController alloc] initWithScreenType:EOAEditWaypointsGroupRenameScreen
                                                                            groupName:_groupName
                                                                           groupColor:nil];
        editWaypointsGroupOptions.delegate = self;
        [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
    }
    else if ([cellData.key isEqualToString:@"change_color"])
    {
        OAEditWaypointsGroupOptionsViewController * editWaypointsGroupOptions =
                [[OAEditWaypointsGroupOptionsViewController alloc] initWithScreenType:EOAEditWaypointsGroupColorScreen
                                                                            groupName:nil
                                                                           groupColor:_groupColor];
        editWaypointsGroupOptions.delegate = self;
        [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
    }
    else if ([cellData.key isEqualToString:@"delete"])
    {
        [self hide:YES completion:^{
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate openConfirmDeleteWaypointsScreen:_groupName];
        }];
    }
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onSwitch)
        cellData.onSwitch(switchView.isOn);

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
