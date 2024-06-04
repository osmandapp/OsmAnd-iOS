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
#import "OAFloatingButtonsHudViewController.h"
#import "Localization.h"
#import "OAMapButtonsHelper.h"
#import "OAQuickAction.h"
#import "OATitleDescrDraggableCell.h"
#import "OAMultiselectableHeaderView.h"
#import "OATableViewCustomHeaderView.h"
#import "OASwitchTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#import <AudioToolbox/AudioServices.h>

#define kEnableSection 0
#define kRowsPerSection 6

@interface OAQuickActionListViewController () <MGSwipeTableCellDelegate, OAMultiselectableHeaderDelegate, OAQuickActionListDelegate>

@end

@implementation OAQuickActionListViewController
{
    NSMutableArray<OAQuickAction *> *_data;
    OAMapButtonsHelper *_mapButtonsHelper;
    OAQuickActionButtonState *_buttonState;
}

#pragma mark - Initialization

- (instancetype)initWithButtonState:(OAQuickActionButtonState *)buttonState
{
    self = [super init];
    if (self)
    {
        _buttonState = buttonState;
    }
    return self;
}

- (void)commonInit
{
    _mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OAMultiselectableHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
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
    _data = [NSMutableArray arrayWithArray:_buttonState.quickActions];
}

- (NSInteger)sectionsCount
{
    // Add enable section
    return [self getScreensCount] + 1;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    if (section == kEnableSection)
        return nil;
    OAMultiselectableHeaderView *vw = (OAMultiselectableHeaderView *)[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [vw setTitleText:[NSString stringWithFormat:OALocalizedString(@"quick_action_screen_header"), section]];
    vw.section = section;
    vw.delegate = self;
    return vw;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    if (section == kEnableSection)
        return 0.;
    return 46.0;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == kEnableSection)
        return 1;
    else if (_data.count <= kRowsPerSection)
        return _data.count;
	else if (section == [self getScreensCount] && _data.count % kRowsPerSection > 0)
        return _data.count % kRowsPerSection;
    else
        return kRowsPerSection;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    if (indexPath.section == kEnableSection)
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.switchView.on = [_buttonState isEnabled];
            cell.titleLabel.text = OALocalizedString(@"shared_string_enabled");

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
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
        [cell.iconView setImage:[action getActionIcon]];
        [cell.iconView setTintColor:[UIColor colorNamed:ACColorNameIconColorSelected]];
        if (cell.iconView.subviews.count > 0)
            [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (action.hasSecondaryIcon)
        {
            CGRect frame = CGRectMake(0., 0., cell.iconView.frame.size.width, cell.iconView.frame.size.height);
            UIImage *imgBackground = [UIImage templateImageNamed:@"ic_custom_compound_action_background"];
            UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
            [background setTintColor:[UIColor colorNamed:ACColorNameGroupBg]];
            [cell.iconView addSubview:background];
            UIImage *img = [UIImage imageNamed:action.getSecondaryIconName];
            UIImageView *view = [[UIImageView alloc] initWithImage:img];
            view.frame = frame;
            [cell.iconView addSubview:view];
        }
        cell.delegate = self;
        cell.allowsSwipeWhenEditing = NO;
        [cell.overflowButton setImage:[UIImage templateImageNamed:@"menu_cell_pointer"] forState:UIControlStateNormal];
        [cell.overflowButton setTintColor:[UIColor colorNamed:ACColorNameIconColorSecondary]];
        [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
        cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        
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
    if (_data.count == 1 || sourceIndexPath == destinationIndexPath)
    {
        return;
    }
    
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    OAQuickAction *sourceAction = [self getAction:sourceIndexPath];
    NSInteger destinationIndex = kRowsPerSection * (destinationIndexPath.section - 1) + destinationIndexPath.row;
    if (sourceIndexPath.section != destinationIndexPath.section && destinationIndex == _data.count)
    {
        destinationIndex--;
    }
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [_data removeObjectAtIndex:(sourceIndexPath.section - 1) * kRowsPerSection + sourceIndexPath.row];
    [_data insertObject:sourceAction atIndex:destinationIndex];
    [CATransaction commit];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != kEnableSection;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != kEnableSection;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section == kEnableSection)
    {
        return sourceIndexPath;
    }
    NSInteger lastSectionIndex = [tableView numberOfSections] - 1;
    if (proposedDestinationIndexPath.section == lastSectionIndex)
    {
        return sourceIndexPath;
    }
    else if (proposedDestinationIndexPath.section >= self.sectionsCount)
    {
        NSInteger prevSection = proposedDestinationIndexPath.section - 1;
        return [NSIndexPath indexPathForRow:[self rowsCount:prevSection] - 1 inSection:prevSection];
    }
    return proposedDestinationIndexPath;
}

#pragma mark - Additions

- (void)saveChanges
{
    [_mapButtonsHelper updateQuickActions:_buttonState actions:_data];
    if (self.quickActionUpdateCallback)
        self.quickActionUpdateCallback();
}

- (NSInteger)getScreensCount
{
    if (_data.count == 0)
        return 0;
    else if (_data.count <= kRowsPerSection)
        return 1;
    else
        return (int)(floor((_data.count - 1.0) / kRowsPerSection)) + 1;
}

- (void)disableEditing
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:NO animated:YES];
    [self updateUIAnimated:nil];
    [self.tableView endUpdates];
}

- (OAQuickAction *)getAction:(NSIndexPath *)indexPath
{
    return _data[kRowsPerSection * (indexPath.section - 1) + indexPath.row];
}

- (void)openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickAction *item = [self getAction:indexPath];
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithButtonState:_buttonState action:item];
    actionScreen.delegate = self;
    [self.navigationController pushViewController:actionScreen animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(UISwitch *)sender
{
    [_buttonState setEnabled:sender.isOn];
    [self.delegate onWidgetStateChanged];
}

- (void)editPressed
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:YES animated:YES];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self updateUIAnimated:nil];
    [self.tableView endUpdates];
}

- (void)onLeftNavbarButtonPressed
{
    [self disableEditing];
    [self updateData];
}

- (void)donePressed
{
    [self saveChanges];
    [self disableEditing];
}

- (void)addActionPressed
{
    OAAddQuickActionViewController *vc = [[OAAddQuickActionViewController alloc] initWithButtonState:_buttonState];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTopButtonPressed
{
    NSInteger sections = self.tableView.numberOfSections;
    
    [self.tableView beginUpdates];
    for (NSInteger section = 1; section < sections; section++)
    {
        NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
        for (NSInteger row = 0; row < rowsCount; row++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
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
            NSMutableArray<OAQuickAction *> *dataCopy = [NSMutableArray arrayWithArray:_data];
            for (NSIndexPath *path in indexes)
            {
                [dataCopy removeObject:[self getAction:path]];
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
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
        {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]
                                          animated:YES];
        }
    }
    [self.tableView endUpdates];
}

#pragma mark - OAQuickActionListDelegate

- (void)updateData
{
    [self reloadDataWithAnimated:YES completion:nil];
    if (self.quickActionUpdateCallback)
        self.quickActionUpdateCallback();
}

@end
