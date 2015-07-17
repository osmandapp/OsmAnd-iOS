//
//  OADestinationListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCardsViewController.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAIconTextTableViewCell.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"

#import "OADestinationCardHeaderView.h"
#import "OADestinationCardBaseController.h"
#import "OAGPXRouteCardController.h"
#import "OADirectionsCardController.h"
#import "OARootViewController.h"
#import "OADestinationsHelper.h"

#import "OsmAndApp.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

@interface OADestinationCardsViewController () <MGSwipeTableCellDelegate, OADestinationCardBaseControllerDelegate>

@end

@implementation OADestinationCardsViewController
{
    OsmAndAppInstance _app;
    
    NSArray *_sections;

    BOOL isDecelerating;
    
    NSIndexPath *indexPathForSwipingCell;
}

+ (OADestinationCardsViewController *)sharedInstance
{
    static OADestinationCardsViewController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OADestinationCardsViewController alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        isDecelerating = NO;
        _isVisible = NO;
    }
    return self;
}

- (OADestinationCardBaseController *)getCardController:(NSInteger)section
{
    return (OADestinationCardBaseController *)_sections[section];
}

- (id)getItem:(NSIndexPath *)indexPath
{
    OADestinationCardBaseController* cardController = [self getCardController:indexPath.section];
    return [cardController getItem:indexPath.row];
}

- (void)updateCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    OADestinationCardBaseController* cardController = [self getCardController:indexPath.section];
    id item = [cardController getItem:indexPath.row];
    if (item)
        [cardController updateCell:cell item:item row:indexPath.row];
}

- (void)refreshSwipeButtonsAtIndexPath:(NSIndexPath *)indexPath
{
    MGSwipeTableCell *cell = (MGSwipeTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell refreshButtons:YES];
}

- (void)refreshFirstRow:(NSInteger)section
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        [self updateCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        [self.tableView endUpdates];
    });
}

- (void)refreshVisibleRows:(NSInteger)section
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
            if (i.section == section)
                [self updateCellAtIndexPath:i];

        [self.tableView endUpdates];
    });
}

- (void)refreshAllRows:(NSInteger)section
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        
        OADestinationCardBaseController *cardController = [self getCardController:section];
        for (NSInteger i = 0; i < [cardController rowsCount]; i++)
            [self updateCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]];
        
        [self.tableView endUpdates];
    });
}

- (void)refreshSwipeButtons:(NSInteger)section
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //[self.tableView beginUpdates];
        
        OADestinationCardBaseController *cardController = [self getCardController:section];
        for (NSInteger i = 0; i < [cardController rowsCount]; i++)
            [self refreshSwipeButtonsAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]];
        
        //[self.tableView endUpdates];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    /*
    CGFloat w = DeviceScreenHeight;
    
    [UIView animateWithDuration:duration animations:^{
    
        for (OADestinationCardHeaderView *cardHeaderView in _headerViews)
        {
            cardHeaderView.frame = CGRectMake(0.0, 0.0, w - 16.0, 50.0);
        }
    }];
     */
}

- (void)doViewWillAppear
{
    _isHiding = NO;
    _isVisible = YES;

    indexPathForSwipingCell = nil;
    isDecelerating = NO;
    
    [self generateData];

    for (OADestinationCardBaseController *cardController in _sections)
        [cardController onAppear];
}

- (void)doViewDisappeared
{
    _isHiding = NO;
    
    for (OADestinationCardBaseController *cardController in _sections)
        [cardController onDisappear];
}

-(void)doViewWillDisappear
{
    _isHiding = YES;
    _isVisible = NO;
}

-(void)generateData
{
    [self generateData:YES];
}

-(void)generateData:(BOOL)reload
{
    NSInteger index = 0;
    
    NSMutableArray *sections = [NSMutableArray array];
    
    // Add cards
    
    if ([OAGPXRouter sharedInstance].routeDoc && [OAGPXRouter sharedInstance].routeDoc.activePoints.count > 0)
    {
        OAGPXRouteCardController *gpxRouteCardController = [[OAGPXRouteCardController alloc] initWithSection:index++ tableView:self.tableView];
        gpxRouteCardController.delegate = self;
        [sections addObject:gpxRouteCardController];
    }

    if ([[OADestinationsHelper instance] pureDestinationsCount] > 0)
    {
        OADirectionsCardController *directionsCardController = [[OADirectionsCardController alloc] initWithSection:index++ tableView:self.tableView];
        directionsCardController.delegate = self;
        [sections addObject:directionsCardController];
    }

    _sections = [NSArray arrayWithArray:sections];

    if (reload)
        [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[self getCardController:section] cardHeaderView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self getCardController:section] rowsCount];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [[self getCardController:indexPath.section] rowsCount] - 1)
        [OAUtilities roundCornersOnView:cell onTopLeft:NO topRight:NO bottomLeft:YES bottomRight:YES radius:4.0];
    else
        cell.layer.mask = nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MGSwipeTableCell *cell = (MGSwipeTableCell *)[[self getCardController:indexPath.section] cellForRow:indexPath.row];
    cell.delegate = self;
    return cell;
}


#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDecelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        isDecelerating = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[self getCardController:indexPath.section] didSelectRow:indexPath.row];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [[self getCardController:section] cardHeaderView].bounds.size.height;
}

#pragma mark Swipe Delegate

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction;
{
    return YES;
}

-(NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;

    if (direction == MGSwipeDirectionRightToLeft)
    {
        //expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 10.0;
                
        NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
        return [[self getCardController:indexPath.section] getSwipeButtons:indexPath.row];
    }

    return nil;
}

-(void) swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (gestureIsActive || state != MGSwipeStateNone)
    {
        indexPathForSwipingCell = indexPath;
        cell.showsReorderControl = NO;
    }
    else if ([indexPath isEqual:indexPathForSwipingCell])
    {
        indexPathForSwipingCell = nil;
        cell.showsReorderControl = YES;
    }
    else
    {
        cell.showsReorderControl = YES;
    }
}


#pragma mark - OADestinationCardBaseControllerDelegate

-(void)indexPathForSwipingCellChanged:(NSIndexPath *)indexPath
{
    indexPathForSwipingCell = indexPath;
}

- (void)showActiveSheet:(UIActionSheet *)activeSheet
{
    [activeSheet showInView:self.view];
}

- (BOOL)isDecelerating
{
    return isDecelerating;
}

- (BOOL)isSwiping
{
    return indexPathForSwipingCell != nil;
}


-(void)cardRemoved:(NSInteger)section
{
    [[self getCardController:section] onDisappear];
    [self generateData:NO];
    
    if (_sections.count == 0)
        [[OARootViewController instance].mapPanel openHideDestinationCardsView];
}

@end
