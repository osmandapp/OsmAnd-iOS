//
//  OAColorsGridViewController.m
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorsGridViewController.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAColorsCollectionHandler.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAColorsGridViewController () <UIColorPickerViewControllerDelegate, OACollectionCellDelegate>

@end

@implementation OAColorsGridViewController
{
    OATableDataModel *_data;
    NSIndexPath *_colorsGridIndexPath;
    NSMutableArray<NSNumber *> *_colors;
    NSInteger _selectedColor;
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
    return @[[self createRightNavbarButton:nil iconName:@"ic_custom_add" action:@selector(onRightNavbarButtonPressed) menu:nil]];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeWhite;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *colorsGridSection = [_data createNewSection];
    [colorsGridSection addRowFromDictionary:@{
        kCellTypeKey: [OACollectionSingleLineTableViewCell getCellIdentifier]
    }];
    _colorsGridIndexPath = [NSIndexPath indexPathForRow:[colorsGridSection rowCount] - 1 inSection:[_data sectionCount] - 1];
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
            OAColorsCollectionHandler *colorsHandler = [[OAColorsCollectionHandler alloc] initWithData:[NSMutableArray arrayWithObject:_colors]];
            colorsHandler.delegate = self;
            [colorsHandler setScrollDirection:UICollectionViewScrollDirectionVertical];
            [colorsHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:[_colors indexOfObject:@(_selectedColor)] inSection:0]];
            [cell setCollectionHandler:colorsHandler];
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

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    UIColorPickerViewController *colorsViewController = [[UIColorPickerViewController alloc] init];
    colorsViewController.delegate = self;
    colorsViewController.selectedColor = UIColorFromARGB(_selectedColor);
    [self.navigationController presentViewController:colorsViewController animated:YES completion:nil];
}

#pragma mark - OACollectionCellDelegate

- (void)onCellSelected:(NSIndexPath *)indexPath
{
    _selectedColor = _colors[indexPath.row].integerValue;
    if (self.delegate)
        [self.delegate onCellSelected:indexPath];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    UIColor *selectedColor = viewController.selectedColor;
    _selectedColor = [OAUtilities colorToNumberFromString:[selectedColor toHexARGBString]];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[[OAAppSettings sharedManager].customTrackColors get]];
    NSString *hexColor = [selectedColor toHexARGBString];
    if (![customTrackColors containsObject:hexColor])
    {
        [customTrackColors addObject:hexColor];
        [[OAAppSettings sharedManager].customTrackColors set:customTrackColors];
    }

    if (_colorsGridIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorsCell = [self.tableView cellForRowAtIndexPath:_colorsGridIndexPath];
        OAColorsCollectionHandler *colorsHandler = (OAColorsCollectionHandler *) [colorsCell getCollectionHandler];
        [colorsHandler addColorIfNeededAndSelect:_selectedColor collectionView:colorsCell.collectionView];
    }

    [self.tableView reloadData];
}

@end
