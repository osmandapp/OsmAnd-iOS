//
//  OAHistorySettingsViewController.m
//  OsmAnd Maps
//
//  Created by ДМИТРИЙ СВЕТЛИЧНЫЙ on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAHistorySettingsViewController.h"
#import "OAAppSettings.h"
#import "OASwitchTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARTargetPoint.h"
#import "OASearchHistoryTableItem.h"
#import "OASearchHistoryTableGroup.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAPointDescription.h"
#import "OARouteBaseViewController.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OADestinationItem.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAGlobalSettingsViewController.h"

#include <OsmAndCore/Utilities.h>

@interface OAHistorySettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAHistorySettingsViewController
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    OAHistoryHelper *_historyHelper;
    OATableDataModel *_data;
    NSArray *_allItems;
    BOOL _isLogged;
}

- (instancetype) initWithSettingsType:(EOAGlobalSettingsHistoryScreen)historyType
{
    self = [super init];
    if (self) {
        [self commonInit];
        _settings = [OAAppSettings sharedManager];
        _historyType = historyType;
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _historyHelper = [OAHistoryHelper sharedInstance];
    [self generateData];
}

- (void) applyLocalization
{
    if (_historyType == EOASearchHistoryProfile)
        self.titleView.text = OALocalizedString(@"search_history");
    else if (_historyType == EOANavigationHistoryProfile)
        self.titleView.text = OALocalizedString(@"navigation_history");
    else if (_historyType == EOAMarkersHistoryProfile)
        self.titleView.text = OALocalizedString(@"map_markers_history");
    
    [self.editButton setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
    [self.selectAllButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.exportButton setTitle:OALocalizedString(@"shared_string_export") forState:UIControlStateNormal];
    [self.deleteButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    [self.cancelButton setHidden:YES];
    [self.selectAllButton setHidden:YES];
    [self.editToolbarView setHidden:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
        [self.tableView reloadData];
    } completion:nil];
}

- (void) generateData
{
    _data = [OATableDataModel model];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components;
    NSDate *today = [NSDate date];
    NSDate *sevenDaysAgo = [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:0];
    
    switch (_historyType)
    {
        case EOASearchHistoryProfile:
        {
            _isLogged = [_settings.defaultSearchHistoryLoggingApplicationMode get];
            
            if (![self.tableView isEditing])
            {
                OATableSectionData *switchSection = [OATableSectionData sectionData];
                [switchSection addRowFromDictionary:@{
                    kCellKeyKey : @"search_history",
                    kCellTitleKey : OALocalizedString(@"search_history"),
                    @"value" : @(_isLogged),
                    kCellTypeKey : [OASwitchTableViewCell getCellIdentifier] }
                ];
                [_data addSection:switchSection];
            }
            if (_isLogged)
            {
                _allItems = [_historyHelper getPointsHavingTypes:_historyHelper.searchTypes limit:0];
                OATableSectionData *lastSevenDaysItemsSection = [OATableSectionData sectionData];
                OATableSectionData *monthsItemsSection = [OATableSectionData sectionData];
                [lastSevenDaysItemsSection setHeaderText:[OALocalizedString(@"last_seven_days") upperCase]];
                OASearchHistoryTableItem *tableItem;
                
                OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(OARootViewController.instance.mapPanel.mapViewController.mapView.target31);
                CLLocationCoordinate2D myLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
                
                for (OAHistoryItem *item in _allItems)
                {
                    if ([item.date compare:sevenDaysAgo] == NSOrderedDescending && [item.date compare:today] == NSOrderedAscending)
                    {
                        tableItem = [[OASearchHistoryTableItem alloc] initWithItem:item mapCenterCoordinate:myLocation];
                        [lastSevenDaysItemsSection addRowFromDictionary:@{
                            @"historyItem" : item,
                            kCellKeyKey : @"search_history",
                            kCellTitleKey : tableItem.item.name ? tableItem.item.name : tableItem.item.typeName,
                            kCellDescrKey : tableItem.item.distance ? tableItem.item.distance : @"",
                            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier] }
                        ];
                    }
                    else
                    {
                        //grouping by months, but not implemented
                        NSMutableDictionary *monthGroups = [NSMutableDictionary dictionary];
                        components = [calendar components:NSCalendarUnitMonth fromDate:item.date];
                        NSString *monthName = [[[NSDateFormatter alloc] init] monthSymbols][components.month-1];
                        NSMutableArray *group = monthGroups[monthName];
                        if (!group)
                        {
                            group = [NSMutableArray array];
                            monthGroups[monthName] = group;
                        }
                        [group addObject:item];
                        
                        tableItem = [[OASearchHistoryTableItem alloc] initWithItem:item mapCenterCoordinate:myLocation];
                        [monthsItemsSection addRowFromDictionary:@{
                            @"historyItem" : item,
                            kCellKeyKey : @"search_history",
                            kCellTitleKey : tableItem.item.name ? tableItem.item.name : tableItem.item.typeName,
                            kCellDescrKey : tableItem.item.distance ? tableItem.item.distance : @"",
                            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier] }
                        ];
                    }
                }
                [_data addSection:lastSevenDaysItemsSection];
            }
            break;
        }
        case EOANavigationHistoryProfile:
        {
            _isLogged = [_settings.defaultNavigationHistoryLoggingApplicationMode get];
            
            if (![self.tableView isEditing])
            {
                OATableSectionData *switchSection = [OATableSectionData sectionData];
                [switchSection addRowFromDictionary:@{
                    kCellKeyKey : @"navigation_history",
                    kCellTitleKey : OALocalizedString(@"navigation_history"),
                    @"value" : @(_isLogged),
                    kCellTypeKey : [OASwitchTableViewCell getCellIdentifier] }
                ];
                [_data addSection:switchSection];
            }
            if (_isLogged)
            {
                OARTargetPoint *startBackup = _app.data.pointToStartBackup;
                OARTargetPoint *destinationBackup = _app.data.pointToNavigateBackup;
                OATableSectionData *prevRouteSection = [OATableSectionData sectionData];
                [prevRouteSection setHeaderText:[OALocalizedString(@"prev_route") upperCase]];
                if (destinationBackup != nil)
                {
                    [prevRouteSection addRowFromDictionary:@{
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        kCellTitleKey : destinationBackup.pointDescription.name,
                        kCellDescrKey : startBackup ? startBackup.pointDescription.name : OALocalizedString(@"shared_string_my_location"),
                        kCellIconNameKey : @"ic_custom_point_to_point",
                        kCellKeyKey : @"prev_route" }
                    ];
                    [_data addSection:prevRouteSection];
                }
                _allItems = [_historyHelper getPointsHavingTypes:_historyHelper.searchTypes limit:0];
                OATableSectionData *lastSevenDaysItemsSection = [OATableSectionData sectionData];
                OATableSectionData *monthsItemsSection = [OATableSectionData sectionData];
                [lastSevenDaysItemsSection setHeaderText:[OALocalizedString(@"last_seven_days") upperCase]];
                for (OAHistoryItem *item in _allItems)
                {
                    if ([item.date compare:sevenDaysAgo] == NSOrderedDescending && [item.date compare:today] == NSOrderedAscending)
                    {
                        [lastSevenDaysItemsSection addRowFromDictionary:@{
                            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                            kCellTitleKey : item.name,
                            kCellIconNameKey : @"ic_custom_history",
                            @"item" : item }
                        ];
                    }
                    else
                    {
                        //grouping by months, but not implemented
                        NSMutableDictionary *monthGroups = [NSMutableDictionary dictionary];
                        components = [calendar components:NSCalendarUnitMonth fromDate:item.date];
                        NSString *monthName = [[[NSDateFormatter alloc] init] monthSymbols][components.month-1];
                        NSMutableArray *group = monthGroups[monthName];
                        if (!group)
                        {
                            group = [NSMutableArray array];
                            monthGroups[monthName] = group;
                        }
                        [group addObject:item];
                        [monthsItemsSection addRowFromDictionary:@{
                            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                            kCellTitleKey : item.name,
                            kCellIconNameKey : @"ic_custom_history",
                            @"item" : item }
                        ];
                    }
                }
                [_data addSection:lastSevenDaysItemsSection];
            }
            break;
        }
        case EOAMarkersHistoryProfile:
        {
            _isLogged = [_settings.defaultMarkersHistoryLoggingApplicationMode get];
            
            if (![self.tableView isEditing])
            {
                OATableSectionData *switchSection = [OATableSectionData sectionData];
                [switchSection addRowFromDictionary:@{
                    kCellKeyKey : @"map_markers_history",
                    kCellTitleKey : OALocalizedString(@"map_markers_history"),
                    @"value" : @(_isLogged),
                    kCellTypeKey : [OASwitchTableViewCell getCellIdentifier] }
                ];
                [_data addSection:switchSection];
            }
            if (_isLogged)
            {
                _allItems = [[OADestinationsHelper instance] sortedDestinationsWithoutParking];
                OATableSectionData *itemsSection = [OATableSectionData sectionData];
                
                for (NSInteger i = 0; i < _allItems.count; i++)
                {
                    OADestination *item = _allItems[i];
                    [itemsSection addRowFromDictionary:@{
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        kCellTitleKey : item.desc,
                        kCellIconNameKey : [item.markerResourceName ? item.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"],
                        @"item" : item
                    }];
                }
                [_data addSection:itemsSection];
            }
            break;
        }
        default:
            break;
    }
    [self.editButton setHidden:!_isLogged];
}

- (OATableRowData *) getItem:(NSIndexPath *)indexPath
{
    return [_data itemForIndexPath:indexPath];
}

- (void) startEditing
{
    [self.tableView setEditing:YES animated:YES];
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    [_editToolbarView setHidden:NO];
    [UIView animateWithDuration:.3 animations:^{
        _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight - _editToolbarView.bounds.size.height, DeviceScreenWidth, _editToolbarView.bounds.size.height);
        [self applySafeAreaMargins];
    }];
    
    [self.editButton setHidden:YES];
    [self.backButton setHidden:YES];
    [self.cancelButton setHidden:NO];
    [self.selectAllButton setHidden:NO];
    [self.tableView reloadData];
}

- (void) finishEditing
{
    [UIView animateWithDuration:.3 animations:^{
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

// MARK: Actions

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
    [self generateData];
    [self.editButton setHidden:YES];
    [self.tableView reloadData];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    if ([self.tableView isEditing])
    {
        [self.tableView beginUpdates];
        [self finishEditing];
        [self.tableView endUpdates];
        [self generateData];
        [self.tableView reloadData];
    }
}

- (IBAction) selectAllButtonClick:(id)sender
{
    NSInteger sections = self.tableView.numberOfSections;
    
    [self.tableView beginUpdates];
    for (NSInteger section = 0; section < sections; section++)
    {
        NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
        for (NSInteger row = 0; row < rowsCount; row++)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
    [self.tableView endUpdates];
}

- (IBAction) exportButtonClicked:(id)sender
{
    
}

- (IBAction) deleteButtonClicked:(id)sender
{
    NSArray *indexes = [self.tableView indexPathsForSelectedRows];
    if (indexes.count > 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"delete_history_items")
                                                                       message:[NSString stringWithFormat:OALocalizedString(@"confirm_history_item_delete"), indexes.count]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil
        ];
        UIAlertAction *clearAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
            NSMutableArray<OAHistoryItem *> *selectedItems = [NSMutableArray array];
            for (NSIndexPath *path in indexes)
            {
                OAHistoryItem* selectedItem = [[_data itemForIndexPath:path] objForKey:@"historyItem"];
                [selectedItems addObject:selectedItem];
            }
            [_historyHelper removePoints:selectedItems];
            [self.tableView beginUpdates];
            [self finishEditing];
            [self.tableView endUpdates];
            [self generateData];
            [self.tableView reloadData];
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:clearAction];
        alert.preferredAction = clearAction;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// MARK: UITableViewDataSoure

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _isLogged ? [_data rowCount:section] : 1;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OATableRowData *item = [self getItem:indexPath];
    NSString *cellType = item.cellType;
    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [item boolForKey:@"value"];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            if (!item.descr)
                [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            if ([UIImage templateImageNamed:item.iconName])
            {
                cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
                cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
            }
            else
            {
                cell.leftIconView.image = [UIImage imageNamed:@"ic_map_pin_small"];
            }
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

// MARK: UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

// MARK: Switch

- (void) updateTableView
{
    if (_historyType == EOASearchHistoryProfile)
    {
        _isLogged = [_settings.defaultSearchHistoryLoggingApplicationMode get];
        
        if (_isLogged)
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i < [_data sectionCount]; i++)
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i <= [_data sectionCount]; i++)
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
    else if (_historyType == EOANavigationHistoryProfile)
    {
        _isLogged = [_settings.defaultNavigationHistoryLoggingApplicationMode get];
        
        if (_isLogged)
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i < [_data sectionCount]; i++)
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i <= [_data sectionCount]; i++)
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        OATableRowData *item = [self getItem:indexPath];
        BOOL isChecked = ((UISwitch *) sender).on;
        NSString *name = item.key;
        if (name)
        {
            if ([name isEqualToString:@"search_history"])
                [_settings.defaultSearchHistoryLoggingApplicationMode set:isChecked];
            else if ([name isEqualToString:@"navigation_history"])
                [_settings.defaultNavigationHistoryLoggingApplicationMode set:isChecked];
            else if ([name isEqualToString:@"map_markers_history"])
                [_settings.defaultMarkersHistoryLoggingApplicationMode set:isChecked];
            [self generateData];
            [self updateTableView];
        }
    }
}

@end
