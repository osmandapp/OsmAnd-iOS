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
#import "OAColors.h"
#import "Localization.h"

@interface OAColorsGridViewController () <OACollectionCellDelegate>

@end

@implementation OAColorsGridViewController
{
    OATableDataModel *_data;
    NSArray<NSNumber *> *_colors;
    NSInteger _selectedColor;
}

#pragma mark - Initialization

- (instancetype)initWithColors:(NSArray<NSNumber *> *)colors selectedColor:(NSInteger)selectedColor
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
            OAColorsCollectionHandler *colorsHandler =
                [[OAColorsCollectionHandler alloc] initWithData:@[_colors]
                                              selectedIndexPath:[NSIndexPath indexPathForRow:[_colors indexOfObject:@(_selectedColor)]
                                                                                   inSection:0]];
            colorsHandler.delegate = self;
            [colorsHandler setScrollDirection:UICollectionViewScrollDirectionVertical];
            [cell setCollectionHandler:colorsHandler];
            [cell buttonVisibility:NO];
            [cell anchorContent:EOATableViewCellContentCenterStyle];
            cell.collectionView.scrollEnabled = NO;
        }
        if (cell)
        {
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
    
}

#pragma mark - OACollectionCellDelegate

- (void)onCellSelected:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate onCellSelected:indexPath];
}

@end
