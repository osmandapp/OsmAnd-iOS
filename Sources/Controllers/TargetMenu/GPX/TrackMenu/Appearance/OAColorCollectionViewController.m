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
    OATableDataModel *_data;
    NSIndexPath *_colorCollectionIndexPath;
    NSMutableArray<NSString *> *_hexKeys;
    NSString *_selectedHexKey;
    NSIndexPath *_editColorIndexPath;
}

#pragma mark - Initialization

- (instancetype)initWithHexKeys:(NSMutableArray<NSString *> *)hexKeys selectedHexKey:(NSString *)selectedHexKey
{
    self = [super init];
    if (self)
    {
        _hexKeys = hexKeys;
        _selectedHexKey = selectedHexKey;
    }
    return self;
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
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:[NSMutableArray arrayWithObject:_hexKeys]];
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
    [self openColorPickerWithColor:[OAGPXAppearanceCollection getOriginalHexColor:_selectedHexKey]];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _selectedHexKey = _hexKeys[indexPath.row];
    if (self.delegate)
        [self.delegate onCollectionItemSelected:indexPath];
}

- (void)reloadCollectionData
{
    if (_colorCollectionIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[_colorCollectionIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAColorsCollectionCellDelegate

- (BOOL)isDefaultColor:(NSIndexPath *)indexPath
{
    return indexPath.row < (_hexKeys.count - [[OAAppSettings sharedManager].customTrackColors get].count);
}

- (void)onItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:[OAGPXAppearanceCollection getOriginalHexColor:_hexKeys[indexPath.row]]];
}

- (void)onItemDuplicate:(NSIndexPath *)indexPath
{
    BOOL isDefaultColor = [self isDefaultColor:indexPath];
    NSString *duplicatedHexKey = [OAGPXAppearanceCollection checkDuplicateHexColor:_hexKeys[indexPath.row]];
    if (isDefaultColor && ![duplicatedHexKey containsString:@"_"])
        duplicatedHexKey = [duplicatedHexKey stringByAppendingString:@"_2"];
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[[OAAppSettings sharedManager].customTrackColors get]];
    if (isDefaultColor)
        [customTrackColors addObject:duplicatedHexKey];
    else
        [customTrackColors insertObject:duplicatedHexKey atIndex:indexPath.row - (_hexKeys.count - customTrackColors.count) + 1];
    [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

    if (_colorCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:isDefaultColor ? [colorCell.collectionView numberOfItemsInSection:indexPath.section] : (indexPath.row + 1)
                                                       inSection:indexPath.section];
        [colorHandler addDuplicatedHexKey:duplicatedHexKey toNewIndexPath:newIndexPath collectionView:colorCell.collectionView];
    }
}

- (void)onItemDelete:(NSIndexPath *)indexPath
{
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[[OAAppSettings sharedManager].customTrackColors get]];
    [customTrackColors removeObject:_hexKeys[indexPath.row]];
    [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

    if (_colorCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler removeColor:indexPath collectionView:colorCell.collectionView];
    }
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[[OAAppSettings sharedManager].customTrackColors get]];
    if (_editColorIndexPath)
    {
        if (![[OAGPXAppearanceCollection getOriginalHexColor:_hexKeys[_editColorIndexPath.row]] isEqualToString:[viewController.selectedColor toHexARGBString]])
        {
            NSString *newColorHex = [OAGPXAppearanceCollection checkDuplicateHexColor:[viewController.selectedColor toHexARGBString]];
            [customTrackColors replaceObjectAtIndex:_editColorIndexPath.row - (_hexKeys.count - customTrackColors.count) withObject:newColorHex];
            [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

            if (_colorCollectionIndexPath)
            {
                OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
                OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
                [colorHandler replaceOldColor:_editColorIndexPath withNewHexKey:newColorHex collectionView:colorCell.collectionView];
            }
        }
        _editColorIndexPath = nil;
    }
    else
    {
        NSString *selectedHexColor = [OAGPXAppearanceCollection checkDuplicateHexColor:[viewController.selectedColor toHexARGBString]];
        [customTrackColors addObject:selectedHexColor];
        [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

        if (_colorCollectionIndexPath)
        {
            OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
            OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
            [colorHandler addAndSelectHexKey:selectedHexColor collectionView:colorCell.collectionView];
        }
    }
}

@end
