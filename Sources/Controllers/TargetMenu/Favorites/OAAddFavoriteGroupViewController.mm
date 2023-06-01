//
//  OAAddFavoriteGroupViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAAddFavoriteGroupViewController.h"
#import "OAColorCollectionViewController.h"
#import "OAInputTableViewCell.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAColorCollectionHandler.h"
#import "OAGPXAppearanceCollection.h"
#import "OADefaultFavorite.h"
#import "OAFavoritesHelper.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define kIllegalFileNameCharacters [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:;.,"]

@interface OAAddFavoriteGroupViewController() <UITextFieldDelegate, UIColorPickerViewControllerDelegate, OAColorsCollectionCellDelegate, OAColorCollectionDelegate, OACollectionTableViewCellDelegate>

@end

@implementation OAAddFavoriteGroupViewController
{
    OATableDataModel *_data;
    NSString *_newGroupName;
    UIBarButtonItem *_doneBarButton;
    OAGPXAppearanceCollection *_appearanceCollection;
    NSArray<OAColorItem *> *_sortedColorItems;
    OAColorItem *_selectedColorItem;
    NSIndexPath *_editColorIndexPath;
    BOOL _isNewColorSelected;
    BOOL _needToScrollToSelectedColor;
    NSIndexPath *_colorIndexPath;
}

#pragma mark - Initialization

- (void)commonInit
{
    _newGroupName = @"";
    _needToScrollToSelectedColor = YES;
    _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];
    _selectedColorItem = [_appearanceCollection getDefaultPointColorItem];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"fav_add_new_group");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    _doneBarButton = [self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                          iconName:nil
                                            action:@selector(onRightNavbarButtonPressed)
                                              menu:nil];
    [self changeButtonAvailability:_doneBarButton isEnabled:NO];
    return @[_doneBarButton];
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *nameSection = [_data createNewSection];
    nameSection.headerText = OALocalizedString(@"favorite_group_name");
    [nameSection addRowFromDictionary:@{
        kCellTypeKey : [OAInputTableViewCell getCellIdentifier],
        kCellTitleKey : @""
    }];

    OATableSectionData *colorSection = [_data createNewSection];
    colorSection.headerText = OALocalizedString(@"access_default_color");
    colorSection.footerText = OALocalizedString(@"default_color_descr");
    [colorSection addRowFromDictionary:@{
        kCellKeyKey : @"colorTitle",
        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_coloring")
    }];
    [colorSection addRowFromDictionary:@{
        kCellKeyKey : @"colorGrid",
        kCellTypeKey : [OACollectionSingleLineTableViewCell getCellIdentifier]
    }];
    _colorIndexPath = [NSIndexPath indexPathForRow:[colorSection rowCount] - 1 inSection:[_data sectionCount] - 1];

    [colorSection addRowFromDictionary:@{
        kCellKeyKey : @"allColors",
        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_all_colors"),
        kCellIconTint : @color_primary_purple
    }];
}

#pragma mark - UITableViewDataSource

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.placeholder = OALocalizedString(@"fav_enter_group_name");
            cell.inputField.textAlignment = NSTextAlignmentNatural;
        }
        if (cell)
        {
            cell.inputField.text = item.title;
            cell.inputField.delegate = self;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACollectionSingleLineTableViewCell getCellIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACollectionSingleLineTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = nib[0];
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_sortedColorItems]];
            colorHandler.delegate = self;
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:_selectedColorItem] inSection:0];
            if (selectedIndexPath.row == NSNotFound)
                selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:[_appearanceCollection getDefaultPointColorItem]] inSection:0];
            [colorHandler setSelectedIndexPath:selectedIndexPath];
            [cell setCollectionHandler:colorHandler];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.rightActionButton.accessibilityLabel = OALocalizedString(@"shared_string_add_color");
            cell.delegate = self;
        }
        if (cell)
        {
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.rightActionButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.rightActionButton addTarget:self action:@selector(onCellButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];

            if (_needToScrollToSelectedColor)
            {
                NSIndexPath *selectedIndexPath = [[cell getCollectionHandler] getSelectedIndexPath];
                if (selectedIndexPath.row != NSNotFound && ![cell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
                {
                    [cell.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                        animated:YES];
                }
                _needToScrollToSelectedColor = NO;
            }
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
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            [cell setCustomLeftSeparatorInset:YES];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);

            NSInteger tintColor = item.iconTint;
            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = tintColor != -1 ? UIColorFromRGB(tintColor) : UIColor.blackColor;
            cell.selectionStyle = tintColor == -1 ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"allColors"])
    {
        OAColorCollectionViewController *colorCollectionViewController =
            [[OAColorCollectionViewController alloc] initWithColorItems:[self generateDataForColorCollection]
                                                      selectedColorItem:_selectedColorItem];
        colorCollectionViewController.delegate = self;
        [self showViewController:colorCollectionViewController];
    }
}

#pragma mark - Additions

- (void)openColorPickerWithColor:(OAColorItem *)colorItem
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [colorItem getColor];
    [self presentViewController:colorViewController animated:YES completion:nil];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    [self dismissViewController];

    if (self.delegate)
        [self.delegate onFavoriteGroupAdded:_newGroupName color:[_selectedColorItem getColor]];
}

- (void)onCellButtonPressed:(UIButton *)sender
{
    [self onRightActionButtonPressed:sender.tag];
}

#pragma mark - OACollectionTableViewCellDelegate

- (void)onRightActionButtonPressed:(NSInteger)tag
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"colorGrid"])
        [self openColorPickerWithColor:_selectedColorItem];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void) textViewDidChange:(UITextView *)textView
{
    BOOL isEnabled = textView.text.length > 0
        && [textView.text rangeOfCharacterFromSet:kIllegalFileNameCharacters].length == 0
        && ![textView.text isEqualToString:OALocalizedString(@"favorites_item")]
        && ![textView.text isEqualToString:OALocalizedString(@"personal_category_name")]
        && ![textView.text isEqualToString:kPersonalCategory]
        && ![OAFavoritesHelper getGroupByName:textView.text];

    if (isEnabled)
        _newGroupName = textView.text;

    [self changeButtonAvailability:_doneBarButton isEnabled:isEnabled];
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;

    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - OAColorCollectionDelegate

- (NSArray<OAColorItem *> *)generateDataForColorCollection
{
    return [_appearanceCollection getAvailableColorsSortingByKey];
}

- (void)onColorCollectionItemSelected:(OAColorItem *)colorItem
{
    _needToScrollToSelectedColor = YES;
    [self onCollectionItemSelected:[NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:@[_colorIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)onColorCollectionNewItemAdded:(UIColor *)color
{
    [_appearanceCollection addNewSelectedColor:color];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];
    if (self.delegate)
        [self.delegate onFavoriteGroupColorsRefresh];
}

- (void)onColorCollectionItemChanged:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    [_appearanceCollection changeColor:colorItem newColor:color];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];
    if (self.delegate)
        [self.delegate onFavoriteGroupColorsRefresh];
}

- (void)onColorCollectionItemDuplicated:(OAColorItem *)colorItem
{
    [_appearanceCollection duplicateColor:colorItem];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];
    if (self.delegate)
        [self.delegate onFavoriteGroupColorsRefresh];
}

- (void)onColorCollectionItemDeleted:(OAColorItem *)colorItem
{
    [_appearanceCollection deleteColor:colorItem];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];
    if (self.delegate)
        [self.delegate onFavoriteGroupColorsRefresh];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _isNewColorSelected = YES;
    _selectedColorItem = _sortedColorItems[indexPath.row];
}

- (void)reloadCollectionData
{
}

#pragma mark - OAColorsCollectionCellDelegate

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:_sortedColorItems[indexPath.row]];
}

- (void)onContextMenuItemDuplicate:(NSIndexPath *)indexPath
{
    [self onColorCollectionItemDuplicated:_sortedColorItems[indexPath.row]];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];

    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [colorHandler addDuplicatedColor:newIndexPath collectionView:colorCell.collectionView];
    [colorHandler updateData:@[_sortedColorItems] collectionView:colorCell.collectionView];
}

- (void)onContextMenuItemDelete:(NSIndexPath *)indexPath
{
    [self onColorCollectionItemDeleted:_sortedColorItems[indexPath.row]];
    _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];

    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    [colorHandler removeColor:indexPath collectionView:colorCell.collectionView];
    [colorHandler updateData:@[_sortedColorItems] collectionView:colorCell.collectionView];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    if (_editColorIndexPath)
    {
        if (![[_sortedColorItems[_editColorIndexPath.row] getHexColor] isEqualToString:[viewController.selectedColor toHexARGBString]])
        {
            [self onColorCollectionItemChanged:_sortedColorItems[_editColorIndexPath.row] withColor:viewController.selectedColor];
            _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];

            [colorHandler updateData:@[_sortedColorItems] collectionView:colorCell.collectionView];
            if (_editColorIndexPath == [colorHandler getSelectedIndexPath])
                [self onCollectionItemSelected:_editColorIndexPath];
        }
        _editColorIndexPath = nil;
    }
    else
    {
        [self onColorCollectionNewItemAdded:viewController.selectedColor];
        _sortedColorItems = [_appearanceCollection getAvailableColorsSortingByLastUsed];

        [colorHandler addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0]
                         collectionView:colorCell.collectionView];
        [colorHandler updateData:@[_sortedColorItems] collectionView:colorCell.collectionView];
    }
}

@end

