//
//  OAQuickActionListViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionListViewController.h"
#import "OAActionConfigurationViewController.h"
#import "OAAddQuickActionViewController.h"
#import "Localization.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickAction.h"
#import "MGSwipeButton.h"
#import "OATitleDescrDraggableCell.h"
#import "OAMultiselectableHeaderView.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"

#import <AudioToolbox/AudioServices.h>

#define kHeaderViewFont [UIFont systemFontOfSize:15.0]
#define toolbarHeight 64

@interface OAQuickActionListViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate, OAMultiselectableHeaderDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *btnAdd;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *selectAllAction;
@property (weak, nonatomic) IBOutlet UIButton *deleteAction;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIButton *btnDone;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeight;

@end

@implementation OAQuickActionListViewController
{
    OAQuickActionRegistry *_registry;
    NSMutableArray<OAQuickAction *> *_data;
    
    UIView *_tableHeaderView;
    UIView *_toolbarBackgroundView;
    CALayer *_horizontalLine;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48.0;
    [self.tableView registerClass:OAMultiselectableHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [self.btnAdd setImage:[[UIImage imageNamed:@"ic_custom_add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.btnAdd setTintColor:UIColor.whiteColor];
    [self.btnEdit setImage:[[UIImage imageNamed:@"ic_custom_edit"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.btnEdit setTintColor:UIColor.whiteColor];
    self.tableView.tableHeaderView = _tableHeaderView;
    _bottomViewHeight.constant = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
}

-(void) commonInit
{
    _registry = [OAQuickActionRegistry sharedInstance];
    _data = [NSMutableArray arrayWithArray:_registry.getQuickActions];
    
    _tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"quick_action_add_actions_descr") font:kHeaderViewFont textColor:UIColor.blackColor lineSpacing:0.0 isTitle:NO];
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        blurEffectView.frame = _toolBarView.frame;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _toolbarBackgroundView = blurEffectView;
        [_toolBarView insertSubview:_toolbarBackgroundView atIndex:0];
        _toolBarView.backgroundColor = UIColor.clearColor;
    }
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    [self.toolBarView.layer addSublayer:_horizontalLine];
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"quick_action_name");
    [_deleteAction setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
    [_selectAllAction setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [_btnCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_btnDone setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void)applySafeAreaMargins
{
    [super applySafeAreaMargins];
    CGRect tableViewFrame = _tableView.frame;
    tableViewFrame.size.height += _toolBarView.frame.size.height;
    _tableView.frame = tableViewFrame;
    UIEdgeInsets insets = _tableView.contentInset;
    insets.bottom = _toolBarView.frame.size.height;
    _tableView.contentInset = insets;
    _toolbarBackgroundView.frame = _toolBarView.bounds;
    
    CGFloat btnWidth = (DeviceScreenWidth - 32.0 - OAUtilities.getLeftMargin * 2) / 2;
    _selectAllAction.frame = CGRectMake(16.0 + OAUtilities.getLeftMargin, 13.0, btnWidth, 22.0);
    _deleteAction.frame = CGRectMake(CGRectGetMaxX(_selectAllAction.frame), 13.0, btnWidth, 22.0);
}

- (void)saveChanges
{
    [_registry updateQuickActions:[NSArray arrayWithArray:_data]];
    [_registry.quickActionListChangedObservable notifyEvent];
}

- (IBAction)editPressed:(id)sender
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:YES animated:YES];
    _toolBarView.hidden = NO;
    _btnCancel.hidden = NO;
    _btnDone.hidden = NO;
    _btnAdd.hidden = YES;
    _btnEdit.hidden = YES;
    _backBtn.hidden = YES;
    [UIView animateWithDuration:.3 animations:^{
        _titleView.text = OALocalizedString(@"quick_action_edit_list");
        _bottomViewHeight.constant = toolbarHeight;
        [self applySafeAreaMargins];
    }];
    [self.tableView endUpdates];
}

- (IBAction)donePressed:(id)sender
{
    [self disableEditing];
    [self saveChanges];
}

- (IBAction)cancelPressed:(id)sender
{
    [self disableEditing];
    _data = [NSMutableArray arrayWithArray:_registry.getQuickActions];
    [self.tableView reloadData];
}

- (void) disableEditing
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:NO animated:YES];
    _btnAdd.hidden = NO;
    _btnEdit.hidden = NO;
    _backBtn.hidden = NO;
    _btnCancel.hidden = YES;
    _btnDone.hidden = YES;
    [UIView animateWithDuration:.3 animations:^{
        _titleView.text = OALocalizedString(@"quick_action_name");
        [self.tabBarController.tabBar setHidden:NO];
        _bottomViewHeight.constant = 0;
    } completion:^(BOOL finished) {
        _toolBarView.hidden = YES;
        [self applySafeAreaMargins];
    }];
    [self.tableView endUpdates];
}

- (IBAction)addActionPressed:(id)sender
{
    OAAddQuickActionViewController *vc = [[OAAddQuickActionViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void) openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickAction *item = [self getAction:indexPath];
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:item isNew:NO];
    [self.navigationController pushViewController:actionScreen animated:YES];
}

- (NSInteger)getScreensCount
{
    NSInteger numOfItems = _data.count;
    BOOL oneSection = numOfItems / 6 < 1;
    BOOL hasRemainder = numOfItems % 6 != 0;
    if (oneSection)
        return 1;
    else
        return (numOfItems / 6) + (hasRemainder ? 1 : 0);
}

- (OAQuickAction *) getAction:(NSIndexPath *)indexPath
{
    if (_data.count == 1)
        return _data.firstObject;
    return _data[6 * indexPath.section + indexPath.row];
}

- (IBAction)selectAllPressed:(id)sender
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

- (IBAction)deletePressed:(id)sender
{
    NSArray *indexes = [self.tableView indexPathsForSelectedRows];
    if (indexes.count > 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:
                                    [NSString stringWithFormat:OALocalizedString(@"confirm_bulk_delete"), indexes.count]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSMutableArray *dataCopy = [NSMutableArray arrayWithArray:_data];
            for (NSIndexPath *path in indexes)
            {
                OAQuickAction *item = [self getAction:path];
                [dataCopy removeObject:item];
            }
            _data = dataCopy;
            [self saveChanges];
            [self.tableView reloadData];
            [self editPressed:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self applySafeAreaMargins];
        CGFloat textWidth = DeviceScreenWidth - 32.0 - OAUtilities.getLeftMargin * 2;
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        CGSize labelSize = [OAUtilities calculateTextBounds:OALocalizedString(@"quick_action_add_actions_descr") width:textWidth font:labelFont];
        _tableHeaderView.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, labelSize.height + 30.0);
        _tableHeaderView.subviews.firstObject.frame = CGRectMake(16.0 + OAUtilities.getLeftMargin, 20.0, textWidth, labelSize.height);
        _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    } completion:nil];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OAMultiselectableHeaderView *vw = (OAMultiselectableHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [vw setTitleText:[NSString stringWithFormat:OALocalizedString(@"quick_action_screen_header"), section + 1]];
    vw.section = section;
    vw.delegate = self;
    return vw;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 46.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableView.isEditing)
        return;
    
    [self openQuickActionSetupFor:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (_data.count == 1)
        return;
    
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    NSInteger destRow = destinationIndexPath.row;
    if (destRow == [tableView numberOfRowsInSection:destinationIndexPath.section] - 1)
        destinationIndexPath = [NSIndexPath indexPathForRow:destRow - 1 inSection:destinationIndexPath.section];
        
    OAQuickAction *sourceAction = [self getAction:sourceIndexPath];
    OAQuickAction *destAction = [self getAction:destinationIndexPath];
    [_data setObject:sourceAction atIndexedSubscript:destinationIndexPath.section * 6 + destinationIndexPath.row];
    [_data setObject:destAction atIndexedSubscript:sourceIndexPath.section * 6 + sourceIndexPath.row];
    [_tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.isEditing;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAQuickAction *action = [self getAction:indexPath];
    OATitleDescrDraggableCell* cell = (OATitleDescrDraggableCell *)[tableView dequeueReusableCellWithIdentifier:[OATitleDescrDraggableCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrDraggableCell getCellIdentifier] owner:self options:nil];
        cell = (OATitleDescrDraggableCell *)[nib objectAtIndex:0];
        cell.descView.hidden = YES;
    }
    
    if (cell)
    {
        [cell.textView setText:action.getName];
        [cell.iconView setImage:[UIImage imageNamed:action.getIconResName]];
        if (cell.iconView.subviews.count > 0)
            [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (action.hasSecondaryIcon)
        {
            CGRect frame = CGRectMake(0., 0., cell.iconView.frame.size.width, cell.iconView.frame.size.height);
            UIImage *imgBackground = [[UIImage imageNamed:@"ic_custom_compound_action_background"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
            [background setTintColor:UIColor.whiteColor];
            [cell.iconView addSubview:background];
            UIImage *img = [UIImage imageNamed:action.getSecondaryIconName];
            UIImageView *view = [[UIImageView alloc] initWithImage:img];
            view.frame = frame;
            [cell.iconView addSubview:view];
        }
        cell.delegate = self;
        cell.allowsSwipeWhenEditing = NO;
        [cell.overflowButton setImage:[[UIImage imageNamed:@"menu_cell_pointer.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [cell.overflowButton setTintColor:UIColorFromRGB(color_tint_gray)];
        [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
        cell.tintColor = UIColorFromRGB(color_primary_purple);
        
        [cell updateConstraintsIfNeeded];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self getScreensCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL oneSection = _data.count / 6 < 1;
    BOOL lastSection = section == _data.count / 6;
    return oneSection || lastSection ? _data.count % 6 : 6;
}

#pragma mark - Swipe Delegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction;
{
    return _tableView.isEditing;
}

- (void) swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    if (state != MGSwipeStateNone)
        cell.showsReorderControl = NO;
    else
        cell.showsReorderControl = YES;
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
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

@end
