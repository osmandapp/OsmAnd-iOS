//
//  OAOsmUploadGPXVisibilityViewConroller.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAOsmUploadGPXVisibilityViewConroller.h"
#import "OASimpleTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OALog.h"

@implementation OAOsmUploadGPXVisibilityViewConroller
{
    EOAOsmUploadGPXVisibility _selectedVisibility;
    OATableDataModel *_data;
}

#pragma mark - Initialization

- (instancetype) initWithVisibility:(EOAOsmUploadGPXVisibility)visibility
{
    self = [super init];
    if (self)
    {
        _selectedVisibility = visibility;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"visibility");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    __weak OAOsmUploadGPXVisibilityViewConroller *weakSelf = self;
    
    OATableSectionData *section = [_data createNewSection];
    section.footerText = [self localizedDescriptionForVisibilityType:_selectedVisibility];
    
    OATableRowData *publicCell = [section createNewRow];
    [publicCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [publicCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityPublic]];
    [publicCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityPublic) forKey:@"selected"];
    [publicCell setObj: (^void(){ [weakSelf onVisibilityChanged:EOAOsmUploadGPXVisibilityPublic]; }) forKey:@"actionBlock"];
    
    OATableRowData *identifiableCell = [section createNewRow];
    [identifiableCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [identifiableCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityIdentifiable]];
    [identifiableCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityIdentifiable) forKey:@"selected"];
    [identifiableCell setObj: (^void(){ [weakSelf onVisibilityChanged:EOAOsmUploadGPXVisibilityIdentifiable]; }) forKey:@"actionBlock"];
    
    OATableRowData *trackableCell = [section createNewRow];
    [trackableCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [trackableCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityTrackable]];
    [trackableCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityTrackable) forKey:@"selected"];
    [trackableCell setObj: (^void(){ [weakSelf onVisibilityChanged:EOAOsmUploadGPXVisibilityTrackable]; }) forKey:@"actionBlock"];
    
    OATableRowData *privateCell = [section createNewRow];
    [privateCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [privateCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityPrivate]];
    [privateCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityPrivate) forKey:@"selected"];
    [privateCell setObj: (^void(){ [weakSelf onVisibilityChanged:EOAOsmUploadGPXVisibilityPrivate]; }) forKey:@"actionBlock"];
}

+ (NSString *) localizedNameForVisibilityType:(EOAOsmUploadGPXVisibility)visibility
{
    if (visibility == EOAOsmUploadGPXVisibilityPublic)
        return OALocalizedString(@"gpxup_public");
    else if (visibility == EOAOsmUploadGPXVisibilityIdentifiable)
        return OALocalizedString(@"gpxup_identifiable");
    else if (visibility == EOAOsmUploadGPXVisibilityTrackable)
        return OALocalizedString(@"gpxup_trackable");
    else if (visibility == EOAOsmUploadGPXVisibilityPrivate)
        return OALocalizedString(@"gpxup_private");
    return nil;
}

+ (NSString *) toUrlParam:(EOAOsmUploadGPXVisibility)visibility
{
    if (visibility == EOAOsmUploadGPXVisibilityPublic)
        return @"public";
    else if (visibility == EOAOsmUploadGPXVisibilityIdentifiable)
        return @"identifiable";
    else if (visibility == EOAOsmUploadGPXVisibilityTrackable)
        return @"trackable";
    else if (visibility == EOAOsmUploadGPXVisibilityPrivate)
        return @"private";
    return nil;
}

- (NSString *) localizedDescriptionForVisibilityType:(EOAOsmUploadGPXVisibility)visibility
{
    if (visibility == EOAOsmUploadGPXVisibilityPublic)
        return OALocalizedString(@"gpx_upload_public_visibility_descr");
    else if (visibility == EOAOsmUploadGPXVisibilityIdentifiable)
        return OALocalizedString(@"gpx_upload_identifiable_visibility_descr");
    else if (visibility == EOAOsmUploadGPXVisibilityTrackable)
        return OALocalizedString(@"gpx_upload_trackable_visibility_descr");
    else if (visibility == EOAOsmUploadGPXVisibilityPrivate)
        return OALocalizedString(@"gpx_upload_private_visibility_descr");
    return nil;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
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
    NSString *cellType = item.cellType;
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            BOOL selected = [item boolForKey:@"selected"];
            cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.accessibilityValue = selected ? OALocalizedString(@"shared_string_selected") : OALocalizedString(@"shared_string_not_selected");
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
}

#pragma mark - Selectors

- (void) onVisibilityChanged:(EOAOsmUploadGPXVisibility)visibility
{
    OALog(@"onVisibilityChanged");
    _selectedVisibility = visibility;
    [self generateData];
    [self.tableView reloadData];
    
    if (self.visibilityDelegate)
        [self.visibilityDelegate onVisibilityChanged:visibility];
    
    [self dismissViewController];
}

@end

