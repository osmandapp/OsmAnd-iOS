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
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"

typedef NS_ENUM(NSUInteger, EOAEditTrackScreenMode)
{
    EOAEditTrackScreenWaypointsMode = 0,
    EOAEditTrackScreenSegmentsMode
};

@interface OAEditWaypointsGroupBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, OAEditWaypointsGroupOptionsDelegate>

@end

@implementation OAEditWaypointsGroupBottomSheetViewController
{
    UITapGestureRecognizer *_backgroundTapRecognizer;

    NSArray<OAGPXTableSectionData *> *_tableData;
    EOAEditTrackScreenMode _mode;

    BOOL _isShown;
    NSString *_groupName;
    UIColor *_groupColor;

    OAGPXTrackAnalysis *_analysis;
    OATrkSegment *_segment;
}

- (instancetype)initWithWaypointsGroupName:(NSString *)groupName

{
    self = [super init];
    if (self)
    {
        _mode = EOAEditTrackScreenWaypointsMode;
        _groupName = groupName;
        [self generateData];
    }
    return self;
}

- (instancetype)initWithSegment:(OATrkSegment *)segment analysis:(OAGPXTrackAnalysis *)analysis

{
    self = [super init];
    if (self)
    {
        _mode = EOAEditTrackScreenSegmentsMode;
        _analysis = analysis;
        _segment = segment;
        [self generateData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isFullScreenAvailable = NO;

    _backgroundTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundPressed:)];
    _backgroundTapRecognizer.numberOfTapsRequired = 1;
    _backgroundTapRecognizer.numberOfTouchesRequired = 1;
    _backgroundTapRecognizer.delegate = self;
    [self.view addGestureRecognizer:_backgroundTapRecognizer];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = kEstimatedRowHeight;

    if (_mode == EOAEditTrackScreenWaypointsMode)
    {
        [self updateShown];
        [self updateColor];

        [self.headerDividerView removeFromSuperview];
        self.titleView.text = _groupName;
    }
    else
    {
        [self.titleView.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor].active = true;
        self.titleView.attributedText =
                [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_options")
                                                attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:17.] }];
    }

    [self setLeftIcon];
    [self hideSliderView];
    [self.rightButton removeFromSuperview];
    [self.closeButton removeFromSuperview];
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

    if (_mode == EOAEditTrackScreenWaypointsMode)
    {
        OAGPXTableCellData *showOnMapCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"control_show_on_map",
                kCellType: [OATitleSwitchRoundCell getCellIdentifier],
                kTableValues: @{ @"bool_value": @(_isShown) },
                kCellTitle: OALocalizedString(@"map_settings_show")
        }];
        [controlCells addObject:showOnMapCellData];

        OAGPXTableSectionData *controlsSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_controls",
                kTableSubjects: controlCells
        }];
        [tableSections addObject:controlsSectionData];

        OAGPXTableCellData *renameCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"rename",
                kCellType: [OATitleIconRoundCell getCellIdentifier],
                kCellRightIconName: @"ic_custom_edit",
                kCellTitle: OALocalizedString(@"fav_rename")
        }];

        OAGPXTableCellData *changeColorCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"change_color",
                kCellType: [OATitleIconRoundCell getCellIdentifier],
                kCellRightIconName: @"ic_custom_appearance",
                kCellTitle: OALocalizedString(@"change_color")
        }];
        [tableSections addObject:[OAGPXTableSectionData withData:@{ kTableSubjects: @[renameCellData, changeColorCellData] }]];

        OAGPXTableCellData *copyToFavoritesCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"copy_to_favorites",
                kCellType: [OATitleIconRoundCell getCellIdentifier],
                kCellRightIconName: @"ic_custom_trip_edit",
                kCellTitle: OALocalizedString(@"copy_to_map_favorites")
        }];
        [tableSections addObject:[OAGPXTableSectionData withData:@{ kTableSubjects: @[copyToFavoritesCellData] }]];
    }
    else
    {
        OAGPXTableCellData *analyzeOnMapCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"analyze_on_map",
                kCellType: [OATitleIconRoundCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"analyze_on_map"),
                kCellRightIconName: @"ic_custom_graph"
        }];

        OAGPXTableCellData *editCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"edit",
                kCellType: [OATitleIconRoundCell getCellIdentifier],
                kCellRightIconName: @"ic_custom_trip_edit",
                kCellTitle: OALocalizedString(@"shared_string_edit")
        }];

        [tableSections addObject:[OAGPXTableSectionData withData:@{ kTableSubjects: @[analyzeOnMapCellData, editCellData] }]];
    }

    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"delete",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"shared_string_delete"),
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellTintColor: @color_primary_red
    }];

    [tableSections addObject:[OAGPXTableSectionData withData:@{ kTableSubjects: @[deleteCellData] }]];

    _tableData = tableSections;
}

- (void)setLeftIcon
{
    if (_mode == EOAEditTrackScreenWaypointsMode)
    {
        UIImage *leftIcon = [UIImage templateImageNamed:_isShown ? @"ic_custom_folder" : @"ic_custom_folder_hidden"];
        UIColor *tintColor = _isShown ? _groupColor : UIColorFromRGB(color_footer_icon_gray);
        self.leftIconView.image = leftIcon;
        self.leftIconView.tintColor = tintColor;
    }
    else
    {
        [self.leftIconView removeFromSuperview];
    }
}

- (CGFloat)initialHeight
{
    NSInteger sectionsCount = _tableData.count;
    NSInteger cellsCount = 0;
    for (NSInteger i = 0; i < sectionsCount; i++)
    {
        cellsCount += _tableData[i].subjects.count;
    }

    return self.headerView.frame.size.height + (sectionsCount - 1) * 20. + 23.
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
    return _tableData[indexPath.section].subjects[indexPath.row];
}

- (void)onShowHidePressed:(BOOL)show
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate setWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:_groupName] ? @"" : _groupName
                                                    show:show];

    [self setLeftIcon];
}

- (void)updateShown
{
    _isShown = self.trackMenuDelegate
            ? [self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:_groupName]
                    ? @"" : _groupName] : NO;
}

- (void)updateColor
{
    _groupColor = self.trackMenuDelegate
            ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:_groupName])
            : [OADefaultFavorite getDefaultColor];
}

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"control_show_on_map"])
    {
        _isShown = toggle;
        [self onShowHidePressed:_isShown];
    }
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return NO;

    if ([tableData.key isEqualToString:@"control_show_on_map"])
        return _isShown;

    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"control_show_on_map"])
    {
        tableData.values[@"bool_value"] = @(_isShown);
    }
    else if ([tableData.key isEqualToString:@"section_controls"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"rename"])
    {
        OAEditWaypointsGroupOptionsViewController *editWaypointsGroupOptions =
                [[OAEditWaypointsGroupOptionsViewController alloc]
                        initWithScreenType:EOAEditWaypointsGroupRenameScreen
                                 groupName:_groupName
                                groupColor:nil];
        editWaypointsGroupOptions.delegate = self;
        [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
    }
    else if ([tableData.key isEqualToString:@"change_color"])
    {
        OAEditWaypointsGroupOptionsViewController *editWaypointsGroupOptions =
                [[OAEditWaypointsGroupOptionsViewController alloc]
                        initWithScreenType:EOAEditWaypointsGroupColorScreen
                                 groupName:nil
                                groupColor:_groupColor];
        editWaypointsGroupOptions.delegate = self;
        [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
    }
    else if ([tableData.key isEqualToString:@"copy_to_favorites"])
    {
        OAEditWaypointsGroupOptionsViewController *editWaypointsGroupOptions =
                [[OAEditWaypointsGroupOptionsViewController alloc]
                        initWithScreenType:EOAEditWaypointsGroupCopyToFavoritesScreen
                                 groupName:_groupName
                                groupColor:nil];
        editWaypointsGroupOptions.delegate = self;
        [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
    }
    else if ([tableData.key isEqualToString:@"analyze_on_map"] && self.trackMenuDelegate)
    {
        [self.trackMenuDelegate openAnalysis:_analysis withMode:EOARouteStatisticsModeAltitudeSlope];
    }
    else if ([tableData.key isEqualToString:@"edit"] && self.trackMenuDelegate)
    {
        [self hide:YES completion:^{ [self.trackMenuDelegate editSegment]; }];
    }
    else if ([tableData.key isEqualToString:@"delete"] && self.trackMenuDelegate)
    {
        if (_mode == EOAEditTrackScreenWaypointsMode)
            [self hide:YES completion:^{ [self.trackMenuDelegate openConfirmDeleteWaypointsScreen:_groupName]; }];
        else
            [self hide:YES completion:^{ [self.trackMenuDelegate deleteAndSaveSegment:_segment]; }];
    }
}

#pragma mark - UITapGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class])
        return [self.tableView indexPathForRowAtPoint:[touch locationInView:self.tableView]] == nil;

    return YES;
}

#pragma mark - OAEditWaypointsGroupOptionsDelegate

- (void)updateWaypointsGroup:(NSString *)name
                       color:(UIColor *)color
{
    if (self.trackMenuDelegate)
    {
        [self.trackMenuDelegate changeWaypointsGroup:_groupName
                                        newGroupName:name
                                       newGroupColor:color];
    }
    if (name)
    {
        self.titleView.text = name;
        _groupName = name;
        [self updateShown];
        [self updateData:_tableData.firstObject.subjects.firstObject];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self updateColor];
    }

    if (color)
        _groupColor = color;

    [self setLeftIcon];
}

- (void)copyToFavorites:(NSString *)name
{
    NSArray<OAGpxWptItem *> *waypoints = [self.trackMenuDelegate getWaypointsData][_groupName];
    for (OAGpxWptItem *waypoint in waypoints)
    {
        OAFavoriteItem *favoriteItem = [OAFavoriteItem fromWpt:waypoint.point category:name];
        [OAFavoritesHelper addFavorite:favoriteItem];
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
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;
            cell.textColorNormal = cellData.tintColor > 0 ? UIColorFromRGB(cellData.tintColor) : UIColor.blackColor;

            cell.titleView.font = [cellData.values.allKeys containsObject:@"font_value"]
                    ? cellData.values[@"font_value"] : [UIFont systemFontOfSize:17.];

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
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;

            cell.switchView.on = [self isOn:cellData];

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
        return [OATitleIconRoundCell getHeight:cellData.title cellWidth:tableView.bounds.size.width];
    else if ([cellData.type isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]])
        return [OATitleSwitchRoundCell getHeight:cellData.title cellWidth:tableView.bounds.size.width];

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 && _mode == EOAEditTrackScreenWaypointsMode ? 0.001 : 20.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [self onButtonPressed:cellData];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [self onSwitch:switchView.isOn tableData:cellData];
}

- (void)onBackgroundPressed:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint touchInView = [recognizer locationInView:self.view];
        if ((OAUtilities.isLandscape && (touchInView.x < self.bottomSheetView.frame.origin.x
                || touchInView.x > self.bottomSheetView.frame.origin.x + self.bottomSheetView.frame.size.width))
                || touchInView.y < self.bottomSheetView.frame.origin.y)
            [self onRightButtonPressed];
    }
}

@end
