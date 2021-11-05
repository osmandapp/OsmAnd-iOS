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
    OAGpxTrkSeg *_segment;
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

- (instancetype)initWithSegment:(OAGpxTrkSeg *)segment analysis:(OAGPXTrackAnalysis *)analysis

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
        _isShown = self.trackMenuDelegate
                ? [self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:_groupName] ? @"" : _groupName]
                : NO;

        _groupColor = self.trackMenuDelegate
                ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:_groupName])
                : [OADefaultFavorite getDefaultColor];
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
        OAGPXTableCellData *showOnMap = [OAGPXTableCellData withData:@{
                kCellKey: @"control_show_on_map",
                kCellType: [OATitleSwitchRoundCell getCellIdentifier],
                kTableValues: @{@"bool_value": @(_isShown)},
                kCellTitle: OALocalizedString(@"map_settings_show"),
                kCellOnSwitch: ^(BOOL toggle) {
                    [self onShowHidePressed:nil];
                },
                kCellIsOn: ^() {
                    return _isShown;
                }
        }];

        [showOnMap setData:@{
                kTableUpdateData: ^() {
                    [showOnMap setData:@{ kTableValues: @{ @"bool_value": @(_isShown) } }];
                }
        }];
        [controlCells addObject:showOnMap];

        OAGPXTableSectionData *controlsSection = [OAGPXTableSectionData withData:@{ kSectionCells: controlCells}];
        [controlsSection setData:@{
                kTableUpdateData: ^() {
                    for (OAGPXTableCellData *cellData in controlsSection.cells) {
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
                                kCellTitle: OALocalizedString(@"fav_rename"),
                                kCellButtonPressed: ^() {
                                    OAEditWaypointsGroupOptionsViewController *editWaypointsGroupOptions =
                                            [[OAEditWaypointsGroupOptionsViewController alloc]
                                                    initWithScreenType:EOAEditWaypointsGroupRenameScreen
                                                             groupName:_groupName
                                                            groupColor:nil];
                                    editWaypointsGroupOptions.delegate = self;
                                    [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
                                }
                        }],
                        [OAGPXTableCellData withData:@{
                                kCellKey: @"change_color",
                                kCellType: [OATitleIconRoundCell getCellIdentifier],
                                kCellRightIconName: @"ic_custom_appearance",
                                kCellTitle: OALocalizedString(@"change_color"),
                                kCellButtonPressed: ^() {
                                    OAEditWaypointsGroupOptionsViewController *editWaypointsGroupOptions =
                                            [[OAEditWaypointsGroupOptionsViewController alloc]
                                                    initWithScreenType:EOAEditWaypointsGroupColorScreen
                                                             groupName:nil
                                                            groupColor:_groupColor];
                                    editWaypointsGroupOptions.delegate = self;
                                    [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
                                }
                        }]
                ]
        }]];
    }
    else
    {
        [tableSections addObject:[OAGPXTableSectionData withData:@{
                kSectionCells: @[
                        [OAGPXTableCellData withData:@{
                                kCellKey: @"analyze_on_map",
                                kCellType: [OATitleIconRoundCell getCellIdentifier],
                                kCellTitle: OALocalizedString(@"analyze_on_map"),
                                kCellRightIconName: @"none",
                                kCellButtonPressed: ^() {
                                    if (self.trackMenuDelegate)
                                        [self.trackMenuDelegate openAnalysis:_analysis
                                                                    withMode:EOARouteStatisticsModeAltitudeSlope];
                                }
                        }],
                        [OAGPXTableCellData withData:@{
                                kCellKey: @"edit",
                                kCellType: [OATitleIconRoundCell getCellIdentifier],
                                kCellRightIconName: @"ic_custom_trip_edit",
                                kCellTitle: OALocalizedString(@"shared_string_edit"),
                                kCellButtonPressed: ^() {
                                    [self hide:YES completion:^{
                                        if (self.trackMenuDelegate)
                                            [self.trackMenuDelegate editSegment];
                                    }];
                                }
                        }]
                ]
        }]];
    }

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"delete",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellTitle: OALocalizedString(@"shared_string_delete"),
                            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                            kCellRightIconName: @"ic_custom_remove_outlined",
                            kCellTintColor: @color_primary_red,
                            kCellButtonPressed: ^() {
                                if (_mode == EOAEditTrackScreenWaypointsMode)
                                {
                                    [self hide:YES completion:^{
                                        if (self.trackMenuDelegate)
                                            [self.trackMenuDelegate openConfirmDeleteWaypointsScreen:_groupName];
                                    }];
                                }
                                else
                                {
                                    [self hide:YES completion:^{
                                        if (self.trackMenuDelegate)
                                            [self.trackMenuDelegate deleteAndSaveSegment:_segment];
                                    }];
                                }
                            }
                    }]
            ]
    }]];

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
        cellsCount += _tableData[i].cells.count;
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
    return _tableData[indexPath.section].cells[indexPath.row];
}

- (void)onShowHidePressed:(id)sender
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate setWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:_groupName] ? @"" : _groupName
                                                    show:_isShown = !_isShown];

    [self setLeftIcon];
}

#pragma mark - UITapGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class])
        return [self.tableView indexPathForRowAtPoint:[touch locationInView:self.tableView]] == nil;

    return YES;
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
            BOOL hasIcon = ![cellData.rightIconName isEqualToString:@"none"];

            cell.titleView.text = cellData.title;
            cell.textColorNormal = cellData.tintColor > 0 ? UIColorFromRGB(cellData.tintColor) : UIColor.blackColor;

            cell.titleView.font = [cellData.values.allKeys containsObject:@"font_value"]
                    ? cellData.values[@"font_value"] : [UIFont systemFontOfSize:17.];

            if (hasIcon)
            {
                cell.iconColorNormal = cellData.tintColor > 0
                        ? UIColorFromRGB(cellData.tintColor) : UIColorFromRGB(color_primary_purple);
                cell.iconView.image = [UIImage templateImageNamed:cellData.rightIconName];
            }
            else
            {
                cell.iconView.layer.cornerRadius = 12.;
                cell.iconColorNormal = UIColorFromRGB(color_tint_gray);
                cell.iconView.image = [OAUtilities resizeImage:[OAUtilities imageWithColor:UIColorFromRGB(color_tint_gray)] newSize:CGSizeMake(24., 24.)];
            }

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OATitleIconRoundCell getCellIdentifier]]
        || [cellData.type isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]])
        return 48.;

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 && _mode == EOAEditTrackScreenWaypointsMode ? 0.001 : 20.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onButtonPressed)
        cellData.onButtonPressed();
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onSwitch)
        cellData.onSwitch(switchView.isOn);

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
