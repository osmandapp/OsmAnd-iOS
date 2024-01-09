//
//  OAHistoryViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryViewController.h"
#import "OADirectionTableViewCell.h"
#import "OAMapViewController.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMultiselectableHeaderView.h"
#import "OARootViewController.h"
#import "OAAutoObserverProxy.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"
#import "OAOsmAndFormatter.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface HistoryTableItem : NSObject

@property (nonatomic) OAHistoryItem *item;
@property (nonatomic, assign) CGFloat distanceMeters;
@property (nonatomic) NSString *distance;
@property (nonatomic, assign) CGFloat direction;

@end

@implementation HistoryTableItem

@end


@interface HistoryTableGroup : NSObject

@property NSString *groupName;
@property NSMutableArray *groupItems;

@end

@implementation HistoryTableGroup

- (id)init
{
    self = [super init];
    if (self)
    {
        self.groupItems = [NSMutableArray array];
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    HistoryTableGroup *item = object;
    
    return [self.groupName isEqualToString:item.groupName];
}

-(NSUInteger)hash
{
    return [self.groupName hash];
}

@end

@interface OAHistoryViewController ()<OAMultiselectableHeaderDelegate, MGSwipeTableCellDelegate>
{
    BOOL isDecelerating;
}

@property (strong, nonatomic) NSMutableArray* groupsAndItems;

@property CGFloat azimuthDirection;
@property NSTimeInterval lastUpdate;

@end

@implementation OAHistoryViewController
{
    NSArray *_headerViews;
    BOOL _isAnimating;
}

#pragma mark - Initialization

- (void)registerObservers
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(updateDistanceAndDirection)
                                                 andObserve:app.locationServices.updateObserver]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onPointRemove:withKey:)
                                                 andObserve:[OAHistoryHelper sharedInstance].historyPointRemoveObservable]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onPointsRemove:withKey:)
                                                 andObserve:[OAHistoryHelper sharedInstance].historyPointsRemoveObservable]];
}

#pragma mark - UIViewColontroller

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    isDecelerating = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateDistanceAndDirection:YES];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_history");
}

- (UIImage *)getCustomIconForLeftNavbarButton
{
    return self.tableView.editing ? [UIImage templateImageNamed:@"icon_remove"] : nil;
}

- (NSString *)getCustomAccessibilityForLeftNavbarButton
{
    return self.tableView.editing ? OALocalizedString(@"shared_string_delete") : OALocalizedString(@"shared_string_back");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:nil
                                                        iconName:@"icon_edit"
                                                          action:@selector(onRightNavbarButtonPressed)
                                                            menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"shared_string_edit");
    return @[rightButton];
}

#pragma mark - Table data

- (void)generateData
{
    [self generateData:YES];
}

- (void)generateData:(BOOL)doReload
{
    self.groupsAndItems = [[NSMutableArray alloc] init];
    NSMutableArray *headerViews = [NSMutableArray array];
    
    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
    NSArray *allItems = [helper getPointsHavingTypes:helper.destinationTypes limit:0];
    
    NSTimeInterval todayBeginTime = [self beginningOfToday];
    NSTimeInterval yesterdayBeginTime = todayBeginTime - 60 * 60 * 24;

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"LLLL - yyyy"];
    
    for(OAHistoryItem *item in allItems)
    {
        NSString *groupName;
        NSTimeInterval time = [item.date timeIntervalSince1970];
        if (time < yesterdayBeginTime)
        {
            groupName = [fmt stringFromDate:item.date];
        }
        else if (time < todayBeginTime)
        {
            groupName = @"1";
        }
        else
        {
            groupName = @"0";
        }

        HistoryTableGroup *grp;
        for (HistoryTableGroup *g in self.groupsAndItems)
            if ([g.groupName isEqualToString:groupName])
            {
                grp = g;
                break;
            }

        if (!grp)
        {
            grp = [[HistoryTableGroup alloc] init];
            grp.groupName = groupName;
            [self.groupsAndItems addObject:grp];
        }

        HistoryTableItem *tableItem = [[HistoryTableItem alloc] init];
        tableItem.item = item;
        [grp.groupItems addObject:tableItem];
    }
    
    // Sort items
    /*
    NSArray *sortedArrayGroups = [self.groupsAndItems sortedArrayUsingComparator:^NSComparisonResult(HistoryTableGroup* obj1, HistoryTableGroup* obj2) {
        return [obj1.groupName localizedCaseInsensitiveCompare:obj2.groupName];
    }];
    [self.groupsAndItems setArray:sortedArrayGroups];
     */
    
    int i = 0;
    for (HistoryTableGroup *group in self.groupsAndItems)
    {
        // add header
        OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
        if ([group.groupName isEqualToString:@"0"])
            [headerView setTitleText:OALocalizedString(@"today")];
        else if ([group.groupName isEqualToString:@"1"])
            [headerView setTitleText:OALocalizedString(@"yesterday")];
        else
            [headerView setTitleText:group.groupName];
        
        headerView.section = i++;
        headerView.delegate = self;
        [headerViews addObject:headerView];
    }
    
    if (doReload)
        [self.tableView reloadData];
    
    _headerViews = [NSArray arrayWithArray:headerViews];
}

- (void)refreshVisibleRows
{
    if ([self.tableView isEditing])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OADirectionTableViewCell class]])
            {
                HistoryTableGroup *groupData = [self.groupsAndItems objectAtIndex:i.section];
                HistoryTableItem *dataItem = [groupData.groupItems objectAtIndex:i.row];
                
                OADirectionTableViewCell *c = (OADirectionTableViewCell *)cell;
                
                [c.titleLabel setText:dataItem.item.name];
                c.leftIcon.image = [dataItem.item icon];
                
                [c.descLabel setText:dataItem.distance];
                c.descIcon.transform = CGAffineTransformMakeRotation(dataItem.direction);
            }
        }
        [self.tableView endUpdates];
    });
}

- (NSIndexPath *)indexPathOfItem:(OAHistoryItem *)item
{
    NSIndexPath *indexPath;

    for (HistoryTableGroup *group in self.groupsAndItems)
        for (HistoryTableItem *dataItem in group.groupItems)
            if (dataItem.item == item)
            {
                indexPath = [NSIndexPath indexPathForRow:[group.groupItems indexOfObject:dataItem] inSection:[self.groupsAndItems indexOfObject:group]];
                break;
            }
    
    return indexPath;
}

- (BOOL)removeItem:(OAHistoryItem *)item
{
    BOOL isGroupEmpty = NO;
    for (HistoryTableGroup *group in self.groupsAndItems)
        for (HistoryTableItem *dataItem in group.groupItems)
            if (dataItem.item == item)
            {
                [group.groupItems removeObject:dataItem];
                isGroupEmpty = (group.groupItems.count == 0);
                break;
            }
    return isGroupEmpty;
}

- (void)onPointsRemove:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{

        [self generateData];
        [self updateDistanceAndDirection:YES];
        
        if (self.groupsAndItems.count == 0)
            [self dismissViewController];
    });
}

- (void)onPointRemove:(id)observable withKey:(id)key
{
    OAHistoryItem *item = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self doRemovePoint:item];
    });
}

- (void)remove:(HistoryTableItem *)dataItem
{
    [[OAHistoryHelper sharedInstance] removePoint:dataItem.item];
}

- (void)doRemovePoint:(OAHistoryItem *)item
{
    NSIndexPath *indexPath = [self indexPathOfItem:item];
    
    _isAnimating = YES;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        if (self.groupsAndItems.count > 0)
            [self updateDistanceAndDirection:YES];
        
        _isAnimating = NO;
        
        if (self.groupsAndItems.count == 0)
            [self dismissViewController];
    }];
    
    [self.tableView beginUpdates];
    
    BOOL groupEmpty = [self removeItem:item];
    
    [self generateData:NO];
    
    if (groupEmpty)
    {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
    }
    else
    {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    [self.tableView endUpdates];
    
    [CATransaction commit];
}

- (NSArray*)getItemsForRows:(NSArray*)indexPath
{
    NSMutableArray* itemList = [[NSMutableArray alloc] init];

    [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
        HistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:path.section];
        [itemList addObject:[groupData.groupItems objectAtIndex:path.row]];
    }];
    
    return itemList;
}

- (NSInteger)sectionsCount
{
    return [self.groupsAndItems count];
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return [_headerViews[section] getHeight];
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    return 0.01;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    return _headerViews[section];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [((HistoryTableGroup*)[self.groupsAndItems objectAtIndex:section]).groupItems count];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    HistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
    
    OADirectionTableViewCell* cell;
    cell = (OADirectionTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OADirectionTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADirectionTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OADirectionTableViewCell *)[nib objectAtIndex:0];
        cell.delegate = self;
    }
    
    if (cell)
    {
        HistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
        [cell.titleLabel setText:dataItem.item.name];
        cell.leftIcon.image = [dataItem.item icon];
        
        [cell.descLabel setText:dataItem.distance];
        cell.descLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        cell.descIcon.transform = CGAffineTransformMakeRotation(dataItem.direction);
    }
    
    return cell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if ([self.tableView isEditing])
        return;

    HistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
    HistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];

    [self.navigationController popToRootViewControllerAnimated:YES];
    [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:dataItem.item pushed:NO];
}

#pragma mark - Additions

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([self.tableView isEditing])
        return;
    
    if (([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 || _isAnimating) && !forceUpdate)
        return;
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;
    
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    for (HistoryTableGroup *group in self.groupsAndItems)
    {
        for (HistoryTableItem *dataItem in group.groupItems)
        {
            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                              newLocation.coordinate.latitude,
                                                              dataItem.item.longitude, dataItem.item.latitude);
            
            dataItem.distance = [OAOsmAndFormatter getFormattedDistance:distance];
            dataItem.distanceMeters = distance;
            CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:dataItem.item.latitude longitude:dataItem.item.longitude]];
            dataItem.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        }
    }
    
    if (isDecelerating)
        return;
    
    [self refreshVisibleRows];
}

- (NSTimeInterval)beginningOfToday
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    [components setNanosecond:0];
    NSDate *today = [cal dateFromComponents:components];
    
    return [today timeIntervalSince1970];
}

#pragma mark - Actions

- (void)onLeftNavbarButtonPressed
{
    if (self.tableView.editing)
    {
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        if ([selectedRows count] == 0)
        {
            UIAlertController *removeAlert = [UIAlertController alertControllerWithTitle:@"" message:OALocalizedString(@"hist_select_remove") preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil];
            [removeAlert addAction:okAction];
            [self presentViewController:removeAlert animated:YES completion:nil];
            return;
        }
        
        UIAlertController *removeAlert = [UIAlertController alertControllerWithTitle:@"" message:OALocalizedString(@"hist_remove_q") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil];
        [removeAlert addAction:noAction];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
            NSArray* selectedItems = [self getItemsForRows:selectedRows];
            NSMutableArray *arr = [NSMutableArray array];
            for (HistoryTableItem* dataItem in selectedItems)
                [arr addObject:dataItem.item];
            [[OAHistoryHelper sharedInstance] removePoints:arr];
            [self onRightNavbarButtonPressed];
        }];
        [removeAlert addAction:yesAction];
        
        [self presentViewController:removeAlert animated:YES completion:nil];
    }
    else
    {
        [self dismissViewController];
    }
}
    
- (void)onRightNavbarButtonPressed
{
    [self.tableView setEditing:![self.tableView isEditing] animated:YES];
    [self updateNavbar];
}


#pragma mark - Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDecelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        isDecelerating = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
}

#pragma mark - OAMultiselectableHeaderDelegate

- (void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
    
    [self.tableView beginUpdates];
    if (value)
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.tableView endUpdates];
}

#pragma mark - Swipe Delegate

- (BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction;
{
    return YES;
}

- (NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    
    if (direction == MGSwipeDirectionRightToLeft)
    {
        //expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 10.0;
        
        CGFloat padding = 15;
        
        NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
        
        HistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
        HistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
        
        MGSwipeButton *remove = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     [self remove:dataItem];
                                     return YES;
                                 }];
        return @[remove];
    }
    
    return nil;
}

@end
