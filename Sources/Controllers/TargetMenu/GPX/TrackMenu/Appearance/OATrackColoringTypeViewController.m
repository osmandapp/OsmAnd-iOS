//
//  OATrackColoringTypeViewController.m
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATrackColoringTypeViewController.h"
#import "OATrackMenuAppearanceHudViewController.h"
#import "OAPluginPopupViewController.h"
#import "OASimpleTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAProducts.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

@implementation OATrackColoringTypeViewController
{
    OATableDataModel *_data;
    NSArray<OATrackAppearanceItem *> *_availableColoringTypes;
    OATrackAppearanceItem *_selectedItem;
}

#pragma mark - Initialization

- (instancetype)initWithAvailableColoringTypes:(NSArray<OATrackAppearanceItem *> *)availableColoringTypes selectedItem:(OATrackAppearanceItem *)selectedItem
{
    self = [super init];
    if (self)
    {
        _availableColoringTypes = availableColoringTypes;
        _selectedItem = selectedItem;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_coloring");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *coloringTypeSection = [_data createNewSection];

    for (OATrackAppearanceItem *availableColoringType in _availableColoringTypes)
    {
        [coloringTypeSection addRowFromDictionary:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            @"appearanceItem": availableColoringType
        }];
    }
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
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            OATrackAppearanceItem *appearanceItem = [item objForKey:@"appearanceItem"];
            cell.accessoryType = _selectedItem == appearanceItem ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.accessibilityLabel = appearanceItem.title;
            cell.titleLabel.text = appearanceItem.title;
            cell.titleLabel.textColor = appearanceItem.isAvailable && appearanceItem.isEnabled ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
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
    OATrackAppearanceItem *appearanceItem = [item objForKey:@"appearanceItem"];
    if (appearanceItem.isAvailable)
    {
        if (!appearanceItem.isEnabled)
        {
            [OAUtilities showToast:OALocalizedString(@"track_has_no_needed_data")
                           details:OALocalizedString(@"select_another_colorization")
                          duration:4
                            inView:self.view];
        }
        else
        {
            [self dismissViewController];
            if (self.delegate)
                [self.delegate onColoringTypeSelected:appearanceItem];
        }
    }
    else
    {
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Advanced_Widgets];
    }
}

@end
