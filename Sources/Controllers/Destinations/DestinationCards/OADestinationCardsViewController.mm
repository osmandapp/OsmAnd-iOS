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
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"

#import "OADestinationCardHeaderView.h"
#import "OADestinationCardBaseController.h"
#import "OADirectionsCardController.h"
#import "OARootViewController.h"
#import "OADestinationsHelper.h"
#import "OAHistoryCardController.h"
#import "OAHistoryHelper.h"
#import "OAHistoryViewController.h"
#import "OADirectionAppearanceViewController.h"

#import "OsmAndApp.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAAutoObserverProxy.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"
#import "OAColors.h"

@interface OADestinationCardsViewController () <MGSwipeTableCellDelegate, OADestinationCardBaseControllerDelegate, UIGestureRecognizerDelegate>

@end

@implementation OADestinationCardsViewController
{
    OsmAndAppInstance _app;
    
    NSArray *_sections;

    BOOL isDecelerating;
    NSIndexPath *indexPathForSwipingCell;
    
    OAAutoObserverProxy *_historyPointAddObserver;
    UIView *_navBarBackgroundView;
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
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 10.0)];
    
    [self.tableView setEditing:YES animated:YES];
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOutsideCells)];
    tapRec.delegate = self;
    
    [self.tableView addGestureRecognizer:tapRec];
    _leftTableViewPadding.constant += OAUtilities.getLeftMargin;
    _rightTableViewPadding.constant += OAUtilities.getLeftMargin;
    [self configureBottomToolbar];
}

- (void) configureBottomToolbar
{
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        self.bottomView.backgroundColor = UIColor.clearColor;
        
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        blurEffectView.frame = self.view.frame;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _navBarBackgroundView = blurEffectView;
        [self.bottomView insertSubview:_navBarBackgroundView atIndex:0];
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    [self.bottomToolBar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.bottomToolBar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    _toolBarHeight.constant += bottomMargin;
    _historyViewButton.title = OALocalizedString(@"history");
    _appearanceViewButton.title = OALocalizedString(@"map_settings_appearance");
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _isHiding = NO;
    _isVisible = YES;
    
    indexPathForSwipingCell = nil;
    isDecelerating = NO;
    
    [self generateData];
    
    _historyPointAddObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onHistoryPointAdded:withKey:)
                                                          andObserve:[OAHistoryHelper sharedInstance].historyPointAddObservable];

}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (_historyPointAddObserver)
    {
        [_historyPointAddObserver detach];
        _historyPointAddObserver = nil;
    }

    _isHiding = NO;
    
    [self deactivateCards];
}

-(void)doViewWillDisappear
{
    _isHiding = YES;
    _isVisible = NO;
}

- (void)onHistoryPointAdded:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL hasHistoryCard = NO;
        for (OADestinationCardBaseController *cardCtrl in _sections)
        {
            if ([cardCtrl isKindOfClass:[OAHistoryCardController class]])
            {
                hasHistoryCard = YES;
                break;
            }
        }
        
        if (!hasHistoryCard)
        {
            [self generateData:YES];

            /*
            [self.tableView beginUpdates];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:_sections.count - 1] withRowAnimation:UITableViewRowAnimationBottom];
            [self.tableView endUpdates];
            */
        }
        
    });
}

- (void)activateCards
{
    for (OADestinationCardBaseController *cardCtrl in _sections)
        [cardCtrl onAppear];
}

- (void)deactivateCards
{
    for (OADestinationCardBaseController *cardCtrl in _sections)
        [cardCtrl onDisappear];
}

-(void)generateData
{
    _sections = nil;
    [self generateData:YES];
}

-(void)generateData:(BOOL)reload
{
    NSInteger index = 0;
    
    NSMutableArray *sections = [NSMutableArray array];
    
    [self deactivateCards];
    
    // Add cards

    if ([[OADestinationsHelper instance] pureDestinationsCount] > 0)
    {
        OADirectionsCardController *directionsCardController;
        for (OADestinationCardBaseController *card in _sections)
            if ([card isKindOfClass:[OADirectionsCardController class]])
            {
                directionsCardController = (OADirectionsCardController *)card;
                break;
            }
        
        if (!directionsCardController)
            directionsCardController = [[OADirectionsCardController alloc] initWithSection:index++ tableView:self.tableView];
        else
            [directionsCardController updateSectionNumber:index++];

        directionsCardController.delegate = self;
        [sections addObject:directionsCardController];
    }

    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
    if ([helper getPointsHavingTypes:helper.destinationTypes limit:1].count > 0)
    {
        OAHistoryCardController *historyCardController;
        for (OADestinationCardBaseController *card in _sections)
            if ([card isKindOfClass:[OAHistoryCardController class]])
            {
                historyCardController = (OAHistoryCardController *)card;
                break;
            }
        
        if (!historyCardController)
            historyCardController = [[OAHistoryCardController alloc] initWithSection:index++ tableView:self.tableView];
        else
            [historyCardController updateSectionNumber:index++];
        
        historyCardController.delegate = self;
        [sections addObject:historyCardController];
    }
    
    _sections = [NSArray arrayWithArray:sections];

    [self activateCards];
    
    if (reload)
        [self.tableView reloadData];
}

- (void)tapOutsideCells
{
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
}

- (IBAction)onHistoryButtonClicked:(id)sender {
    OAHistoryViewController *history = [[OAHistoryViewController alloc] init];
    [[OARootViewController instance].navigationController pushViewController:history animated:YES];
}

- (IBAction)onAppearanceButtonClicked:(id)sender {
    OADirectionAppearanceViewController *directionAppearance = [[OADirectionAppearanceViewController alloc] init];
    [[OARootViewController instance].navigationController pushViewController:directionAppearance animated:YES];
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
    {
        cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, DeviceScreenWidth - 2 * [OAUtilities getLeftMargin] - 16, cell.frame.size.height);
        [OAUtilities roundCornersOnView:cell onTopLeft:NO topRight:NO bottomLeft:YES bottomRight:YES radius:4.0];
    }
    else
        cell.layer.mask = nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MGSwipeTableCell *cell = (MGSwipeTableCell *)[[self getCardController:indexPath.section] cellForRow:indexPath.row];
    cell.delegate = self;
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self getCardController:indexPath.section] isKindOfClass:OADirectionsCardController.class];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (sourceIndexPath.section != proposedDestinationIndexPath.section)
        return sourceIndexPath;
    else
        return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [[self getCardController:sourceIndexPath.section] reorderObjects:sourceIndexPath.row dest:destinationIndexPath.row];
    [self.tableView reloadData];
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
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
    if ((gestureIsActive || state != MGSwipeStateNone) && state != MGSwipeStateSwippingLeftToRight)
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
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationLeft];
    
    NSInteger sectionsCount = _sections.count;
    [self generateData:NO];

    if (_sections.count >= sectionsCount)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_sections.count - 1, ABS(_sections.count - sectionsCount) + 1)] withRowAnimation:UITableViewRowAnimationBottom];
    
    //if (_sections.count == 0 || [_sections[0] isKindOfClass:[OAHistoryCardController class]])
        [[OARootViewController instance].mapPanel hideDestinationCardsView];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (_sections.count == 0)
        return YES;
        
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[self getCardController:_sections.count - 1] rowsCount] - 1 inSection:_sections.count - 1];
    CGRect rect = [self.tableView convertRect:[self.tableView rectForRowAtIndexPath:indexPath] toView:[self.tableView superview]];
    return [touch locationInView:self.tableView].y > rect.origin.y + rect.size.height; //[touch.view isKindOfClass:[UITableView class]];
}

@end
