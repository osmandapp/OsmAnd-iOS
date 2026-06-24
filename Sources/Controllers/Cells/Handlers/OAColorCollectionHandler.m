//
//  OAColorsCollectionHandler.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorCollectionHandler.h"
#import "OAColorsCollectionViewCell.h"
#import "OAColorsPaletteCell.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OAGPXAppearanceCollection.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kWhiteColor 0x44FFFFFF

static NSString * const kOriginalKey = @"original";
static NSString * const kSolidColorKey = @"solid_color";

@interface OAColorCollectionHandler () <ColorCollectionViewControllerDelegate, OAColorPickerViewControllerDelegate, UIColorPickerViewControllerDelegate>

@property(nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation OAColorCollectionHandler
{
    NSMutableArray<NSMutableArray<OASPaletteItemSolid *> *> *_data;
    NSMutableArray<OAColorsAppearanceCategory *> *_categories;
    NSMutableDictionary<NSString *, OAColorsAppearanceCategory *> *_categoriesByKeyName;
    NSString *_selectedCategoryKey;
    NSIndexPath *_editColorIndexPath;
    BOOL _isStartedNewColorAdding;
    BOOL _isFavoriteList;
}

@synthesize delegate;

- (NSMutableArray<NSMutableArray<OASPaletteItemSolid *> *> *) getData
{
    return _data;
}

#pragma mark - Initialization

- (instancetype)initWithData:(NSArray<NSArray<OASPaletteItemSolid *> *> *)data isFavoriteList:(BOOL)isFavoriteList
{
    self = [super initWithData:data collectionView:nil];
    if (self)
    {
        _categories = [NSMutableArray array];
        _categoriesByKeyName = [NSMutableDictionary dictionary];
        _selectedCategoryKey = @"";
        _isFavoriteList = isFavoriteList;
        [self setup];
    }
    return self;
}

- (void)setup
{
    [self initColorCategories];
    [self selectCategoryWithName:kSolidColorKey];
}

- (void)setupDefaultCategory
{
    if (!_groupColors)
        return;

    BOOL allEqual = YES;
    UIColor *first = _groupColors.firstObject;

    for (UIColor *icon in _groupColors)
    {
        if (![icon isEqual:first])
        {
            allEqual = NO;
            break;
        }
    }

    [self selectCategoryWithName:_isFavoriteList && !allEqual ? kOriginalKey : kSolidColorKey];
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

    UIAction *editAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_edit") image:[[UIImage systemImageNamed:@"pencil"] resizedMenuImage] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf onContextMenuItemEdit:indexPath];
    }];
    editAction.accessibilityLabel = OALocalizedString(@"shared_string_edit_color");
    [menuElements addObject:editAction];

    UIAction *duplicateAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_duplicate") image:[[UIImage systemImageNamed:@"doc.on.doc"] resizedMenuImage] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf duplicateItemFromContextMenu:indexPath];
    }];
    duplicateAction.accessibilityLabel = OALocalizedString(@"shared_string_duplicate_color");
    [menuElements addObject:duplicateAction];

    UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete") image:[[UIImage systemImageNamed:@"trash"] resizedMenuImage] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf deleteItemFromContextMenu:indexPath];
    }];
    deleteAction.accessibilityLabel = OALocalizedString(@"shared_string_delete_color");
    deleteAction.attributes = UIMenuElementAttributesDestructive;

    [menuElements addObject:[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[deleteAction]]];
    return [UIMenu menuWithChildren:menuElements];
}

- (UIMenu *)buildTopButtonContextMenu
{
    NSMutableArray<UIMenuElement *> *topMenuElements = [NSMutableArray array];
    NSMutableArray<UIMenuElement *> *bottomMenuElements = [NSMutableArray array];

    for (OAColorsAppearanceCategory *category in _categories)
        [self updateMenuElements: [category.key isEqualToString:kOriginalKey] ? topMenuElements : bottomMenuElements withCategory:category];

    UIMenu *topMenu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:topMenuElements];
    UIMenu *bottomMenu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:bottomMenuElements];

    return [UIMenu menuWithTitle:@"" children:@[topMenu, bottomMenu]];
}

- (void)updateMenuElements:(NSMutableArray<UIMenuElement *> *)menuElements
              withCategory:(OAColorsAppearanceCategory *)category
{
    UIAction *action = [UIAction actionWithTitle:category.translatedName
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        [self onMenuItemSelectedWithName:category.key];
    }];

    [menuElements addObject:action];
}

- (void)onMenuItemSelectedWithName:(NSString *)name
{
    OAColorsAppearanceCategory *category = _categoriesByKeyName[name];
    if (category)
    {
        [self selectCategoryWithName:name];
    }
}

- (void)selectCategoryWithName:(NSString *)categoryKey
{
    _selectedCategoryKey = categoryKey;

    OAColorsAppearanceCategory *category = _categoriesByKeyName[categoryKey];
    if (category)
    {
        [self updateHostCellIfNeeded];

        if (self.hostCell)
            [self.handlerDelegate onCategorySelectedWith:self.hostCell];
    }
}

- (void)updateHostCellIfNeeded
{
    [self updateTopButtonName];
    [self updateHostCellIfOriginalCategory:[_selectedCategoryKey isEqualToString:kOriginalKey]];
}

- (void)updateTopButtonName
{
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold];

    OAColorsAppearanceCategory *category = _categoriesByKeyName[_selectedCategoryKey];
    if (category)
    {
        UIImage *iconImage = [UIImage systemImageNamed:@"chevron.up.chevron.down" withConfiguration:config];
        if (iconImage)
        {
            iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = iconImage;

            NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attachment];

            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", category.translatedName]];
            [attributedString appendAttributedString:imageString];

            OAColorsPaletteCell *cell = (OAColorsPaletteCell *)self.hostCell;
            [cell.topButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        }
    }
}

- (void)updateHostCellIfOriginalCategory:(BOOL)isOriginal
{
    OAColorsPaletteCell *cell = (OAColorsPaletteCell *)self.hostCell;
    [self.hostCell collectionStackViewVisibility:!isOriginal];
    cell.descriptionLabelStackView.hidden = !isOriginal;
    cell.bottomButtonStackView.hidden = isOriginal;
    cell.separatorOffsetViewWidth.constant = isOriginal ? 20 : 0;
}

#pragma mark - Data

- (void)initColorCategories
{
    [self initOriginalCategory];
    [self initSolidColorCategory];

    for (OAColorsAppearanceCategory *category in _categories)
        _categoriesByKeyName[category.key] = category;
}

- (void)initOriginalCategory
{
    OAColorsAppearanceCategory *category = [[OAColorsAppearanceCategory alloc] initWithKey:kOriginalKey translatedName:OALocalizedString(@"shared_string_original")];
    [_categories addObject:category];
}

- (void)initSolidColorCategory
{
    OAColorsAppearanceCategory *category = [[OAColorsAppearanceCategory alloc] initWithKey:kSolidColorKey translatedName:OALocalizedString(@"track_coloring_solid")];
    [_categories addObject:category];
}

- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OASPaletteItemSolid *)newItem
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    [self setSelectedIndexPath:indexPath];
    [self insertItem:newItem atIndexPath:self.selectedIndexPath];
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
        [weakSelf.delegate onCollectionItemSelected:weakSelf.selectedIndexPath selectedItem:newItem collectionView:collectionView shouldDismiss:NO];
        if (weakSelf.hostCell && [weakSelf.hostCell needUpdateHeight])
            [weakSelf.delegate reloadCollectionData];
    } completion:^(BOOL finished) {
        [weakSelf updateVisibleSelectionState];
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

- (void)addColor:(NSIndexPath *)indexPath newItem:(OASPaletteItemSolid *)newItem
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    [self insertItem:newItem atIndexPath:indexPath];
    __weak __typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];

        if (weakSelf.selectedIndexPath && indexPath.row <= weakSelf.selectedIndexPath.row)
        {
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

    NSIndexPath *previousSelectedIndexPath = [self.selectedIndexPath copy];
    [self removeItem:indexPath];
    if ([indexPath isEqual:self.selectedIndexPath])
        [self setSelectedIndexPath:[self itemsCount:indexPath.section] > 0 ? [NSIndexPath indexPathForRow:0 inSection:indexPath.section] : nil];
    else if (self.selectedIndexPath && indexPath.row < self.selectedIndexPath.row)
        [self setSelectedIndexPath:[NSIndexPath indexPathForRow:self.selectedIndexPath.row - 1 inSection:self.selectedIndexPath.section]];

    __weak __typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        if ([indexPath isEqual:previousSelectedIndexPath] && weakSelf.selectedIndexPath)
            [collectionView reloadItemsAtIndexPaths:@[weakSelf.selectedIndexPath]];
        [weakSelf updateVisibleSelectionState];
        if ([indexPath isEqual:weakSelf.selectedIndexPath])
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

- (OASPaletteItemSolid *)getSelectedItem
{
    if (!_selectedIndexPath || _selectedIndexPath.section < 0 || _selectedIndexPath.row < 0 || _data.count <= _selectedIndexPath.section || _data[_selectedIndexPath.section].count <= _selectedIndexPath.row)
        return nil;

    return _data[_selectedIndexPath.section][_selectedIndexPath.row];
}

- (void)setSelectionItem:(OASPaletteItemSolid *)item
{
    NSIndexPath *indexPath = [self indexForColorItem:item];
    if (indexPath)
        _selectedIndexPath = indexPath;
}

- (BOOL)isColorItemSelected:(OASPaletteItemSolid *)item
{
    return [[OAGPXAppearanceCollection sharedInstance] isSameColorItem:[self getSelectedItem] secondItem:item];
}

- (void)generateData:(NSArray<NSArray<OASPaletteItemSolid *> *> *)data
{
    NSMutableArray<NSMutableArray<OASPaletteItemSolid *> *> *newData = [NSMutableArray array];
    for (NSArray *items in data)
    {
        [newData addObject:[NSMutableArray arrayWithArray:items]];
    }
    _data = newData;
}

- (void)insertItem:(OASPaletteItemSolid *)newItem atIndexPath:(NSIndexPath *)indexPath
{
    if (_data.count > indexPath.section && (indexPath.row == 0 || _data[indexPath.section].count > indexPath.row - 1))
        [_data[indexPath.section] insertObject:newItem atIndex:indexPath.row];
}

- (void)replaceItem:(OASPaletteItemSolid *)newItem atIndexPath:(NSIndexPath *)indexPath
{
    if (!newItem || _data.count <= indexPath.section || _data[indexPath.section].count <= indexPath.row)
        return;

    _data[indexPath.section][indexPath.row] = newItem;
    UICollectionView *collectionView = [self getCollectionView];
    if (collectionView)
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
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

- (void)updateVisibleSelectionState
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;
    
    for (NSIndexPath *indexPath in collectionView.indexPathsForVisibleItems)
    {
        if (_data.count <= indexPath.section || _data[indexPath.section].count <= indexPath.row)
            continue;
        
        OAColorsCollectionViewCell *cell = (OAColorsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if (![cell isKindOfClass:OAColorsCollectionViewCell.class])
            continue;
        
        BOOL isSelected = [self isColorItemSelected:_data[indexPath.section][indexPath.row]];
        cell.selectionView.layer.borderWidth = isSelected ? 2 : 0;
        cell.selectionView.layer.borderColor = isSelected ? [UIColor colorNamed:ACColorNameIconColorActive].CGColor : UIColor.clearColor.CGColor;
    }
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath
{
    OAColorsCollectionViewCell *cell = [[self getCollectionView] dequeueReusableCellWithReuseIdentifier:[self getCellIdentifier] forIndexPath:indexPath];
    NSInteger colorValue = _data[indexPath.section][indexPath.row].colorInt;
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

    if ([self isColorItemSelected:_data[indexPath.section][indexPath.row]])
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

- (void)openColorPickerWithColor:(OASPaletteItemSolid *)colorItem sourceView:(UIView *)sourceView newColorAdding:(BOOL)newColorAdding
{
    if (_hostVC)
    {
        _isStartedNewColorAdding = newColorAdding;
        OAColorPickerViewController *colorViewController = [[OAColorPickerViewController alloc] init];
        colorViewController.delegate = self;
        colorViewController.closingDelegete = self;
        colorViewController.selectedColor = UIColorFromARGB(colorItem.colorInt);
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
        [_hostVC showMediumToLargeSheetViewController:colorCollectionViewController];
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
        OASPaletteItemSolid *editingColor = _data[0][0];
        if (_editColorIndexPath)
            editingColor = _data[0][_editColorIndexPath.row];

        int32_t selectedColor = (int32_t) viewController.selectedColor.toARGBNumber;
        if (editingColor.colorInt != selectedColor)
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

- (void)selectColorItem:(OASPaletteItemSolid *)colorItem
{
    NSIndexPath *prevSelectedColorIndex = [self getSelectedIndexPath];
    NSIndexPath *selectedIndex = [self indexForColorItem:colorItem];
    if (!selectedIndex)
        return;

    [self setSelectedIndexPath:selectedIndex];
    NSArray<NSIndexPath *> *indexPaths = prevSelectedColorIndex ? @[prevSelectedColorIndex, selectedIndex] : @[selectedIndex];
    [[self getCollectionView] reloadItemsAtIndexPaths:indexPaths];
    [self scrollToIndexPathIfNeeded:selectedIndex];

    if (self.delegate)
    {
        [self.delegate onCollectionItemSelected:selectedIndex selectedItem:nil collectionView:[self getCollectionView] shouldDismiss:YES];
    }
}

- (OASPaletteItemSolid *)addAndGetNewColorItem:(UIColor *)color
{
    OASPaletteItemSolid *newItem = [[OAGPXAppearanceCollection sharedInstance] addNewSelectedColor:color];
    if (!newItem)
        return nil;

    [self addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0] newItem:newItem];
    return newItem;
}

- (void)changeColorItem:(OASPaletteItemSolid *)colorItem withColor:(UIColor *)color
{
    NSIndexPath *indexPath = [self indexForColorItem:colorItem];
    if (!indexPath || !color)
        return;

    OASPaletteItemSolid *newItem;
    if (_isOpenedFromAllColorsScreen && _hostColorHandler)
    {
        [_hostColorHandler changeColorItem:colorItem withColor:color];
        newItem = [[OASPaletteUtils shared] updateSolidColorOriginalItem:colorItem newColorInt:(int32_t)[color toARGBNumber]];
    }
    else if (!_isOpenedFromAllColorsScreen && [self.delegate respondsToSelector:@selector(changeColorItem:withColor:)])
    {
        [(id<ColorCollectionViewControllerDelegate>)self.delegate changeColorItem:colorItem withColor:color];
        newItem = [[OASPaletteUtils shared] updateSolidColorOriginalItem:colorItem newColorInt:(int32_t)[color toARGBNumber]];
    }
    else
    {
        newItem = [[OAGPXAppearanceCollection sharedInstance] changeColor:colorItem newColor:color];
    }
    if (!newItem)
        return;

    BOOL shouldNotifySelection = [indexPath isEqual:_selectedIndexPath] && _data[indexPath.section][indexPath.row].colorInt != newItem.colorInt;
    _data[indexPath.section][indexPath.row] = newItem;
    UICollectionView *collectionView = [self getCollectionView];
    if (collectionView)
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    if (self.delegate && shouldNotifySelection)
        [self.delegate onCollectionItemSelected:indexPath selectedItem:newItem collectionView:collectionView shouldDismiss:NO];
}

- (OASPaletteItemSolid *)duplicateColorItem:(OASPaletteItemSolid *)colorItem
{
    NSIndexPath *indexPath = [self indexForColorItem:colorItem];
    if (!indexPath)
        return colorItem;

    if (_isOpenedFromAllColorsScreen && _hostColorHandler)
    {
        OASPaletteItemSolid *duplicatedColorItem = [_hostColorHandler duplicateColorItem:colorItem];
        if (!duplicatedColorItem || [duplicatedColorItem.id isEqualToString:colorItem.id])
            return colorItem;

        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        [self addColor:newIndexPath newItem:duplicatedColorItem];

        if (_hostCell && [_hostCell needUpdateHeight])
            [self.delegate reloadCollectionData];

        return duplicatedColorItem;
    }

    if (!_isOpenedFromAllColorsScreen && [self.delegate respondsToSelector:@selector(duplicateColorItem:)])
    {
        OASPaletteItemSolid *duplicatedColorItem = [(id<ColorCollectionViewControllerDelegate>)self.delegate duplicateColorItem:colorItem];
        if (!duplicatedColorItem || [duplicatedColorItem.id isEqualToString:colorItem.id])
            return colorItem;

        if (![self indexForColorItem:duplicatedColorItem])
            [self addColor:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section] newItem:duplicatedColorItem];

        return duplicatedColorItem;
    }

    OASPaletteItemSolid *duplicatedColorItem = [[OAGPXAppearanceCollection sharedInstance] duplicateColor:colorItem];
    if (!duplicatedColorItem)
        return colorItem;

    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [self addColor:newIndexPath newItem:duplicatedColorItem];
    return duplicatedColorItem;
}

- (void)deleteColorItem:(OASPaletteItemSolid *)colorItem
{
    if (!_isOpenedFromAllColorsScreen && [self.delegate respondsToSelector:@selector(deleteColorItem:)])
    {
        [(id<ColorCollectionViewControllerDelegate>)self.delegate deleteColorItem:colorItem];
        return;
    }

    NSIndexPath *indexPath = [self indexForColorItem:colorItem];
    if (!indexPath)
        return;

    BOOL isSelectedColorDeleted = [[OAGPXAppearanceCollection sharedInstance] isSameColorItem:[self getSelectedItem] secondItem:colorItem];
    if (isSelectedColorDeleted)
        [self setSelectedIndexPath:nil];

    [self removeColor:indexPath];
    if (_isOpenedFromAllColorsScreen && _hostColorHandler)
    {
        [_hostColorHandler deleteColorItem:colorItem];
    }
    if (!_isOpenedFromAllColorsScreen)
        [[OAGPXAppearanceCollection sharedInstance] deleteColor:colorItem];
}

- (NSIndexPath *)indexForColorItem:(OASPaletteItemSolid *)colorItem
{
    for (NSInteger section = 0; section < _data.count; section++)
    {
        NSArray<OASPaletteItemSolid *> *items = _data[section];
        for (NSInteger row = 0; row < items.count; row++)
        {
            if ([items[row].id isEqualToString:colorItem.id])
                return [NSIndexPath indexPathForRow:row inSection:section];
        }
    }

    return nil;
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
