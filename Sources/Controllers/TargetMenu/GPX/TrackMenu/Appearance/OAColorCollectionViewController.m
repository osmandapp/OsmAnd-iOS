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
    NSMutableArray<NSNumber *> *_colors;
    NSInteger _selectedColor;
    NSIndexPath *_editColorIndexPath;
}

#pragma mark - Initialization

- (instancetype)initWithColors:(NSMutableArray<NSNumber *> *)colors selectedColor:(NSInteger)selectedColor
{
    self = [super init];
    if (self)
    {
        _colors = colors;
        _selectedColor = selectedColor;
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
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:[NSMutableArray arrayWithObject:_colors]];
            colorHandler.delegate = self;
            [colorHandler setScrollDirection:UICollectionViewScrollDirectionVertical];
            [colorHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:[_colors indexOfObject:@(_selectedColor)] inSection:0]];
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

- (void)openColorPickerWithColor:(NSInteger)color
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = UIColorFromARGB(color);
    [self.navigationController presentViewController:colorViewController animated:YES completion:nil];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    [self openColorPickerWithColor:_selectedColor];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _selectedColor = _colors[indexPath.row].integerValue;
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
    return indexPath.row < _colors.count - [[OAAppSettings sharedManager].customTrackColors get].count;
}

- (void)onItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:_colors[indexPath.row].integerValue];
}

- (void)onItemDuplicate:(NSIndexPath *)indexPath
{
    NSString *hexColor = [UIColorFromARGB(_colors[indexPath.row].integerValue) toHexARGBString];
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[[OAAppSettings sharedManager].customTrackColors get]];
    BOOL isDefaultColor = indexPath.row < _colors.count - customTrackColors.count;
    if (isDefaultColor)
        [customTrackColors addObject:hexColor];
    else
        [customTrackColors insertObject:hexColor atIndex:indexPath.row - (_colors.count - customTrackColors.count) + 1];
    [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

    if (_colorCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler duplicateColor:indexPath isDefaultColor:isDefaultColor collectionView:colorCell.collectionView];
    }
}

- (void)onItemDelete:(NSIndexPath *)indexPath
{
    NSString *hexColor = [UIColorFromARGB(_colors[indexPath.row].integerValue) toHexARGBString];
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[[OAAppSettings sharedManager].customTrackColors get]];
    [customTrackColors removeObject:hexColor];
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
        NSInteger oldColor = _colors[_editColorIndexPath.row].integerValue;
        NSString *newColorHex = [viewController.selectedColor toHexARGBString];
        NSInteger newColor = [OAUtilities colorToNumberFromString:newColorHex];

        [customTrackColors replaceObjectAtIndex:[customTrackColors indexOfObject:[UIColorFromARGB(oldColor) toHexARGBString]]
                                     withObject:newColorHex];
        [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

        if (_colorCollectionIndexPath)
        {
            OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
            OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
            [colorHandler replaceOldColor:_editColorIndexPath withNewColor:newColor collectionView:colorCell.collectionView];
        }

        _editColorIndexPath = nil;
    }
    else
    {
        NSString *selectedHexColor = [viewController.selectedColor toHexARGBString];

        [customTrackColors addObject:selectedHexColor];
        [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];

        if (_colorCollectionIndexPath)
        {
            OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorCollectionIndexPath];
            OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
            [colorHandler addAndSelectColor:[OAUtilities colorToNumberFromString:selectedHexColor]
                             collectionView:colorCell.collectionView];
        }
    }
}

@end
