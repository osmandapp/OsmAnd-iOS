//
//  OAColorsCollectionHandler.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorCollectionHandler.h"
#import "OAColorsCollectionViewCell.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAGPXAppearanceCollection.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kWhiteColor 0x44FFFFFF
@interface OAColorCollectionHandler () <ColorCollectionViewControllerDelegate, OACollectionCellDelegate, OAColorPickerViewControllerDelegate, UIColorPickerViewControllerDelegate>

@property(nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation OAColorCollectionHandler
{
    NSMutableArray<NSMutableArray<OAColorItem *> *> *_data;
    NSIndexPath *_editColorIndexPath;
    BOOL _isStartedNewColorAdding;
}

@synthesize delegate;

- (NSMutableArray<NSMutableArray<OAColorItem *> *> *) getData
{
    return _data;
}

#pragma mark - Base UI

- (NSString *)getCellIdentifier
{
    return OAColorsCollectionViewCell.reuseIdentifier;
}

- (UIMenu *)getMenuForItem:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    BOOL isDefaultColor = _data[indexPath.section][indexPath.row].isDefault;
    if (self.delegate && !isDefaultColor)
    {
        UIAction *editAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_edit")
                                                   image:[UIImage systemImageNamed:@"pencil"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf onContextMenuItemEdit:indexPath];
        }];
        editAction.accessibilityLabel = OALocalizedString(@"shared_string_edit_color");
        [menuElements addObject:editAction];
    }

    UIAction *duplicateAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_duplicate")
                                                    image:[UIImage systemImageNamed:@"doc.on.doc"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf duplicateItemFromContextMenu:indexPath];
    }];
    duplicateAction.accessibilityLabel = OALocalizedString(@"shared_string_duplicate_color");
    [menuElements addObject:duplicateAction];

    if (!isDefaultColor)
    {
        UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf deleteItemFromContextMenu:indexPath];
        }];
        deleteAction.accessibilityLabel = OALocalizedString(@"shared_string_delete_color");
        deleteAction.attributes = UIMenuElementAttributesDestructive;
        [menuElements addObject:[UIMenu menuWithTitle:@""
                                           image:nil
                                      identifier:nil
                                         options:UIMenuOptionsDisplayInline
                                        children:@[deleteAction]]];
    }

    return isDefaultColor ? [UIMenu menuWithTitle:OALocalizedString(@"access_default_color") children:menuElements] : [UIMenu menuWithChildren:menuElements];
}

#pragma mark - Data

- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    NSIndexPath *prevSelectedIndexPath = _selectedIndexPath;
    [self setSelectedIndexPath:indexPath];
    [collectionView performBatchUpdates:^{
        [weakSelf insertItem:newItem atIndexPath:weakSelf.selectedIndexPath];
        [collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:_data.count - 1 inSection:0]]];

        [collectionView reloadItemsAtIndexPaths:@[prevSelectedIndexPath, weakSelf.selectedIndexPath]];
        
        [weakSelf.delegate onCollectionItemSelected:weakSelf.selectedIndexPath selectedItem:newItem collectionView:collectionView shouldDismiss:NO];
        
        if (weakSelf.hostCell && [weakSelf.hostCell needUpdateHeight])
            [weakSelf.delegate reloadCollectionData];
    } completion:^(BOOL finished) {
        [weakSelf scrollToIndexPathIfNeeded:weakSelf.selectedIndexPath];
    }];
}

- (void) scrollToIndexPathIfNeeded:(NSIndexPath *)indexPath
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;
    
    NSInteger rowsCount = [collectionView numberOfItemsInSection:indexPath.section];
    if (![collectionView.indexPathsForVisibleItems containsObject:indexPath] && indexPath.row < (rowsCount - 1))
    {
        [collectionView scrollToItemAtIndexPath:indexPath
                               atScrollPosition:[self getScrollDirection] == UICollectionViewScrollDirectionHorizontal
                                                    ? UICollectionViewScrollPositionCenteredHorizontally
                                                    : UICollectionViewScrollPositionCenteredVertically
                                       animated:YES];
    }
}

- (void)replaceOldColor:(NSIndexPath *)indexPath
{
    UICollectionView *collectionView = [self getCollectionView];
    if (collectionView)
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];

    if (self.delegate)
    {
        if (indexPath == _selectedIndexPath)
            [self.delegate onCollectionItemSelected:indexPath selectedItem:nil collectionView:collectionView shouldDismiss:YES];
        else
            [self.delegate reloadCollectionData];
    }
    if (_isOpenedFromAllColorsScreen && _hostColorHandler && _hostColorHandler.delegate)
    {
        [_hostColorHandler.delegate reloadCollectionData];
    }
}

- (void)addColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
        [weakSelf insertItem:newItem atIndexPath:indexPath];
        
        if (indexPath.row <= weakSelf.selectedIndexPath.row) {
            NSIndexPath *insertedIndex = indexPath;
            NSIndexPath *updatedPrevSelectedIndex = [NSIndexPath indexPathForRow:weakSelf.selectedIndexPath.row + 1 inSection:weakSelf.selectedIndexPath.section];
            [weakSelf setSelectedIndexPath:updatedPrevSelectedIndex];
            [collectionView reloadItemsAtIndexPaths:@[insertedIndex, updatedPrevSelectedIndex]];
        }
    } completion:^(BOOL finished) {
        [weakSelf scrollToIndexPathIfNeeded:indexPath];
    }];
}

- (void)removeColor:(NSIndexPath *)indexPath
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
        [weakSelf removeItem:indexPath];
        if (indexPath == weakSelf.selectedIndexPath)
        {
            [weakSelf setSelectedIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [collectionView reloadItemsAtIndexPaths:@[weakSelf.selectedIndexPath]];
        }
        else if (indexPath.row < weakSelf.selectedIndexPath.row)
        {
            [weakSelf setSelectedIndexPath:[NSIndexPath indexPathForRow:weakSelf.selectedIndexPath.row - 1 inSection:weakSelf.selectedIndexPath.section]];
        }
    } completion:^(BOOL finished) {
        if (indexPath == weakSelf.selectedIndexPath)
            [weakSelf scrollToIndexPathIfNeeded:weakSelf.selectedIndexPath];
    }];
}

- (NSIndexPath *)getSelectedIndexPath
{
    return _selectedIndexPath;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    _selectedIndexPath = selectedIndexPath;
}

- (OAColorItem *)getSelectedItem
{
    return _data[_selectedIndexPath.section][_selectedIndexPath.row];
}

- (void)setSelectionItem:(OAColorItem *)item
{
    for (int i = 0; i < _data.count; i++)
    {
        NSArray<OAColorItem *> *section = _data[i];
        for (int j = 0; j < section.count; j++)
        {
            if (item == section[j])
            {
                _selectedIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
                return;
            }
        }
    }
}

- (void)generateData:(NSArray<NSArray<OAColorItem *> *> *)data
{
    NSMutableArray<NSMutableArray<OAColorItem *> *> *newData = [NSMutableArray array];
    for (NSArray *items in data)
    {
        [newData addObject:[NSMutableArray arrayWithArray:items]];
    }
    _data = newData;
}

- (void)insertItem:(id)newItem atIndexPath:(NSIndexPath *)indexPath
{
    if (_data.count > indexPath.section && (indexPath.row == 0 || _data[indexPath.section].count > indexPath.row - 1))
        [_data[indexPath.section] insertObject:newItem atIndex:indexPath.row];
}

- (void)removeItem:(NSIndexPath *)indexPath
{
    if (_data.count > indexPath.section && _data[indexPath.section].count > indexPath.row)
        [_data[indexPath.section] removeObjectAtIndex:indexPath.row];
}

- (NSInteger)itemsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath
{
    OAColorsCollectionViewCell *cell = [[self getCollectionView] dequeueReusableCellWithReuseIdentifier:[self getCellIdentifier] forIndexPath:indexPath];
    NSInteger colorValue = _data[indexPath.section][indexPath.row].value;
    if (colorValue == kWhiteColor)
    {
        cell.colorView.layer.borderWidth = 1;
        cell.colorView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    }
    else
    {
        cell.colorView.layer.borderWidth = 0;
    }

    UIColor *color = UIColorFromARGB(colorValue);
    cell.colorView.backgroundColor = color;
    cell.backgroundImageView.image = [UIImage templateImageNamed:@"bg_color_chessboard_pattern"];
    cell.backgroundImageView.tintColor = UIColorFromRGB(colorValue);

    if (indexPath == _selectedIndexPath)
    {
        cell.selectionView.layer.borderWidth = 2;
        cell.selectionView.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
    }
    else
    {
        cell.selectionView.layer.borderWidth = 0;
        cell.selectionView.layer.borderColor = UIColor.clearColor.CGColor;
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)openColorPickerWithColor:(OAColorItem *)colorItem sourceView:(UIView *)sourceView newColorAdding:(BOOL)newColorAdding
{
    if (_hostVC)
    {
        _isStartedNewColorAdding = newColorAdding;
        OAColorPickerViewController *colorViewController = [[OAColorPickerViewController alloc] init];
        colorViewController.delegate = self;
        colorViewController.closingDelegete = self;
        colorViewController.selectedColor = [colorItem getColor];
        if (sourceView)
        {
            colorViewController.modalPresentationStyle = UIModalPresentationPopover;
            colorViewController.popoverPresentationController.sourceView = sourceView;
        }
        else if (_hostVCOpenColorPickerButton)
        {
            colorViewController.modalPresentationStyle = UIModalPresentationPopover;
            colorViewController.popoverPresentationController.sourceView = _hostVCOpenColorPickerButton;
        }
        [_hostVC presentViewController:colorViewController animated:YES completion:nil];
    }
}

- (void)openAllColorsScreen
{
    if (_hostVC)
    {
        ItemsCollectionViewController *colorCollectionViewController =
        [[ItemsCollectionViewController alloc] initWithCollectionType:ColorCollectionTypeColorItems items:_data[0] selectedItem:[self getSelectedItem]];
        colorCollectionViewController.delegate = self;
        colorCollectionViewController.hostColorHandler = self;
        [_hostVC showModalViewController:colorCollectionViewController];
    }
}

- (void)onItemSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    [super onItemSelected:indexPath collectionView:collectionView];
    if (_isOpenedFromAllColorsScreen && _hostColorHandler)
    {
        [_hostColorHandler onItemSelected:indexPath collectionView:[_hostColorHandler getCollectionView]];
    }
}

#pragma mark UIColorPickerViewControllerDelegate

- (void)colorPickerViewController:(UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(BOOL)continuously
{
    if (_isStartedNewColorAdding)
    {
        _isStartedNewColorAdding = NO;
        [self addAndGetNewColorItem:viewController.selectedColor];
    }
    else
    {
        OAColorItem *editingColor = _data[0][0];
        if (_editColorIndexPath)
            editingColor = _data[0][_editColorIndexPath.row];
        
        if (![[editingColor getHexColor] isEqualToString:[viewController.selectedColor toHexARGBString]])
        {
            [self changeColorItem:editingColor withColor:viewController.selectedColor];
        }
    }
}

#pragma mark - OAColorPickerViewControllerDelegate

- (void)onColorPickerDisappear:(OAColorPickerViewController *)colorPicker
{
    _isStartedNewColorAdding = NO;
    _editColorIndexPath = nil;
}

#pragma mark - OAColorCollectionDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath {
    if (self.delegate)
        [self.delegate onCollectionItemSelected:indexPath selectedItem:nil collectionView:[self getCollectionView] shouldDismiss:YES];
}

- (void)selectColorItem:(OAColorItem *)colorItem
{
    NSIndexPath *prevSelectedColorIndex = [self getSelectedIndexPath];
    NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:[_data[0] indexOfObject:colorItem] inSection:0];
    [self setSelectedIndexPath:selectedIndex];
    [[self getCollectionView] reloadItemsAtIndexPaths:@[prevSelectedColorIndex, selectedIndex]];
    [self scrollToIndexPathIfNeeded:selectedIndex];
    
    if (self.delegate)
    {
        [self.delegate onCollectionItemSelected:selectedIndex selectedItem:nil collectionView:[self getCollectionView] shouldDismiss:YES];
    }
}

- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color
{
    OAColorItem *newColorItem = [[OAGPXAppearanceCollection sharedInstance] addNewSelectedColor:color];
    [self addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0] newItem:newColorItem];
    return newColorItem;
}

- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    NSIndexPath *indexPath = [self indexForColorItem:colorItem];
    [[OAGPXAppearanceCollection sharedInstance] changeColor:colorItem newColor:color];
    [self replaceOldColor:indexPath];
}

- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem
{
    NSIndexPath *indexPath = [self indexForColorItem:colorItem];
    OAColorItem *duplicatedColorItem = [[OAGPXAppearanceCollection sharedInstance] duplicateColor:colorItem];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [self addColor:newIndexPath newItem:duplicatedColorItem];
    if (_isOpenedFromAllColorsScreen && _hostColorHandler)
    {
        [_hostColorHandler addColor:newIndexPath newItem:duplicatedColorItem];
        if (_hostColorHandler.delegate)
            [_hostColorHandler.delegate reloadCollectionData];
    } else if (self.delegate) {
        [self.delegate reloadCollectionData];
    }
    return duplicatedColorItem;
}

- (void)deleteColorItem:(OAColorItem *)colorItem
{
    NSIndexPath *indexPath = [self indexForColorItem:colorItem];
    [self removeColor:indexPath];
    if (_isOpenedFromAllColorsScreen && _hostColorHandler)
    {
        [_hostColorHandler deleteColorItem:colorItem];
        if (_hostColorHandler.delegate)
            [_hostColorHandler.delegate reloadCollectionData];
    } else if (self.delegate) {
        [self.delegate reloadCollectionData];
    }
    if (!_isOpenedFromAllColorsScreen)
        [[OAGPXAppearanceCollection sharedInstance] deleteColor:colorItem];
}

- (NSIndexPath *)indexForColorItem:(OAColorItem *)colorItem
{
    return [NSIndexPath indexPathForRow:[_data[0] indexOfObject:colorItem] inSection:0];
}

#pragma mark - OAColorsCollectionCellDelegate

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    UICollectionViewCell *editingCell = [[self getCollectionView] cellForItemAtIndexPath:indexPath];
    [self openColorPickerWithColor:_data[0][indexPath.row] sourceView:editingCell newColorAdding:NO];
}

- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath
{
    [self duplicateColorItem:_data[0][indexPath.row]];
}

- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath
{
    [self deleteColorItem:_data[0][indexPath.row]];
}

@end
