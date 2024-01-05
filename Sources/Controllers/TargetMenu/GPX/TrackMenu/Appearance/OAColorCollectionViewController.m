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
    OAColorItem *_selectedColorItem;
    NSIndexPath *_editColorIndexPath;
}

#pragma mark - Initialization

- (instancetype)initWithColorItems:(NSArray<OAColorItem *> *)colorItems selectedColorItem:(OAColorItem *)selectedColorItem
{
    self = [super init];
    if (self)
    {
        _colorItems = [NSMutableArray arrayWithArray:colorItems];
        _selectedColorItem = selectedColorItem;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
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
    UIBarButtonItem *addButton = [self createRightNavbarButton:nil iconName:@"ic_custom_add" action:@selector(onRightNavbarButtonPressed) menu:nil];
    addButton.accessibilityLabel = OALocalizedString(@"shared_string_add_color");
    return @[addButton];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeWhite;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *colorsSection = [_data createNewSection];
    [colorsSection addRowFromDictionary:@{
        kCellTypeKey: [OACollectionSingleLineTableViewCell getCellIdentifier]
    }];
    _colorCollectionIndexPath = [NSIndexPath indexPathForRow:[colorsSection rowCount] - 1 inSection:[_data sectionCount] - 1];
}

- (BOOL)hideFirstHeader
{
    return YES;
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
        OACollectionSingleLineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACollectionSingleLineTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = nib[0];
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_colorItems] collectionView:cell.collectionView];
            colorHandler.delegate = self;
            [colorHandler setScrollDirection:UICollectionViewScrollDirectionVertical];
            [colorHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:[_colorItems indexOfObject:_selectedColorItem] inSection:0]];
            [cell setCollectionHandler:colorHandler];
            [cell rightActionButtonVisibility:NO];
            [cell anchorContent:EOATableViewCellContentCenterStyle];
            cell.collectionView.scrollEnabled = NO;
        }
        if (cell)
        {
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

#pragma mark - Additions

- (void)openColorPickerWithColor:(OAColorItem *)colorItem
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [colorItem getColor];
    [self.navigationController presentViewController:colorViewController animated:YES completion:nil];
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
    if (self.delegate && _colorCollectionIndexPath)
    {
        OAColorItem *colorItem = _colorItems[indexPath.row];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:colorItem.isDefault ? [colorCell.collectionView numberOfItemsInSection:indexPath.section] : (indexPath.row + 1)
                                                       inSection:indexPath.section];
        OAColorItem *duplicatedColorItem = [self.delegate duplicateColorItem:colorItem];
        [_colorItems insertObject:duplicatedColorItem atIndex:newIndexPath.row];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler addColor:newIndexPath newItem:duplicatedColorItem];
    }
}

- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath
{
    if (self.delegate && _colorCollectionIndexPath)
    {
        OAColorItem *colorItem = _colorItems[indexPath.row];
        [_colorItems removeObjectAtIndex:indexPath.row];
        [self.delegate deleteColorItem:colorItem];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler removeColor:indexPath];
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
