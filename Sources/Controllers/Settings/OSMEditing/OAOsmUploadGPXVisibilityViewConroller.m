//
//  OAOsmUploadGPXVisibilityViewConroller.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAOsmUploadGPXVisibilityViewConroller.h"
#import "OASettingsTitleTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "Localization.h"
#import "OAColors.h"

@interface OAOsmUploadGPXVisibilityViewConroller () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAOsmUploadGPXVisibilityViewConroller
{
    EOAOsmUploadGPXVisibility _selectedVisibility;
    OATableDataModel *_data;
}

- (instancetype) initWithVisibility:(EOAOsmUploadGPXVisibility)visibility
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self) {
        _selectedVisibility = visibility;
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"visibility");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.subtitleLabel.hidden = YES;
    [self showCancelButtonWithBackButton];
    [self setupView];
}

- (void) setupView
{
    _data = [[OATableDataModel alloc] init];
    
    OATableSectionData *section = [OATableSectionData sectionData];
    if (_selectedVisibility == EOAOsmUploadGPXVisibilityPublic)
        section.footerText = OALocalizedString(@"gpx_upload_public_visibility_descr");
    else if (_selectedVisibility == EOAOsmUploadGPXVisibilityIdentifiable)
        section.footerText = OALocalizedString(@"gpx_upload_identifiable_visibility_descr");
    else if (_selectedVisibility == EOAOsmUploadGPXVisibilityTrackable)
        section.footerText = OALocalizedString(@"gpx_upload_trackable_visibility_descr");
    else if (_selectedVisibility == EOAOsmUploadGPXVisibilityPrivate)
        section.footerText = OALocalizedString(@"gpx_upload_private_visibility_descr");
    
    [self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityPublic];
    
    OATableRowData *publicCell = [OATableRowData rowData];
    [publicCell setCellType:[OASettingsTitleTableViewCell getCellIdentifier]];
    [publicCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityPublic]];
    [publicCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityPublic) forKey:@"selected"];
    [publicCell setObj: (^void(){ [self onVisibilityChanged:EOAOsmUploadGPXVisibilityPublic]; }) forKey:@"actionBlock"];
    [section addRow:publicCell];
    
    OATableRowData *identifiableCell = [OATableRowData rowData];
    [identifiableCell setCellType:[OASettingsTitleTableViewCell getCellIdentifier]];
    [identifiableCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityIdentifiable]];
    [identifiableCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityIdentifiable) forKey:@"selected"];
    [identifiableCell setObj: (^void(){ [self onVisibilityChanged:EOAOsmUploadGPXVisibilityIdentifiable]; }) forKey:@"actionBlock"];
    [section addRow:identifiableCell];
    
    OATableRowData *trackableCell = [OATableRowData rowData];
    [trackableCell setCellType:[OASettingsTitleTableViewCell getCellIdentifier]];
    [trackableCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityTrackable]];
    [trackableCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityTrackable) forKey:@"selected"];
    [trackableCell setObj: (^void(){ [self onVisibilityChanged:EOAOsmUploadGPXVisibilityTrackable]; }) forKey:@"actionBlock"];
    [section addRow:trackableCell];
    
    OATableRowData *privateCell = [OATableRowData rowData];
    [privateCell setCellType:[OASettingsTitleTableViewCell getCellIdentifier]];
    [privateCell setTitle:[self.class localizedNameForVisibilityType:EOAOsmUploadGPXVisibilityPrivate]];
    [privateCell setObj:@(_selectedVisibility == EOAOsmUploadGPXVisibilityPrivate) forKey:@"selected"];
    [privateCell setObj: (^void(){ [self onVisibilityChanged:EOAOsmUploadGPXVisibilityPrivate]; }) forKey:@"actionBlock"];
    [section addRow:privateCell];
    
    [_data addSection:section];
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

#pragma mark - Actions

- (void) onVisibilityChanged:(EOAOsmUploadGPXVisibility)visibility
{
    NSLog(@"onVisibilityChanged");
    _selectedVisibility = visibility;
    [self setupView];
    [self.tableView reloadData];
    
    if (self.visibilityDelegate)
        [self.visibilityDelegate onVisibilityChanged:visibility];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellType = item.cellType;
    if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item.title;
            cell.iconView.hidden = ![item boolForKey:@"selected"];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
}

@end

