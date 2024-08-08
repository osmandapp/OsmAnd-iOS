//
//  OAColorCollectionViewController.m
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorCollectionViewController.h"
#import "OARootViewController.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAColorCollectionHandler.h"
#import "OAGPXAppearanceCollection.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAColorCollectionViewController () <UIColorPickerViewControllerDelegate, OAColorsCollectionCellDelegate>

@end

@implementation OAColorCollectionViewController
{
    OAAppSettings *_settings;
    OATableDataModel *_data;
    NSIndexPath *_colorCollectionIndexPath;
    NSMutableArray<OAColorItem *> *_colorItems;
    NSMutableArray<PaletteColor *> *_paletteItems;
    OAColorItem *_selectedColorItem;
    PaletteColor *_selectedPaletteItem;
    NSIndexPath *_editColorIndexPath;
}

#pragma mark - Initialization

- (instancetype)initWithCollectionType:(EOAColorCollectionType)type items:(NSArray *)items selectedItem:(id)selectedItem
{
    self = [super init];
    if (self)
    {
        _collectionType = type;
        switch (type)
        {
            case EOAColorCollectionTypeColorItems:
                _colorItems = [NSMutableArray arrayWithArray:items];
                _selectedColorItem = selectedItem;
                break;
            case EOAColorCollectionTypePaletteItems:
                _paletteItems = [NSMutableArray arrayWithArray:items];
                _selectedPaletteItem = selectedItem;
                break;
        }
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)registerCells
{
    switch (_collectionType)
    {
        case EOAColorCollectionTypeColorItems:
        {
            [self.tableView registerNib:[UINib nibWithNibName:[OACollectionSingleLineTableViewCell reuseIdentifier] bundle:nil]
                 forCellReuseIdentifier:[OACollectionSingleLineTableViewCell reuseIdentifier]];
        }
        case EOAColorCollectionTypePaletteItems:
        {
            [self.tableView registerNib:[UINib nibWithNibName:[OATwoIconsButtonTableViewCell reuseIdentifier] bundle:nil]
                 forCellReuseIdentifier:[OATwoIconsButtonTableViewCell reuseIdentifier]];
        }
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = _collectionType == EOAColorCollectionTypePaletteItems ? UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorNamed:_collectionType == EOAColorCollectionTypeColorItems ? ACColorNameGroupBg : ACColorNameViewBg];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_all_colors");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    if (_collectionType == EOAColorCollectionTypeColorItems)
    {
        UIBarButtonItem *addButton = [self createRightNavbarButton:nil iconName:@"ic_custom_add" action:@selector(onRightNavbarButtonPressed) menu:nil];
        addButton.accessibilityLabel = OALocalizedString(@"shared_string_add_color");
        return @[addButton];
    }
    
    return  nil;
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return _collectionType == EOAColorCollectionTypeColorItems ? EOABaseNavbarColorSchemeWhite : EOABaseNavbarColorSchemeGray;
}

- (BOOL)hideFirstHeader
{
    return  _collectionType == EOAColorCollectionTypeColorItems ? YES : NO;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    if (_collectionType == EOAColorCollectionTypeColorItems)
    {
        OATableSectionData *colorsSection = [_data createNewSection];
        [colorsSection addRowFromDictionary:@{
            kCellTypeKey: [OACollectionSingleLineTableViewCell getCellIdentifier]
        }];
        _colorCollectionIndexPath = [NSIndexPath indexPathForRow:[colorsSection rowCount] - 1 inSection:[_data sectionCount] - 1];
    }
    else
    {
        OATableSectionData *palettesSection = [_data createNewSection];
        for (PaletteColor *palette in _paletteItems)
        {
            OATableRowData *paletteColor = [palettesSection createNewRow];
            [paletteColor setCellType:[OATwoIconsButtonTableViewCell reuseIdentifier]];
            [paletteColor setKey:@"paletteColor"];
            [paletteColor setTitle:palette.toHumanString];
            [paletteColor setIconName:palette == _selectedPaletteItem ? @"ic_checkmark_default" : nil];
            [paletteColor setObj:palette forKey:@"palette"];
        }
    }
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OACollectionSingleLineTableViewCell getCellIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell reuseIdentifier]];
        OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_colorItems] collectionView:cell.collectionView];
        colorHandler.delegate = self;
        [colorHandler setScrollDirection:UICollectionViewScrollDirectionVertical];
        [colorHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:[_colorItems indexOfObject:_selectedColorItem] inSection:0]];
        [cell setCollectionHandler:colorHandler];
        [cell rightActionButtonVisibility:NO];
        [cell anchorContent:EOATableViewCellContentCenterStyle];
        cell.collectionView.scrollEnabled = NO;
        [cell.collectionView reloadData];
        [cell layoutIfNeeded];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OATwoIconsButtonTableViewCell reuseIdentifier]])
    {
        OATwoIconsButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATwoIconsButtonTableViewCell reuseIdentifier]];
        PaletteCollectionHandler *paletteHandler = [[PaletteCollectionHandler alloc] init];
        PaletteColor *palette = [item objForKey:@"palette"];
        cell.titleLabel.text = item.title;
        cell.descriptionLabel.text = [paletteHandler createDescriptionForPaletteWithPalette:palette];
        cell.leftIconView.image = [UIImage imageNamed:item.iconName];
        [paletteHandler applyGradientTo:cell.secondLeftIconView with:palette];
        cell.secondLeftIconView.layer.cornerRadius = 3;
        [cell.button setTitle:nil forState:UIControlStateNormal];
        [cell.button setImage:[UIImage templateImageNamed:@"ic_navbar_overflow_menu_outlined"] forState:UIControlStateNormal];
        cell.button.menu = [self createPaletteMenuForCellButton:indexPath];
        cell.button.showsMenuAsPrimaryAction = YES;
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"paletteColor"])
    {
        _selectedPaletteItem = [item objForKey:@"palette"];
        if (self.delegate)
            [self.delegate selectPaletteItem:_selectedPaletteItem];
        
        [self dismissViewController];
    }
}

#pragma mark - Additions

- (void)openColorPickerWithColor:(OAColorItem *)colorItem
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [colorItem getColor];
    [self.navigationController presentViewController:colorViewController animated:YES completion:nil];
}

- (UIMenu *)createPaletteMenuForCellButton:(NSIndexPath *)indexPath
{
    UIAction *duplicateAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_duplicate")
                                                    image:[UIImage systemImageNamed:@"doc.on.doc"]
                                               identifier:nil
                                                  handler:^(UIAction* action) {
        [self duplicateItemFromContextMenu:indexPath];
    }];
    
    UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                 image:[UIImage systemImageNamed:@"trash"]
                                            identifier:nil
                                               handler:^(UIAction* action) {
        [self deleteItemFromContextMenu:indexPath];
    }];
    UIMenu *deleteMenu = [UIMenu menuWithTitle:@""
                                         image:nil
                                    identifier:nil
                                       options:UIMenuOptionsDisplayInline
                                      children:@[deleteAction]];
    return [UIMenu menuWithChildren:@[duplicateAction, deleteMenu]];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    [self openColorPickerWithColor:_selectedColorItem];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _selectedColorItem = _colorItems[indexPath.row];

    if (self.delegate)
        [self.delegate selectColorItem:_selectedColorItem];

    [self dismissViewController];
}

- (void)reloadCollectionData
{
    if (_colorCollectionIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[_colorCollectionIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAColorsCollectionCellDelegate

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:_colorItems[_editColorIndexPath.row]];
}

- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        switch (_collectionType)
        {
            case EOAColorCollectionTypeColorItems:
                if (_colorCollectionIndexPath)
                {
                    OAColorItem *colorItem = _colorItems[indexPath.row];
                    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
                    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:colorItem.isDefault
                                                 ? [colorCell.collectionView numberOfItemsInSection:indexPath.section]
                                                 : (indexPath.row + 1)
                                                                   inSection:indexPath.section];
                    OAColorItem *duplicatedColorItem = [self.delegate duplicateColorItem:colorItem];
                    [_colorItems insertObject:duplicatedColorItem atIndex:newIndexPath.row];
                    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
                    [colorHandler addColor:newIndexPath newItem:duplicatedColorItem];
                }
                break;
            case EOAColorCollectionTypePaletteItems:
            {
                
            }
            default:
                break;
        }
    }
}

- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        switch (_collectionType)
        {
            case EOAColorCollectionTypeColorItems:
                if (_colorCollectionIndexPath)
                {
                    OAColorItem *colorItem = _colorItems[indexPath.row];
                    [_colorItems removeObjectAtIndex:indexPath.row];
                    [self.delegate deleteColorItem:colorItem];
                    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
                    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
                    [colorHandler removeColor:indexPath];
                }
                break;
            case EOAColorCollectionTypePaletteItems:
            {
                
            }
            default:
                break;
        }
    }
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    if (self.delegate && _colorCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        if (_editColorIndexPath)
        {
            if (![[_colorItems[_editColorIndexPath.row] getHexColor] isEqualToString:[viewController.selectedColor toHexARGBString]])
            {
                [self.delegate changeColorItem:_colorItems[_editColorIndexPath.row]
                                     withColor:viewController.selectedColor];
                [colorHandler replaceOldColor:_editColorIndexPath];
            }
            _editColorIndexPath = nil;
        }
        else
        {
            OAColorItem *newColorItem = [self.delegate addAndGetNewColorItem:viewController.selectedColor];
            [_colorItems addObject:newColorItem];
            [colorHandler addAndSelectColor:[NSIndexPath indexPathForRow:_colorItems.count - 1 inSection:0] newItem:newColorItem];
        }
    }
}

@end
