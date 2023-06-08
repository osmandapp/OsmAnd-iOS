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
#import "OATitleDescrDraggableCell.h"
#import "OAMultiselectableHeaderView.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"

#import <AudioToolbox/AudioServices.h>

@interface OAQuickActionListViewController () <MGSwipeTableCellDelegate, OAMultiselectableHeaderDelegate, OAQuickActionListDelegate>

@end

@implementation OAQuickActionListViewController
{
    OAQuickActionRegistry *_registry;
    NSMutableArray<OAQuickAction *> *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _registry = [OAQuickActionRegistry sharedInstance];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OAMultiselectableHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

#pragma mark - Base setup UI

- (void)setupBottomFonts
{
    self.topButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.bottomButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return self.tableView.editing ? OALocalizedString(@"quick_action_edit_list") : OALocalizedString(@"configure_screen_quick_action");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return self.tableView.editing ? OALocalizedString(@"shared_string_cancel") : nil;
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    if (self.tableView.editing)
    {
        return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                      iconName:nil
                                        action:@selector(donePressed)
                                          menu:nil]];
    }
    else
    {
        UIBarButtonItem *addButton = [self createRightNavbarButton:nil
                                                          iconName:@"ic_navbar_add"
                                                            action:@selector(addActionPressed)
                                                              menu:nil];
        
        UIBarButtonItem *aditButton = [self createRightNavbarButton:nil
                                                           iconName:@"ic_navbar_pencil"
                                                             action:@selector(editPressed)
                                                               menu:nil];
        
        addButton.accessibilityLabel = OALocalizedString(@"shared_string_add");
        aditButton.accessibilityLabel = OALocalizedString(@"shared_string_edit");
        
        return @[addButton, aditButton];
    }
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"quick_action_add_actions_descr");
}

- (UILayoutConstraintAxis)getBottomAxisMode
{
    return UILayoutConstraintAxisHorizontal;
}

- (NSString *)getTopButtonTitle
{
    return self.tableView.editing ? OALocalizedString(@"shared_string_select_all") : @"";
}

- (NSString *)getBottomButtonTitle
{
    return self.tableView.editing ? OALocalizedString(@"shared_string_delete") : @"";
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [NSMutableArray arrayWithArray:_registry.getQuickActions];
}

- (NSInteger)sectionsCount
{
    return [self getScreensCount];
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    OAMultiselectableHeaderView *vw = (OAMultiselectableHeaderView *)[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [vw setTitleText:[NSString stringWithFormat:OALocalizedString(@"quick_action_screen_header"), section + 1]];
    vw.section = section;
    vw.delegate = self;
    return vw;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 46.0;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    BOOL oneSection = _data.count / 6 < 1;
    BOOL lastSection = section == _data.count / 6;
    return oneSection || lastSection ? _data.count % 6 : 6;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAQuickAction *action = [self getAction:indexPath];
    OATitleDescrDraggableCell* cell = (OATitleDescrDraggableCell *)[self.tableView dequeueReusableCellWithIdentifier:[OATitleDescrDraggableCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrDraggableCell getCellIdentifier] owner:self options:nil];
        cell = (OATitleDescrDraggableCell *)[nib objectAtIndex:0];
        cell.descView.hidden = YES;
    }
    
    if (cell)
    {
        [cell.textView setText:action.getName];
        [cell.iconView setImage:[UIImage templateImageNamed:action.getIconResName]];
        [cell.iconView setTintColor:UIColorFromRGB(color_poi_orange)];
        if (cell.iconView.subviews.count > 0)
            [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (action.hasSecondaryIcon)
        {
            CGRect frame = CGRectMake(0., 0., cell.iconView.frame.size.width, cell.iconView.frame.size.height);
            UIImage *imgBackground = [UIImage templateImageNamed:@"ic_custom_compound_action_background"];
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
        [cell.overflowButton setImage:[UIImage templateImageNamed:@"menu_cell_pointer"] forState:UIControlStateNormal];
        [cell.overflowButton setTintColor:UIColorFromRGB(color_tint_gray)];
        [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
        cell.tintColor = UIColorFromRGB(color_primary_purple);
        
        [cell updateConstraintsIfNeeded];
    }
    return cell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
        return;
    
    [self openQuickActionSetupFor:indexPath];
}

#pragma mark - UITableViewDataSource

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
    [self.tableView reloadData];
}

#pragma mark - Additions

- (void)saveChanges
{
    [_registry updateQuickActions:[NSArray arrayWithArray:_data]];
    [_registry.quickActionListChangedObservable notifyEvent];
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

- (void)disableEditing
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:NO animated:YES];
    [self updateUI:YES];
    [self.tableView endUpdates];
}

- (OAQuickAction *)getAction:(NSIndexPath *)indexPath
{
    if (_data.count == 1)
        return _data.firstObject;
    return _data[6 * indexPath.section + indexPath.row];
}

- (void)openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickAction *item = [self getAction:indexPath];
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:item isNew:NO];
    actionScreen.delegate = self;
    [self.navigationController pushViewController:actionScreen animated:YES];
}

#pragma mark - Selectors

- (void)editPressed
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:YES animated:YES];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self updateUI:YES];
    [self.tableView endUpdates];
}

- (void)onLeftNavbarButtonPressed
{
    [self disableEditing];
    _data = [NSMutableArray arrayWithArray:_registry.getQuickActions];
    [self.tableView reloadData];
}

- (void)donePressed
{
    [self disableEditing];
    [self saveChanges];
}

- (void)addActionPressed
{
    OAAddQuickActionViewController *vc = [[OAAddQuickActionViewController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTopButtonPressed
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

- (void)onBottomButtonPressed
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
            [self editPressed];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction;
{
    return self.tableView.isEditing;
}

- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    if (state != MGSwipeStateNone)
        cell.showsReorderControl = NO;
    else
        cell.showsReorderControl = YES;
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

#pragma mark - OAQuickActionListDelegate

- (void)updateData
{
    _data = [NSMutableArray arrayWithArray:_registry.getQuickActions];
    [self.tableView reloadData];
}

@end
