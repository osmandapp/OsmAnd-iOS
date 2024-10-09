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
#import "OALocationServices.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDocumentPrimitives.h"
#import "GeneratedAssetSymbols.h"

@interface OADeleteWaypointsViewController ()

@property(nonnull) NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *selectedWaypointGroups;
@property(nonnull) OAGPXTableData *data;

@end

@implementation OADeleteWaypointsViewController
{
    OsmAndAppInstance _app;
    NSTimeInterval _lastUpdate;

    NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *_waypointGroups;
}

#pragma mark - Initialization

- (instancetype)initWithSectionsData:(OAGPXTableData *)tableData
{
    self = [super init];
    if (self)
    {
        _data = tableData;
        _app = [OsmAndApp instance];
        _selectedWaypointGroups = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerObservers
{
    OsmAndAppInstance app = [OsmAndApp instance];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(updateDistanceAndDirection)
                                                 andObserve:app.locationServices.updateLocationObserver]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(updateDistanceAndDirection)
                                                 andObserve:app.locationServices.updateHeadingObserver]];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _waypointGroups = self.trackMenuDelegate ? [self.trackMenuDelegate getWaypointsData] : [NSMutableDictionary dictionary];

    self.tableView.editing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    [self updateDistanceAndDirection];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.trackMenuDelegate)
        [self.trackMenuDelegate refreshLocationServices];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"delete_waypoints");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_select_all")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (NSAttributedString *)getBottomButtonTitleAttr
{
    BOOL hasSelection = _selectedWaypointGroups.allKeys.count != 0;

    NSString *textShow = OALocalizedString(@"shared_string_delete");
    UIFont *fontShow = [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold];
    UIColor *colorShow = hasSelection ? [UIColor colorNamed:ACColorNameButtonTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
    NSMutableAttributedString *attrShow = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];

    NSInteger selectedGroupsCount = 0;
    NSInteger selectedWaypointsCount = 0;
    if (hasSelection)
    {
        for (NSString *groupName in _selectedWaypointGroups.keyEnumerator)
        {
            selectedWaypointsCount += [_selectedWaypointGroups[groupName] count];
            if ([_selectedWaypointGroups[groupName] count] == [_waypointGroups[groupName] count])
            {
                selectedGroupsCount++;
            }
        }
    }
    
    NSString *textCategories = [NSString stringWithFormat:@"\n%@ %li, %@ %li",
                                OALocalizedString(@"shared_string_groups"),
                                selectedGroupsCount,
                                OALocalizedString(@"shared_string_waypoints").lowerCase,
                                selectedWaypointsCount];
    
    UIFont *fontCategories = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    UIColor *colorCategories = hasSelection ? UIColor.whiteColor : [UIColor colorNamed:ACColorNameTextColorSecondary];
    NSMutableAttributedString *attrCategories = [[NSMutableAttributedString alloc] initWithString:textCategories attributes:@{NSFontAttributeName: fontCategories, NSForegroundColorAttributeName: colorCategories}];

    [attrShow appendAttributedString:attrCategories];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:2.0];
    [style setAlignment:NSTextAlignmentCenter];
    [attrShow addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attrShow.string.length)];

    return attrShow;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return _selectedWaypointGroups.allKeys.count != 0 ? EOABaseButtonColorSchemeRed : EOABaseButtonColorSchemeInactive;
}

#pragma mark - Table data

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _data.subjects[indexPath.section].subjects[indexPath.row];
}

- (NSInteger)sectionsCount
{
    return _data.subjects.count;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if ([_data.subjects[section].key isEqualToString:@"actions_section"] || [_data.subjects[section].key isEqualToString: [NSString stringWithFormat:@"section_waypoints_group_%@", OALocalizedString(@"route_points")]])
        return 0;

    return _data.subjects[section].subjects.firstObject.toggle ? _data.subjects[section].subjects.count : 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
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

            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [[UIColor colorNamed:ACColorNameIconColorActive] colorWithAlphaComponent:.05];
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
            cell.leftIconView.tintColor = cellData.tintColor;

            cell.arrowIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
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

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
    else
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        OAGpxWptItem *gpxWptItem = [self getGpxWptItem:indexPath.section row:indexPath.row - 1];
        NSString *groupName = gpxWptItem.point.category;
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

#pragma mark - Additions

- (void)updateDistanceAndDirection
{
    @synchronized(self)
    {
        if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.5)
            return;

        _lastUpdate = [[NSDate date] timeIntervalSince1970];

        // Obtain fresh location and heading
        CLLocation *newLocation = _app.locationServices.lastKnownLocation;
        if (!newLocation)
            return;

        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<NSIndexPath *> *visibleRows = [weakSelf.tableView indexPathsForVisibleRows];
            for (NSIndexPath *visibleRow in visibleRows)
            {
                OAGPXTableCellData *cellData = weakSelf.data.subjects[visibleRow.section].subjects[visibleRow.row];
                if (weakSelf.trackMenuDelegate)
                    [weakSelf.trackMenuDelegate updateProperty:@"update_distance_and_direction" tableData:cellData];
            }
            [weakSelf.tableView reloadRowsAtIndexPaths:visibleRows
                                  withRowAnimation:UITableViewRowAnimationNone];
        });
    }
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

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    OAGpxWptItem *gpxWptItem = [self getGpxWptItem:indexPath.section row:indexPath.row - 1];
    NSString *groupName = gpxWptItem.point.category;
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
    
    [self updateBottomButtons];
}

#pragma mark - Selectors

- (void)selectDeselectGroup:(id)sender
{
    UIButton *sw = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    
    NSMutableArray<OAGpxWptItem *> *gpxWptItems = [self getGpxWptItems:indexPath.section];
    
    NSString *groupName = gpxWptItems.firstObject.point.category;
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
    
    [self updateBottomButtons];
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

- (void)onRightNavbarButtonPressed
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
        OAGPXTableCellData *groupCellData = _data.subjects[i].subjects.firstObject;
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate updateData:groupCellData];
    }

    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
        [self.tableView reloadData];
    }
                    completion: nil];
    
    [self updateBottomButtons];
}

- (void)onBottomButtonPressed
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

    __weak __typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action)
        {
            for (NSString *groupName in weakSelf.selectedWaypointGroups.keyEnumerator)
                if (weakSelf.trackMenuDelegate)
                    [weakSelf.trackMenuDelegate deleteWaypointsGroup:groupName
                                                   selectedWaypoints:weakSelf.selectedWaypointGroups[groupName]];

            [weakSelf dismissViewController];
        }
    ]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onLeftNavbarButtonPressed
{
    [self dismissViewController];
}

@end
