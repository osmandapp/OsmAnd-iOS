//
//  OAWikipediaSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWikipediaSettingsViewController.h"
#import "OAWikipediaLanguagesViewController.h"
#import "OAWikipediaImagesSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAWikipediaPlugin.h"
#import "OAApplicationMode.h"
#import "OADownloadMode.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAWikipediaSettingsViewController () <OAWikipediaScreenDelegate>

@end

@implementation OAWikipediaSettingsViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    OAWikipediaPlugin *_wikiPlugin;
    NSIndexPath *_selectedIndexPath;
}

#pragma mark - Initialization

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _wikiPlugin = (OAWikipediaPlugin *) [OAPlugin getPlugin:OAWikipediaPlugin.class];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _selectedIndexPath = nil;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"download_wikipedia_maps");
}

- (NSString *)getSubtitle
{
    return OALocalizedString(@"shared_string_settings");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *languageSection = [_data createNewSection];
    languageSection.footerText = OALocalizedString(@"wikipedia_language_settings_descr");

    OATableRowData *languageItem = [languageSection createNewRow];
    languageItem.key = @"language";
    languageItem.cellType = [OAValueTableViewCell getCellIdentifier];
    languageItem.title = OALocalizedString(@"shared_string_language");
    languageItem.iconName = @"ic_custom_map_languge";
    [self generateValueForItem:languageItem];

    OATableRowData *imagesItem = [languageSection createNewRow];
    imagesItem.key = @"images";
    imagesItem.cellType = [OAValueTableViewCell getCellIdentifier];
    imagesItem.title = OALocalizedString(@"wikivoyage_download_pics");
    imagesItem.iconName = [_app.data getWikipediaImagesDownloadMode:self.appMode].iconName;
    [self generateValueForItem:imagesItem];
}

- (void)generateValueForItem:(OATableRowData *)item
{
    if ([item.key isEqualToString:@"language"])
    {
        [item setObj:[_wikiPlugin getLanguagesSummary:self.appMode] forKey:@"value"];
    }
    else if ([item.key isEqualToString:@"images"])
    {
        OADownloadMode *downloadMode = [_app.data getWikipediaImagesDownloadMode:self.appMode];
        [item setObj:downloadMode.title forKey:@"value"];
        item.iconName = downloadMode.iconName;
    }
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = UIColorFromRGB([self.appMode getIconColor]);
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
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
    _selectedIndexPath = indexPath;

    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"language"])
    {
        OAWikipediaLanguagesViewController *controller = [[OAWikipediaLanguagesViewController alloc] initWithAppMode:self.appMode];
        controller.wikipediaDelegate = self;
        [self showModalViewController:controller];
    }
    if ([item.key isEqualToString:@"images"])
    {
        OAWikipediaImagesSettingsViewController *controller = [[OAWikipediaImagesSettingsViewController alloc] initWithAppMode:self.appMode];
        controller.wikipediaDelegate = self;
        [self showModalViewController:controller];
    }
}

#pragma mark - OAWikipediaScreenDelegate

- (void)updateWikipediaSettings
{
    if (_selectedIndexPath)
    {
        OATableRowData *item = [_data itemForIndexPath:_selectedIndexPath];
        [self generateValueForItem:item];
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
