//
//  OAFavoriteGroupEditorViewController.m
//  OsmAnd
//
//  Created by SKalii on 17.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAFavoriteGroupEditorViewController.h"
#import "MBProgressHUD.h"
#import "OAFavoritesHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OASearchMoreCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OAFavoriteGroupEditorViewController
{
    OAFavoriteGroup *_favoriteGroup;
    MBProgressHUD *_progressHUD;
    NSIndexPath *_applyToExistingIndexPath;
    UIColor *_lastAppliedColor;
    NSString *_lastAppliedIconName;
    NSString *_lastAppliedBackgroundIconName;
}

#pragma mark - Initialization

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_progressHUD)
    {
        UIWindow *window = self.navigationController.view.window ?: self.view.window;
        _progressHUD.frame = window.bounds;
        [window addSubview:_progressHUD];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_progressHUD removeFromSuperview];
}

- (void)postInit
{
    [super postInit];
    
    if (self.isNewItem)
    {
        _favoriteGroup = [[OAFavoriteGroup alloc] init];
        _favoriteGroup.name = self.editName;
        _favoriteGroup.color = self.editColor;
        _favoriteGroup.isVisible = YES;
        _favoriteGroup.iconName = self.editIconName;
        _favoriteGroup.backgroundType = self.editBackgroundIconName;
    }
    else
    {
        _favoriteGroup = [OAFavoritesHelper groupByName:self.editName];
    }
}

- (BOOL)shouldBlurAppearanceNavBar
{
    return NO;
}

- (OAFavoriteGroup *)existingGroupFor:(NSString *)name
{
    NSString *groupName = [self targetGroupNameForName:name];
    OAFavoriteGroup *group = [OAFavoritesHelper groupByTrimmedName:groupName];
    if (group || !self.isNewItem)
        return group;

    NSString *languageCode = [OAUtilities currentLang];
    NSLocale *locale = languageCode.length > 0 ? [NSLocale localeWithLocaleIdentifier:languageCode] : NSLocale.currentLocale;
    NSString *lowercaseGroupName = [groupName lowercaseStringWithLocale:locale];
    for (OAFavoriteGroup *favoriteGroup in [OAFavoritesHelper favoriteGroups])
    {
        if ([[[favoriteGroup.name trim] lowercaseStringWithLocale:locale] isEqualToString:lowercaseGroupName]
            || [[OAFavoriteGroup getDisplayName:favoriteGroup.name] isEqualToString:groupName])
            return favoriteGroup;
    }
    return nil;
}

- (BOOL)allowsValidationForGroupName
{
    return !self.isNewItem;
}

#pragma mark - Table data

- (void)generateActionSection
{
    if (self.isNewItem)
        return;

    OATableSectionData *section = [self.tableData createNewSection];
    OATableRowData *row = [section createNewRow];
    row.cellType = OASearchMoreCell.reuseIdentifier;
    row.title = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), OALocalizedString(@"apply_to_existing"), [NSString stringWithFormat:@"(%lu)", (unsigned long)_favoriteGroup.points.count]];
    _applyToExistingIndexPath = [NSIndexPath indexPathForRow:[section rowCount] - 1 inSection:[self.tableData sectionCount] - 1];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *row = [self.tableData itemForIndexPath:indexPath];
    if (![row.cellType isEqualToString:OASearchMoreCell.reuseIdentifier])
        return [super getRow:indexPath];

    OASearchMoreCell *cell = [self.tableView dequeueReusableCellWithIdentifier:OASearchMoreCell.reuseIdentifier];
    if (!cell)
        cell = [[NSBundle mainBundle] loadNibNamed:OASearchMoreCell.reuseIdentifier owner:self options:nil].firstObject;

    cell.textView.text = row.title;
    cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [self updateApplyToExistingCell:cell];
    return cell;
}

- (void)changeSaveButtonAvailabilityWithGroup
{
    [super changeSaveButtonAvailabilityWithGroup];
    if (_applyToExistingIndexPath)
        [self updateApplyToExistingCell:(OASearchMoreCell *)[self.tableView cellForRowAtIndexPath:_applyToExistingIndexPath]];
}

- (void)updateApplyToExistingCell:(OASearchMoreCell *)cell
{
    if (!cell)
        return;

    BOOL enabled = [self isExistingPointsAppearanceChanged] && _favoriteGroup.points.count > 0;
    cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    cell.textView.textColor = [UIColor colorNamed:enabled ? ACColorNameTextColorActive : ACColorNameTextColorSecondary];
}

- (BOOL)isExistingPointsAppearanceChanged
{
    if (!_lastAppliedColor)
        return [self isAppearanceChanged];

    return ![self.editColor isEqual:_lastAppliedColor] || [self isIconNameChanged:_lastAppliedIconName] || ![self.editBackgroundIconName isEqualToString:_lastAppliedBackgroundIconName];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *row = [self.tableData itemForIndexPath:indexPath];
    if (![row.cellType isEqualToString:OASearchMoreCell.reuseIdentifier])
    {
        [super onRowSelected:indexPath];
        return;
    }

    if ([self isExistingPointsAppearanceChanged] && _favoriteGroup.points.count > 0)
        [self editPointsGroup:YES updateGroupValues:NO];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    if (self.isNewItem)
    {
        [self addPointsGroup];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_save")
                                                                       message:OALocalizedString(@"save_favorite_default_appearance")
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"apply_only_to_new_points")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:NO updateGroupValues:YES];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"apply_to_all_points")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:YES updateGroupValues:YES];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        
        UIPopoverPresentationController *popover = alert.popoverPresentationController;
        popover.barButtonItem = self.navigationItem.rightBarButtonItem;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;

        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onLeftNavbarButtonPressed
{
    if (self.isNewItem || ![self isExistingPointsAppearanceChanged])
    {
        [super onLeftNavbarButtonPressed];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"exit_without_saving") message:OALocalizedString(@"unsaved_changes_will_be_lost") preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [super onLeftNavbarButtonPressed];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Additions

- (NSString *)targetGroupNameForName:(NSString *)name
{
    NSString *trimmedName = [(name ?: @"") stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *parentGroupName = self.parentGroupName ?: @"";
    if (parentGroupName.length > 0 && trimmedName.length > 0)
        return [NSString stringWithFormat:@"%@/%@", parentGroupName, trimmedName];
    else if (trimmedName.length > 0)
        return trimmedName;
    else
        return parentGroupName;
}

- (void)addPointsGroup
{
    [self dismissViewController];
    if (self.delegate)
    {
        [self.delegate addNewItemWithName:self.editName
                                 iconName:self.editIconName
                                    color:self.editColor
                       backgroundIconName:self.editBackgroundIconName];
    }
}

- (void)editPointsGroup:(BOOL)updatePoints updateGroupValues:(BOOL)updateGroupValues
{
    [self.view endEditing:YES];

    // Cover the navbar without changing the shared navigation controller's interaction state.
    UIView *containerView = self.view.window ?: self.view;
    _progressHUD = [MBProgressHUD showHUDAddedTo:containerView animated:NO];
    _progressHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _progressHUD.accessibilityViewIsModal = YES;

    if ([self isIconNameChanged:_favoriteGroup.iconName] || (updatePoints && self.editIconName.length == 0) || (updatePoints && _lastAppliedIconName && [self isIconNameChanged:_lastAppliedIconName]))
    {
        [OAFavoritesHelper updateGroup:_favoriteGroup
                              iconName:self.editIconName
                          updatePoints:updatePoints
                       updateGroupIcon:updateGroupValues
                       saveImmediately:NO
                            completion:^{
            [self finishSavingGroup:updatePoints updateGroupValues:updateGroupValues];
        }];
    }
    else
    {
        [self finishSavingGroup:updatePoints updateGroupValues:updateGroupValues];
    }
}

- (void)finishSavingGroup:(BOOL)updatePoints updateGroupValues:(BOOL)updateGroupValues
{
    [self finishEditingPointsGroup:updatePoints updateGroupValues:updateGroupValues];
    if (updatePoints)
    {
        _lastAppliedColor = self.editColor;
        _lastAppliedIconName = [self.editIconName copy];
        _lastAppliedBackgroundIconName = [self.editBackgroundIconName copy];
        [self changeSaveButtonAvailabilityWithGroup];
    }

    [_progressHUD hide:NO];
    _progressHUD = nil;

    if ([self.delegate respondsToSelector:@selector(onEditorUpdated)])
        [self.delegate onEditorUpdated];
    if (self.navigationController.topViewController == self)
    {
        if (updateGroupValues)
            [self dismissViewController];
        else
            [OAUtilities showToast:OALocalizedString(@"settings_applied") details:nil duration:4 verticalOffset:50 inView:self.view];
    }
}

- (void)finishEditingPointsGroup:(BOOL)updatePoints updateGroupValues:(BOOL)updateGroupValues
{
    [[self getPoiIconCollectionHandler] addIconToLastUsed:self.editIconName];

    if (![self.editColor isEqual:_favoriteGroup.color] || (updatePoints && _lastAppliedColor && ![self.editColor isEqual:_lastAppliedColor]))
        [OAFavoritesHelper updateGroup:_favoriteGroup
                                 color:self.editColor
                          updatePoints:updatePoints
                      updateGroupColor:updateGroupValues
                       saveImmediately:NO];

    if (![self.editBackgroundIconName isEqualToString:_favoriteGroup.backgroundType] || (updatePoints && _lastAppliedBackgroundIconName && ![self.editBackgroundIconName isEqualToString:_lastAppliedBackgroundIconName]))
        [OAFavoritesHelper updateGroup:_favoriteGroup
                    backgroundIconName:self.editBackgroundIconName
                          updatePoints:updatePoints
                      updateGroupShape:updateGroupValues
                       saveImmediately:NO];

    [OAFavoritesHelper updateGroup:_favoriteGroup
                           newName:self.editName
                   saveImmediately:NO];

    [OAFavoritesHelper notifyFavoritesStorageChanged];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
}

@end
