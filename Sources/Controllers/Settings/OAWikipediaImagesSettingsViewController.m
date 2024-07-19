//
//  OAWikipediaImagesSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 17.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWikipediaImagesSettingsViewController.h"
#import "OAWikipediaLanguagesViewController.h"
#import "OASimpleTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OADownloadMode.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OAWikipediaImagesSettingsViewController
{
    OATableDataModel *_data;
    OsmAndAppInstance _app;
}

#pragma mark - Initialization

- (void)commonInit
{
    _app = [OsmAndApp instance];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"wikivoyage_download_pics");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getSubtitle
{
    return @"";
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *downloadImagesSection = [_data createNewSection];

    for (OADownloadMode *downloadMode in [OADownloadMode getDownloadModes])
    {
        [downloadImagesSection addRowFromDictionary:@{
            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
            @"downloadMode" : downloadMode
        }];
    }
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
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            OADownloadMode *downloadMode = [item objForKey:@"downloadMode"];

            cell.titleLabel.text = downloadMode.title;
            cell.leftIconView.image = [UIImage templateImageNamed:downloadMode.iconName];

            BOOL isSelected = [downloadMode isEqual:[_app.data getWikipediaImagesDownloadMode:self.appMode]];
            cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.leftIconView.tintColor = isSelected ? [self.appMode getProfileColor] : [UIColor colorNamed:ACColorNameIconColorDisabled];
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
    OADownloadMode *downloadMode = [item objForKey:@"downloadMode"];
    [_app.data setWikipediaImagesDownloadMode:downloadMode mode:self.appMode];

    if (self.wikipediaDelegate)
        [self.wikipediaDelegate updateWikipediaSettings];

    [self dismissViewController];
}

@end
