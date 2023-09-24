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
#import "OAQuickActionRegistry.h"
#import "OAQuickAction.h"
#import "OATitleDescrDraggableCell.h"
#import "OAMultiselectableHeaderView.h"
#import "OAColors.h"
#import "OAAppSettings.h"
#import "OATableViewCustomHeaderView.h"
#import "OASwitchTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAQuickActionListViewController () <OAMultiselectableHeaderDelegate, OAQuickActionListDelegate>

@property(nonatomic) BOOL editMode;

@end

@implementation OAQuickActionListViewController
{
    OAQuickActionRegistry *_registry;
    OAAppSettings *_settings;
    OATableSectionData *_switchSection;
}

#pragma mark - Initialization

- (void)commonInit
{
    _registry = [OAQuickActionRegistry sharedInstance];
    _settings = [OAAppSettings sharedManager];

    _switchSection = [OATableSectionData sectionData];
    OATableRowData *switchRow = [_switchSection createNewRow];
    switchRow.key = @"pref";
    switchRow.title = OALocalizedString(@"shared_string_enabled");
    switchRow.cellType = [OASwitchTableViewCell getCellIdentifier];
    [switchRow setObj:_settings.quickActionIsOn forKey:@"pref"];
}

- (void)setEditMode:(BOOL)editMode
{
    _editMode = editMode;
    [self.tableView setEditing:editMode animated:YES];
    if ([self.tableData hasChanged])
    {
        [self updateUI:YES completion:^{
            [self updateSwitchSection];
        }];
    }
    else
    {
        [self updateUIWithoutData:^{
            [self updateSwitchSection];
        }];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OAMultiselectableHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _editMode ? OALocalizedString(@"quick_action_edit_list") : OALocalizedString(@"configure_screen_quick_action");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return _editMode ? OALocalizedString(@"shared_string_cancel") : nil;
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    if (_editMode)
    {
        return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                      iconName:nil
                                        action:@selector(onRightNavbarButtonPressed)
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
                                                             action:@selector(onRightNavbarButtonPressed)
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
    return _editMode ? nil : OALocalizedString(@"quick_action_add_actions_descr");
}

- (UILayoutConstraintAxis)getBottomAxisMode
{
    return UILayoutConstraintAxisHorizontal;
}

- (NSString *)getTopButtonTitle
{
    return _editMode
        ? self.tableView.indexPathsForSelectedRows.count ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all")
        : @"";
}

- (NSString *)getBottomButtonTitle
{
    return _editMode ? OALocalizedString(@"shared_string_delete") : @"";
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
    [self.tableData clearAllData];

    if (!_editMode)
        [self.tableData addSection:_switchSection];

    OATableSectionData *actionsSection = [self.tableData createNewSection];
    for (NSInteger i = 0; i < _registry.getQuickActions.count; i++)
    {
        OAQuickAction *action = _registry.getQuickActions[i];
        if ([actionsSection rowCount] == 6)
            actionsSection = [self.tableData createNewSection];
        OATableRowData *actionRow = [actionsSection createNewRow];
        actionRow.key = @"action";
        actionRow.cellType = [OASimpleTableViewCell getCellIdentifier];
        [actionRow setObj:action forKey:@"action"];
    }
    [self.tableData resetChanges];
}

- (BOOL)hideFirstHeader
{
    return !_editMode;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
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
            OACommonBoolean *pref = [item objForKey:@"pref"];
            cell.switchView.on = [pref get];
            cell.titleLabel.text = item.title;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.leftIconView.tintColor = UIColorFromRGB(color_poi_orange);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            OAQuickAction *action = [item objForKey:@"action"];
            if (action)
            {
                cell.titleLabel.text = [action getName];
                cell.leftIconView.image = [UIImage templateImageNamed:[action getIconResName]];
                if ([action hasSecondaryIcon])
                {
                    CGRect frame = CGRectMake(0., 0., cell.leftIconView.frame.size.width, cell.leftIconView.frame.size.height);
                    UIImage *imgBackground = [UIImage templateImageNamed:@"ic_custom_compound_action_background"];
                    UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
                    [background setTintColor:UIColor.whiteColor];
                    [cell.leftIconView addSubview:background];
                    UIImage *img = [UIImage imageNamed:action.getSecondaryIconName];
                    UIImageView *view = [[UIImageView alloc] initWithImage:img];
                    view.frame = frame;
                    [cell.leftIconView addSubview:view];
                }
            }
        }
        return cell;
    }
    return nil;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    if (section == 0 && !_editMode)
        return [super getCustomHeightForHeader:section];

    return [OATableViewCustomHeaderView getHeight:[[NSString stringWithFormat:OALocalizedString(@"quick_action_screen_header"), section] upperCase] width:self.tableView.bounds.size.width xOffset:16. yOffset:12. font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    if (section == 0 && !_editMode)
        return nil;

    OAMultiselectableHeaderView *vw = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.delegate = self;
    [self configureHeader:vw forSection:section];

    return vw;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
    {
        [self updateBottomButtons];
        return;
    }

    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"action"])
    {
        OAQuickAction *action = [item objForKey:@"action"];
        if (action)
        {
            OAActionConfigurationViewController *actionScreen =
                [[OAActionConfigurationViewController alloc] initWithAction:action isNew:NO];
            actionScreen.delegate = self;
            [self showViewController:actionScreen];
        }
    }
}

- (void)onRowDeselected:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
        [self updateBottomButtons];
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _editMode;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _editMode;
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    OATableRowData *sourceItem = [self.tableData itemForIndexPath:sourceIndexPath];
    [self.tableData removeRowAt:sourceIndexPath];
    if (destinationIndexPath.section == sourceIndexPath.section)
    {
        [self.tableData addRowAtIndexPath:destinationIndexPath row:sourceItem];
        return;
    }

    OATableSectionData *destinationSectionData = [self.tableData sectionDataForIndex:destinationIndexPath.section];
    if ([destinationSectionData rowCount] < 6)
    {
        [destinationSectionData addRow:sourceItem position:destinationIndexPath.row];
    }
    else
    {
        NSMutableArray<OATableRowData *> *rowsToNextSection = [NSMutableArray array];
        for (NSInteger section = destinationIndexPath.section; section < [self.tableData sectionCount]; section++)
        {
            OATableSectionData *sectionData = [self.tableData sectionDataForIndex:section];
            if (section == destinationIndexPath.section)
                [sectionData addRow:sourceItem position:destinationIndexPath.row];

            if ([sectionData rowCount] > 6)
            {
                NSMutableArray<NSIndexPath *> *indexPathsToDelete = [NSMutableArray array];
                for (NSInteger row = 6; row < [sectionData rowCount]; row++)
                {
                    NSIndexPath *indexPathToDelete = [NSIndexPath indexPathForRow:row inSection:section];
                    [indexPathsToDelete addObject:indexPathToDelete];
                    [rowsToNextSection addObject:[self.tableData itemForIndexPath:indexPathToDelete]];
                }
                for (NSIndexPath *indexPathForDelete in indexPathsToDelete)
                {
                    [sectionData removeRowAtIndex:indexPathForDelete.row];
                }

                if (section == [self.tableData sectionCount] - 1)
                {
                    NSInteger newSectionCount = ceil(rowsToNextSection.count / 6.);
                    for (NSInteger newSection = 0; newSection < newSectionCount; newSection++)
                    {
                        sectionData = [self.tableData createNewSection];
                        NSRange range = NSMakeRange(0, MIN(6, rowsToNextSection.count));
                        [sectionData addRows:[rowsToNextSection subarrayWithRange:range] position:0];
                        [rowsToNextSection removeObjectsInRange:range];
                    }
                }
                else
                {
                    sectionData = [self.tableData sectionDataForIndex:section + 1];
                }

                if (rowsToNextSection.count > 0)
                {
                    [sectionData addRows:rowsToNextSection position:0];
                    [rowsToNextSection removeAllObjects];
                }
            }
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Additions

- (void)configureHeader:(OAMultiselectableHeaderView *)headerView forSection:(NSInteger)section
{
    headerView.section = section;
    [headerView setTitleText:[NSString stringWithFormat:OALocalizedString(@"quick_action_screen_header"), !_editMode ? section : (section + 1)]];
}

- (void)reloadHeaders
{
    for (NSInteger i = 0; i < [self.tableView numberOfSections]; i++)
    {
        UITableViewHeaderFooterView *headerView = [self.tableView headerViewForSection:i];
        if ([headerView isKindOfClass:OAMultiselectableHeaderView.class])
            [self configureHeader:(OAMultiselectableHeaderView *) headerView forSection:i];
    }
}

- (void)updateSwitchSection
{
    if (_editMode)
    {
        [self.tableData removeSection:_switchSection];
        [self.tableData resetChanges];
        [self.tableView performBatchUpdates:^{
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        } completion:^(BOOL finished) {
            [self reloadHeaders];
        }];
    }
    else if (self.tableData.sectionCount > 0 && [self.tableData sectionDataForIndex:0] != _switchSection)
    {
        [self.tableData addSection:_switchSection atIndex:0];
        [self.tableData resetChanges];
        [self.tableView performBatchUpdates:^{
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        } completion:^(BOOL finished) {
            [self reloadHeaders];
        }];
    }
}

- (void)saveChanges
{
    if ([self.tableData hasChanged])
    {
        NSMutableArray<OAQuickAction *> *actions = [NSMutableArray array];
        for (NSInteger section = 0; section < [self.tableData sectionCount]; section++)
        {
            for (NSInteger row = 0; row < [self.tableData rowCount:section]; row++)
            {
                OATableRowData *item = [self.tableData itemForIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                OAQuickAction *action = [item objForKey:@"action"];
                if (action)
                    [actions addObject:action];
            }
        }
        [_registry updateQuickActions:actions];
        [_registry.quickActionListChangedObservable notifyEvent];
    }
}

- (void)showUnsavedChangesAlert:(BOOL)shouldDismiss
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: OALocalizedString(@"unsaved_changes")
                                                                   message: OALocalizedString(@"unsaved_changes_will_be_lost_discard")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_discard")
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        self.editMode = NO;
        if (shouldDismiss)
            [self dismissViewController];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    UIPopoverPresentationController *popPresenter = alert.popoverPresentationController;
    popPresenter.barButtonItem = [self getLeftNavbarButton];
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (_editMode)
    {
        if ([self.tableData hasChanged])
            [self showUnsavedChangesAlert:NO];
        else
            self.editMode = NO;
        return;
    }
    [super onLeftNavbarButtonPressed];
}

- (void)onRightNavbarButtonPressed
{
    if (_editMode)
        [self saveChanges];
    self.editMode = !_editMode;
}

- (void)onTopButtonPressed
{
    if ([self.tableView indexPathsForSelectedRows].count > 0)
    {
        for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows])
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    else
    {
        for (NSInteger section = 0; section < [self.tableData sectionCount]; section++)
        {
            for (NSInteger row = 0; row < [self.tableData rowCount:section]; row++)
            {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                            animated:YES
                                      scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    [self updateBottomButtons];
}

- (void)onBottomButtonPressed
{
    NSArray<NSIndexPath *> *indexes = [self.tableView indexPathsForSelectedRows];

    if (indexes.count > 0)
    {
        NSMutableArray<NSIndexSet *> *sectionsToRemove = [NSMutableArray array];
        for (NSInteger section = 0; section < [self.tableData sectionCount]; section++)
        {
            if ([NSIndexPath getRowsCount:section at:indexes] == [self.tableData rowCount:section])
                [sectionsToRemove addObject:[NSIndexSet indexSetWithIndex:section]];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:
                                    [NSString stringWithFormat:OALocalizedString(@"confirm_bulk_delete"), indexes.count]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self.tableData removeItemsAtIndexPaths:indexes];
            [self.tableView performBatchUpdates:^{
                [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
                if (sectionsToRemove.count > 0)
                {
                    for (NSIndexSet *section in sectionsToRemove)
                    {
                        [self.tableView deleteSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }
            } completion:^(BOOL finished) {
                [self updateBottomButtons];
            }];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onSwitchPressed:(UISwitch *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqual:@"pref"])
    {
        OACommonBoolean *pref = [item objForKey:@"pref"];
        [pref set:sender.isOn];
        [self.delegate onWidgetStateChanged];
    }
}

- (void)addActionPressed
{
    OAAddQuickActionViewController *vc = [[OAAddQuickActionViewController alloc] init];
    vc.delegate = self;
    [self showViewController:vc];
}

#pragma mark - OAMultiselectableHeaderDelegate

- (void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *) sender;
    NSInteger section = headerView.section;
    for (int i = 0; i < [self.tableData rowCount:section]; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        if (value)
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - OAQuickActionListDelegate

- (void)updateData
{
    [self updateUI:YES];
}

@end
