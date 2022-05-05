//
//  OADeleteWaypointsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 13.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OADeleteWaypointsViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OAPointWithRegionTableViewCell.h"
#import "OASelectionCollapsableCell.h"
#import "OAGpxWptItem.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDocumentPrimitives.h"

@interface OADeleteWaypointsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation OADeleteWaypointsViewController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_locationServicesUpdateObserver;
    NSTimeInterval _lastUpdate;

    OAGPXTableData *_tableData;
    NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *_waypointGroups;
    NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *_selectedWaypointGroups;
}

- (instancetype)initWithSectionsData:(OAGPXTableData *)tableData
{
    self = [super init];
    if (self)
    {
        _tableData = tableData;
        _app = [OsmAndApp instance];
        _selectedWaypointGroups = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _waypointGroups = self.trackMenuDelegate ? [self.trackMenuDelegate getWaypointsData] : [NSMutableDictionary dictionary];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;

    [self updateDeleteButtonView];
    [self updateDistanceAndDirection];
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(updateDistanceAndDirection)
                                                                 andObserve:_app.locationServices.updateObserver];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_locationServicesUpdateObserver)
    {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }

    if (self.trackMenuDelegate)
        [self.trackMenuDelegate refreshLocationServices];
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"delete_waypoints");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.selectAllButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
}

- (void)updateDistanceAndDirection
{
    if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.5)
        return;

    _lastUpdate = [[NSDate date] timeIntervalSince1970];

    // Obtain fresh location and heading
    CLLocation *newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<NSIndexPath *> *visibleRows = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *visibleRow in visibleRows)
        {
            OAGPXTableCellData *cellData = _tableData.subjects[visibleRow.section].subjects[visibleRow.row];
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate updateProperty:@"update_distance_and_direction" tableData:cellData];
        }
        [self.tableView reloadRowsAtIndexPaths:visibleRows
                              withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)updateDeleteButtonView
{
    BOOL hasSelection = _selectedWaypointGroups.allKeys.count != 0;
    self.deleteButton.backgroundColor =
            hasSelection ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_route_button_inactive);
    [self.deleteButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.deleteButton setUserInteractionEnabled:hasSelection];

    NSString *textShow = OALocalizedString(@"shared_string_delete");
    UIFont *fontShow = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    UIColor *colorShow = hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer);
    NSMutableAttributedString *attrShow = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];

    NSInteger selectedGroupsCount = 0;
    NSInteger selectedWaypointsCount = 0;
    for (NSString *groupName in _selectedWaypointGroups.keyEnumerator)
    {
        selectedWaypointsCount += _selectedWaypointGroups[groupName].count;
        if (_selectedWaypointGroups[groupName].count == _waypointGroups[groupName].count)
            selectedGroupsCount += 1;
    }
    NSString *textGroups = [NSString stringWithFormat:@"\n%@ %li, %@ %li",
                    OALocalizedString(@"groups"),
                                                      selectedGroupsCount,
                                                      OALocalizedString(@"gpx_waypoints").lowerCase,
                                                      selectedWaypointsCount];

    UIFont *fontCategories = [UIFont systemFontOfSize:13];
    UIColor *colorCategories = hasSelection != 0 ? UIColor.whiteColor : UIColorFromRGB(color_text_footer);
    NSMutableAttributedString *attrCategories = [[NSMutableAttributedString alloc] initWithString:textGroups attributes:@{NSFontAttributeName: fontCategories, NSForegroundColorAttributeName: colorCategories}];

    [attrShow appendAttributedString:attrCategories];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:2.0];
    [style setAlignment:NSTextAlignmentCenter];
    [attrShow addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attrShow.string.length)];

    [self.deleteButton setAttributedTitle:attrShow forState:UIControlStateNormal];
}

- (void)selectDeselectGroup:(id)sender
{
    UIButton *sw = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];

    NSMutableArray<OAGpxWptItem *> *gpxWptItems = [self getGpxWptItems:indexPath.section];
    NSString *groupName = gpxWptItems.firstObject.point.type;
    if (self.trackMenuDelegate)
        groupName = [self.trackMenuDelegate checkGroupName:groupName];
    NSMutableArray<OAGpxWptItem *> *waypoints = _selectedWaypointGroups[groupName];

    if (waypoints)
    {
        if (waypoints.count != 0)
            [waypoints removeAllObjects];
        else
            [waypoints addObjectsFromArray:gpxWptItems];
    }
    else
    {
        waypoints = [NSMutableArray array];
        [waypoints addObjectsFromArray:gpxWptItems];
    }
    _selectedWaypointGroups[groupName] = waypoints.count > 0 ? waypoints : nil;
    OAGPXTableCellData *groupCellData = [self getCellData:indexPath];
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate updateData:groupCellData];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                  withRowAnimation:UITableViewRowAnimationNone];

    [self updateDeleteButtonView];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    OAGpxWptItem *gpxWptItem = [self getGpxWptItem:indexPath.section row:indexPath.row - 1];
    NSString *groupName = gpxWptItem.point.type;
    if (self.trackMenuDelegate)
        groupName = [self.trackMenuDelegate checkGroupName:groupName];
    NSMutableArray<OAGpxWptItem *> *waypoints = _selectedWaypointGroups[groupName];

    if (waypoints)
    {
        if ([waypoints containsObject:gpxWptItem])
            [waypoints removeObject:gpxWptItem];
        else
            [waypoints addObject:gpxWptItem];
    }
    else
    {
        waypoints = [NSMutableArray array];
        [waypoints addObject:gpxWptItem];
    }
    _selectedWaypointGroups[groupName] = waypoints.count > 0 ? waypoints : nil;
    OAGPXTableCellData *groupCellData = [self getCellData:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate updateData:groupCellData];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section], indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];

    [self updateDeleteButtonView];
}

- (OAGpxWptItem *)getGpxWptItem:(NSInteger)section row:(NSInteger)row
{
    return [self getGpxWptItems:section][row];
}

- (NSMutableArray<OAGpxWptItem *> *)getGpxWptItems:(NSInteger)section
{
    NSArray<NSString *> *waypointSortedGroupNames = self.trackMenuDelegate
            ? [self.trackMenuDelegate getWaypointSortedGroups] : [NSArray array];
    return waypointSortedGroupNames.count > 0
            ? _waypointGroups[waypointSortedGroupNames[section]] : _waypointGroups[_waypointGroups.allKeys[section]];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData.subjects[indexPath.section].subjects[indexPath.row];
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [cellData setData:@{
            kCellToggle: @(!cellData.toggle)
    }];
    [cellData setData:@{
            kCellRightIconName: cellData.toggle ? @"ic_custom_arrow_up" : @"ic_custom_arrow_right"
    }];

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];

    [self.tableView beginUpdates];
    [self.tableView reloadSections:indexSet
                  withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];

    if (self.trackMenuDelegate)
        [self.trackMenuDelegate reloadSections:indexSet];
}

- (IBAction)onCancelButtonClicked:(id)sender
{
    [self dismissViewController];
}

- (IBAction)onSelectAllButtonClicked:(id)sender
{
    NSArray<NSString *> *waypointSortedGroupNames = self.trackMenuDelegate
            ? [self.trackMenuDelegate getWaypointSortedGroups] : [NSArray array];
    for (NSInteger i = 0; i < waypointSortedGroupNames.count; i++)
    {
        NSString *groupName = waypointSortedGroupNames[i];
        if ([groupName isEqualToString:OALocalizedString(@"route_points")])
            continue;

        NSMutableArray *waypoints = [NSMutableArray array];
        [waypoints addObjectsFromArray:[self getGpxWptItems:i]];
        _selectedWaypointGroups[groupName] = waypoints;
        OAGPXTableCellData *groupCellData = _tableData.subjects[i].subjects.firstObject;
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate updateData:groupCellData];
    }

    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self.tableView reloadData];
                    }
                    completion: nil];

    [self updateDeleteButtonView];
}

- (IBAction)onDeleteButtonClicked:(id)sender
{
    NSInteger waypointsCount = 0;
    for (NSMutableArray<OAGpxWptItem *> *waypoints in _selectedWaypointGroups.allValues)
    {
        waypointsCount += waypoints.count;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:[NSString stringWithFormat:OALocalizedString(@"points_delete_multiple"), waypointsCount]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action)
                                            {
                                                if (_locationServicesUpdateObserver)
                                                {
                                                    [_locationServicesUpdateObserver detach];
                                                    _locationServicesUpdateObserver = nil;
                                                }

                                                for (NSString *groupName in _selectedWaypointGroups.keyEnumerator)
                                                {
                                                    if (self.trackMenuDelegate)
                                                    {
                                                        [self.trackMenuDelegate deleteWaypointsGroup:groupName
                                                                                   selectedWaypoints:_selectedWaypointGroups[groupName]];
                                                    }
                                                }

                                                [self dismissViewController];
                                            }
    ]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.subjects.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_tableData.subjects[section].key isEqualToString:@"actions_section"]
            || [_tableData.subjects[section].key isEqualToString:[NSString stringWithFormat:@"group_%@_section", OALocalizedString(@"route_points")]])
        return 0;

    return _tableData.subjects[section].subjects.firstObject.toggle ? _tableData.subjects[section].subjects.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAPointWithRegionTableViewCell getCellIdentifier]])
    {
        OAPointWithRegionTableViewCell *cell =
                [self.tableView dequeueReusableCellWithIdentifier:[OAPointWithRegionTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointWithRegionTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OAPointWithRegionTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);

            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            [cell.titleView setText:cellData.title];
            [cell.iconView setImage:cellData.leftIcon];
            [cell setRegion:cellData.desc];
            [cell setDirection:cellData.values[@"string_value_distance"]];

            cell.directionIconView.transform =
                    CGAffineTransformMakeRotation([cellData.values[@"float_value_direction"] floatValue]);

            if (![cell.directionIconView.tintColor isEqual:UIColorFromRGB(color_active_light)])
            {
                cell.directionIconView.image = [UIImage templateImageNamed:@"ic_small_direction"];
                cell.directionIconView.tintColor = UIColorFromRGB(color_active_light);
            }
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASelectionCollapsableCell getCellIdentifier]])
    {
        OASelectionCollapsableCell *cell =
                [self.tableView dequeueReusableCellWithIdentifier:[OASelectionCollapsableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASelectionCollapsableCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OASelectionCollapsableCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showOptionsButton:NO];
            [cell makeSelectable:YES];
        }
        if (cell)
        {
            NSInteger tag = indexPath.section << 10 | indexPath.row;

            [cell.titleView setText:cellData.title];

            [cell.leftIconView setImage:[UIImage templateImageNamed:@"ic_custom_folder"]];
            cell.leftIconView.tintColor = UIColorFromRGB(cellData.tintColor);

            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
            if (!cellData.toggle && [cell isDirectionRTL])
                cell.arrowIconView.image = cell.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;

            cell.openCloseGroupButton.tag = tag;
            [cell.openCloseGroupButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.openCloseGroupButton addTarget:self
                                          action:@selector(openCloseGroupButtonAction:)
                                forControlEvents:UIControlEventTouchUpInside];

            cell.selectionButton.tag = tag;
            [cell.selectionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.selectionButton addTarget:self
                                     action:@selector(selectDeselectGroup:)
                           forControlEvents:UIControlEventTouchUpInside];

            cell.selectionGroupButton.tag = tag;
            [cell.selectionGroupButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.selectionGroupButton addTarget:self
                                          action:@selector(selectDeselectGroup:)
                                forControlEvents:UIControlEventTouchUpInside];

            NSString *groupName = self.trackMenuDelegate ? [self.trackMenuDelegate checkGroupName:cellData.title] : @"";
            UIImage *selectionImage = [_selectedWaypointGroups.allKeys containsObject:groupName] ?
                    _selectedWaypointGroups[groupName].count == _waypointGroups[groupName].count
                            ? [UIImage imageNamed:@"ic_system_checkbox_selected"]
                            : [UIImage imageNamed:@"ic_system_checkbox_indeterminate"]
                    : nil;
            [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
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
    if (indexPath.row > 0)
    {
        OAGpxWptItem *gpxWptItem = [self getGpxWptItem:indexPath.section row:indexPath.row - 1];
        NSString *groupName = gpxWptItem.point.type;
        if (self.trackMenuDelegate)
            groupName = [self.trackMenuDelegate checkGroupName:groupName];
        NSMutableArray<OAGpxWptItem *> *selectedWaypoints = _selectedWaypointGroups[groupName];
        BOOL selected = selectedWaypoints && [selectedWaypoints containsObject:gpxWptItem];
        [cell setSelected:selected animated:YES];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

@end
