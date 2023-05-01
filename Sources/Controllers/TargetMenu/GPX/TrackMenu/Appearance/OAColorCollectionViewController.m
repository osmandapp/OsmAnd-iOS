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
#import "OAColors.h"
#import "Localization.h"

@interface OAColorCollectionViewController () <UIColorPickerViewControllerDelegate, OAColorsCollectionCellDelegate>

@end

@implementation OAColorCollectionViewController
{
    OAAppSettings *_settings;
    OATableDataModel *_data;
    NSIndexPath *_colorCollectionIndexPath;
    NSArray<NSString *> *_hexKeys;
    NSString *_selectedHexKey;
    NSIndexPath *_editColorIndexPath;
}

#pragma mark - Initialization

- (instancetype)initWithHexKeys:(NSArray<NSString *> *)hexKeys selectedHexKey:(NSString *)selectedHexKey
{
    self = [super init];
    if (self)
    {
        _hexKeys = hexKeys;
        _selectedHexKey = selectedHexKey;
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
    self.tableView.backgroundColor = UIColor.whiteColor;
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
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_hexKeys]];
            colorHandler.delegate = self;
            [colorHandler setScrollDirection:UICollectionViewScrollDirectionVertical];
            [colorHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:[_hexKeys indexOfObject:_selectedHexKey] inSection:0]];
            [cell setCollectionHandler:colorHandler];
            [cell buttonVisibility:NO];
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

- (void)openColorPickerWithColor:(NSString *)hexColor
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [UIColor colorFromString:hexColor];
    [self.navigationController presentViewController:colorViewController animated:YES completion:nil];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    [self openColorPickerWithColor:[_settings getOriginalHexColor:_selectedHexKey]];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _selectedHexKey = _hexKeys[indexPath.row];
    if (self.delegate)
        [self.delegate onHexKeySelected:_selectedHexKey];
}

- (void)reloadCollectionData
{
    if (_colorCollectionIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[_colorCollectionIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAColorsCollectionCellDelegate

- (BOOL)isDefaultColor:(NSString *)hexKey
{
    if (self.delegate)
        return [self.delegate isDefaultColor:hexKey];

    return NO;
}

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:[_settings getOriginalHexColor:_hexKeys[indexPath.row]]];
}

- (void)onContextMenuItemDuplicate:(NSIndexPath *)indexPath
{
    BOOL isDefaultColor = [self isDefaultColor:_hexKeys[indexPath.row]];
    [_settings duplicateCustomTrackHexKey:_hexKeys[indexPath.row] isDefaultColor:isDefaultColor];
    if (self.delegate)
        _hexKeys = [self.delegate updateColors];

    if (_colorCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:isDefaultColor ? [colorCell.collectionView numberOfItemsInSection:indexPath.section] : (indexPath.row + 1)
                                                       inSection:indexPath.section];
        [colorHandler addDuplicatedHexKey:newIndexPath collectionView:colorCell.collectionView];
        [colorHandler updateData:@[_hexKeys] collectionView:colorCell.collectionView];
    }
}

- (void)onContextMenuItemDelete:(NSIndexPath *)indexPath
{
    if (_colorCollectionIndexPath)
    {
        [_settings removeCustomTrackHexKey:_hexKeys[indexPath.row]];
        if (self.delegate)
            _hexKeys = [self.delegate updateColors];

        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler removeColor:indexPath collectionView:colorCell.collectionView];
        [colorHandler updateData:@[_hexKeys] collectionView:colorCell.collectionView];
    }
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    if (_colorCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        if (_editColorIndexPath)
        {
            if (![[_settings getOriginalHexColor:_hexKeys[_editColorIndexPath.row]] isEqualToString:[viewController.selectedColor toHexARGBString]])
            {
                [_settings replaceCustomTrackHexKey:_hexKeys[_editColorIndexPath.row]
                                      withNewHexKey:[viewController.selectedColor toHexARGBString]
                                         isSelected:_editColorIndexPath == [colorHandler getSelectedIndexPath]];
                if (self.delegate)
                    _hexKeys = [self.delegate updateColors];

                [colorHandler updateData:@[_hexKeys] collectionView:colorCell.collectionView];
                if (_editColorIndexPath == [colorHandler getSelectedIndexPath])
                    [self onCollectionItemSelected:_editColorIndexPath];
            }
            _editColorIndexPath = nil;
        }
        else
        {
            [_settings addAndSelectCustomTrackHexKey:[viewController.selectedColor toHexARGBString]];
            if (self.delegate)
                _hexKeys = [self.delegate updateColors];

            [colorHandler addAndSelectIndexPath:[NSIndexPath indexPathForRow:_hexKeys.count - 1 inSection:0]
                                 collectionView:colorCell.collectionView];
            [colorHandler updateData:@[_hexKeys] collectionView:colorCell.collectionView];
        }
    }
}

@end
