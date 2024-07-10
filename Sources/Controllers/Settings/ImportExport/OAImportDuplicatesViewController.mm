//
//  OAImportDuplicatesViewControllers.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportDuplicatesViewController.h"
#import "OAImportCompleteViewController.h"
#import "OAMainSettingsViewController.h"
#import "Localization.h"
#import "OAApplicationMode.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAResourcesUIHelper.h"
#import "OASettingsImporter.h"
#import "OAQuickAction.h"
#import "OAPOIUIFilter.h"
#import "OAAvoidRoadInfo.h"
#import "OAProfileDataObject.h"
#import "OARoutingDataObject.h"
#import "OASimpleTableViewCell.h"
#import "OAActivityViewWithTitleCell.h"
#import "OAIndexConstants.h"
#import "OAFileSettingsItem.h"
#import "OAFileNameTranslationHelper.h"
#import "OAFavoritesHelper.h"
#import "OAFavoritesSettingsItem.h"
#import "OAOsmNotePoint.h"
#import "OASettingsHelper.h"
#import "OAOpenStreetMapPoint.h"
#import "OADestination.h"
#import "OATileSource.h"
#import "OAPOIHelper.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

@interface OAHeaderType : NSObject

@property (nonatomic) NSString *title;

@end

@implementation OAHeaderType

- (instancetype) initWithTitle:(NSString *)title
{
    self = [super init];
    if (self)
    {
        _title = title;
    }
    return self;
}

@end


@interface OAImportDuplicatesViewController () <OASettingsImportExportDelegate>

@end

@implementation OAImportDuplicatesViewController
{
    OsmAndAppInstance _app;
    NSString *_file;
    OASettingsHelper *_settingsHelper;

    NSArray<NSArray<NSDictionary *> *> *_data;
    BOOL _importStarted;
}

#pragma mark - Initialization

- (instancetype)initWithDuplicatesList:(NSArray *)duplicatesList settingsItems:(NSArray<OASettingsItem *> *)settingsItems file:(NSString *)file
{
    self = [super init];
    if (self)
    {
        _duplicatesList = duplicatesList;
        _settingsItems = settingsItems;
        _file = file;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _settingsHelper = [OASettingsHelper sharedInstance];
}

- (void)postInit
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    if (!importTask)
    {
        if (!_settingsItems)
            _settingsItems = [importTask getSelectedItems];
        if (!_duplicatesList)
            _duplicatesList = [importTask getDuplicates];
        if (!_file)
            _file = [importTask getFile];
        importTask.delegate = self;
    }
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _importStarted ? OALocalizedString(@"shared_string_importing") : OALocalizedString(@"import_duplicates_title");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return _importStarted ? OALocalizedString(@"shared_string_cancel") : nil;
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

- (NSString *)getTableHeaderDescription
{
    return _importStarted ? [NSString stringWithFormat:OALocalizedString(@"importing_from"), _file.lastPathComponent] : OALocalizedString(@"import_duplicates_description");
}

- (NSAttributedString *)getTopButtonTitleAttr
{
    if (_importStarted)
        return nil;

    NSString *title = OALocalizedString(@"keep_both");
    NSString *subtitle = OALocalizedString(@"keep_both_desc");
    NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle]];
    [buttonTitle setColor:[UIColor colorNamed:ACColorNameButtonTextColorSecondary] forString:title];
    [buttonTitle setFont:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold maximumSize:20.] forString:title];
    [buttonTitle setMinLineHeight:18. alignment:NSTextAlignmentCenter forString:title];
    [buttonTitle setColor:[UIColor colorNamed:ACColorNameTextColorSecondary] forString:subtitle];
    [buttonTitle setFont:[UIFont scaledSystemFontOfSize:13. maximumSize:18.] forString:subtitle];
    [buttonTitle setMinLineHeight:17. alignment:NSTextAlignmentCenter forString:subtitle];
    return buttonTitle;
}

- (NSAttributedString *)getBottomButtonTitleAttr
{
    if (_importStarted)
        return nil;

    NSString *title = OALocalizedString(@"replace_all");
    NSString *subtitle = OALocalizedString(@"replace_all_desc");
    NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle]];
    [buttonTitle setColor:[UIColor colorNamed:ACColorNameButtonTextColorPrimary] forString:title];
    [buttonTitle setFont:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold maximumSize:20.] forString:title];
    [buttonTitle setMinLineHeight:18. alignment:NSTextAlignmentCenter forString:title];
    [buttonTitle setColor:[UIColor.whiteColor colorWithAlphaComponent:.5] forString:subtitle];
    [buttonTitle setFont:[UIFont scaledSystemFontOfSize:13. maximumSize:18.] forString:subtitle];
    [buttonTitle setMinLineHeight:17. alignment:NSTextAlignmentCenter forString:subtitle];
    return buttonTitle;
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemePurple;
}

#pragma mark - Table data

- (void)generateData
{
    if (_importStarted || [_settingsHelper.importTask getImportType] == EOAImportTypeImport)
    {
        _data = @[@[@{
            @"cellType": [OAActivityViewWithTitleCell getCellIdentifier],
            @"label": OALocalizedString(@"shared_string_importing")
        }]];
    }
    else if (_duplicatesList)
    {
        // from DuplicatesSettingsAdapter.java : onBindViewHolder()
        NSMutableArray *result = [NSMutableArray new];
        for (NSArray *section in [self prepareDuplicates:_duplicatesList])
        {
            NSMutableArray *sectionData = [NSMutableArray new];
            for (id currentItem in section)
            {
                NSMutableDictionary *item = [NSMutableDictionary new];
                if ([currentItem isKindOfClass:OAHeaderType.class])
                {
                    OAHeaderType *header = (OAHeaderType *)currentItem;
                    item[@"label"] = header.title;
                    item[@"description"] = [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [header.title lowerCase]];
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                    item[@"key"] = @"headerType";
                }
                else if ([currentItem isKindOfClass:OAApplicationModeBean.class])
                {
                    OAApplicationModeBean *modeBean = (OAApplicationModeBean *)currentItem;
                    NSString *profileName = modeBean.userProfileName;
                    if (profileName.length == 0)
                    {
                        OAApplicationMode* appMode = [OAApplicationMode valueOfStringKey:modeBean.stringKey def:nil];
                        if (appMode)
                            profileName = appMode.toHumanString;
                        else
                            profileName = modeBean.stringKey.capitalizedString;
                    }
                    item[@"label"] = profileName;
                    NSString *routingProfile = @"";
                    NSString *routingProfileValue = modeBean.routingProfile;
                    if (routingProfileValue && routingProfileValue.length > 0)
                    {
                        try
                        {
                            routingProfile = [OARoutingDataObject getLocalizedName:[OARoutingDataObject getValueOf:routingProfileValue.upperCase]];
                            routingProfile = [routingProfile capitalizedString];
                            
                        } catch (NSException *e)
                        {
                            routingProfile = [routingProfileValue capitalizedString];
                            NSLog(@"Error trying to get routing resource for %@ \n %@ %@", routingProfileValue, e.name, e.reason);
                        }
                    }
                    if (routingProfile.length == 0)
                        item[@"description"] = @"";
                    else
                        item[@"description"] = [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"nav_type_hint"), routingProfile];
                    
                    item[@"icon"] = [UIImage imageNamed:modeBean.iconName];
                    item[@"iconColor"] = UIColorFromRGB(modeBean.iconColor);
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                else if ([currentItem isKindOfClass:OAQuickAction.class])
                {
                    OAQuickAction *action = (OAQuickAction *)currentItem;
                    item[@"label"] = [action getName];
                    item[@"icon"] = [UIImage imageNamed:[action getIconResName]];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                else if ([currentItem isKindOfClass:OAPOIUIFilter.class])
                {
                    OAPOIUIFilter *filter = (OAPOIUIFilter *)currentItem;
                    item[@"label"] = [filter getName];
                    item[@"icon"] = [OAPOIHelper getCustomFilterIcon:filter];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                else if ([currentItem isKindOfClass:OATileSource.class])
                {
                    OATileSource *tileSource = currentItem;
                    NSString *caption = tileSource.name;
                    item[@"label"] = caption;
                    item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_map"];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                    item[@"iconColor"] = [UIColor colorNamed:ACColorNameIconColorDefault];
                }
                else if ([currentItem isKindOfClass:NSString.class])
                {
                    NSString *file = (NSString *)currentItem;
                    EOASettingsItemFileSubtype type = [OAFileSettingsItemFileSubtype getSubtypeByFileName:file];
                    NSString *fileName = [[[file lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    if ([file hasSuffix:RENDERER_INDEX_EXT])
                    {
                        item[@"label"] = [fileName stringByDeletingPathExtension];
                        item[@"icon"] = [UIImage imageNamed:@"ic_custom_map_style"];
                    }
                    else if ([file hasSuffix:ROUTING_FILE_EXT])
                    {
                        item[@"label"] = fileName;
                        item[@"icon"] = [UIImage imageNamed:@"ic_custom_route"];
                    }
                    else if ([file.lowercaseString hasSuffix:GPX_FILE_EXT])
                    {
                        item[@"label"] = fileName;
                        item[@"icon"] = [UIImage imageNamed:@"ic_custom_trip"];
                    }
                    else if (type == EOASettingsItemFileSubtypeWikiMap)
                    {
                        item[@"label"] = [OAFileNameTranslationHelper getMapName:fileName];
                        item[@"icon"] = [UIImage imageNamed:@"ic_custom_wikipedia"];
                    }
                    else if (type == EOASettingsItemFileSubtypeSrtmMap)
                    {
                        item[@"label"] = [OAFileNameTranslationHelper getMapName:fileName];
                        item[@"icon"] = [UIImage imageNamed:@"ic_custom_contour_lines"];
                    }
                    else
                    {
                        item[@"label"] = [OAFileNameTranslationHelper getMapName:fileName];
                        item[@"icon"] = [UIImage imageNamed:@"ic_custom_map"];
                    }
                    item[@"iconColor"] = [UIColor colorNamed:ACColorNameIconColorDefault];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                else if ([currentItem isKindOfClass:OAAvoidRoadInfo.class])
                {
                    item[@"label"] = ((OAAvoidRoadInfo *)currentItem).name;
                    item[@"icon"] = [UIImage imageNamed:@"ic_custom_alert"];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                else if ([currentItem isKindOfClass:OAFavoriteGroup.class])
                {
                    OAFavoriteGroup *group = (OAFavoriteGroup *)currentItem;
                    item[@"label"] = [OAFavoriteGroup getDisplayName:group.name];
                    item[@"icon"] = [UIImage imageNamed:@"ic_custom_favorites"];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                else if ([currentItem isKindOfClass:OADestination.class])
                {
                    OADestination *marker = (OADestination *)currentItem;
                    item[@"label"] = marker.desc;
                    item[@"icon"] = [UIImage imageNamed:@"ic_custom_marker"];
                    item[@"description"] = @"";
                    item[@"cellType"] = [OASimpleTableViewCell getCellIdentifier];
                }
                NSDictionary *newDict = [NSDictionary dictionaryWithDictionary:item];
                [sectionData addObject:newDict];
            }
            [result addObject:sectionData];
        }
        _data = result;
    }
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"cellType"];
    BOOL isHeaderType = [item[@"key"] isEqualToString:@"headerType"];

    if ([type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"label"];
            
            if (isHeaderType)
            {
                [cell leftIconVisibility:NO];
                cell.descriptionLabel.text = item[@"description"];
            }
            else
            {
                if (!item[@"description"] || ((NSString *)item[@"description"]).length > 0)
                {
                    [cell descriptionVisibility:YES];
                    cell.descriptionLabel.text = item[@"description"];
                }
                else
                {
                    [cell descriptionVisibility:NO];
                    cell.descriptionLabel.text = nil;
                }

                if (item[@"icon"] && item[@"iconColor"])
                {
                    cell.leftIconView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    cell.leftIconView.tintColor = item[@"iconColor"];
                }
                else if (item[@"icon"])
                {
                    cell.leftIconView.image = item[@"icon"];
                    cell.leftIconView.tintColor = nil;
                }
                [cell leftIconVisibility:YES];
            }
        }
        return cell;
    }
    else if ([type isEqualToString:[OAActivityViewWithTitleCell getCellIdentifier]])
    {
        OAActivityViewWithTitleCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAActivityViewWithTitleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAActivityViewWithTitleCell getCellIdentifier] owner:self options:nil];
            cell = (OAActivityViewWithTitleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.titleView.text = item[@"label"];;
            cell.activityIndicatorView.hidden = NO;
            [cell.activityIndicatorView startAnimating];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:OAMainSettingsViewController.class])
        {
            [self.navigationController popToViewController:controller animated:YES];
            return;
        }
    }
}

- (void)onTopButtonPressed
{
    [self importItems:NO];
}

- (void)onBottomButtonPressed
{
    [self importItems:YES];
}

#pragma mark - Additions

- (void)importItems:(BOOL)shouldReplace
{
    if (_settingsItems && _file)
    {
        _importStarted = YES;
        [self updateUIAnimated:nil];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        for (OASettingsItem *item in _settingsItems)
        {
            [item setShouldReplace:shouldReplace];
        }
        [_settingsHelper importSettings:_file items:_settingsItems latestChanges:@"" version:kVersion delegate:self];
    }
}

- (NSArray<NSArray *> *)prepareDuplicates:(NSArray *)duplicatesList
{
    NSMutableArray<NSMutableArray *> *duplicates = [NSMutableArray array];
    NSMutableArray<OAApplicationModeBean *> *profiles = [NSMutableArray array];
    NSMutableArray<OAQuickAction *> *actions = [NSMutableArray array];
    NSMutableArray<OAPOIUIFilter *> *filters = [NSMutableArray array];
    NSMutableArray<OATileSource *> *tileSources = [NSMutableArray array];
    NSMutableArray<NSString *> *renderFilesList = [NSMutableArray array];
    NSMutableArray<NSString *> *routingFilesList = [NSMutableArray array];
    NSMutableArray<NSString *> *gpxFilesList = [NSMutableArray array];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
    NSMutableArray<NSString *> *mapFiles = [NSMutableArray array];
    NSMutableArray<OAFavoriteGroup *> *favoriteItems = [NSMutableArray array];
    NSMutableArray<OAOsmNotePoint *> *osmNotesPointList = [NSMutableArray array];
    NSMutableArray<OAOpenStreetMapPoint *> *osmEditsPointList = [NSMutableArray array];
    NSMutableArray<OADestination *> *activeMarkersList = [NSMutableArray array];

    for (id object in duplicatesList)
    {
        if ([object isKindOfClass:OAApplicationModeBean.class])
            [profiles addObject: (OAApplicationModeBean *)object];
        else if ([object isKindOfClass:OAQuickAction.class])
            [actions addObject: (OAQuickAction *)object];
        if ([object isKindOfClass:OAPOIUIFilter.class])
            [filters addObject: (OAPOIUIFilter *)object];
        else if ([object isKindOfClass:OATileSource.class])
            [tileSources addObject:object];
        else if ([object isKindOfClass:NSString.class])
        {
            NSString *file = (NSString *)object;
            EOASettingsItemFileSubtype subType = [OAFileSettingsItemFileSubtype getSubtypeByFileName:file];
            if ([file hasSuffix:RENDERER_INDEX_EXT])
                [renderFilesList addObject:file];
            else if ([file hasSuffix:ROUTING_FILE_EXT])
                [routingFilesList addObject:file];
            else if ([file.lowercaseString hasSuffix:GPX_FILE_EXT])
                [gpxFilesList addObject:file];
            else if ([OAFileSettingsItemFileSubtype isMap:subType])
                [mapFiles addObject:file];
        }
        else if ([object isKindOfClass:OAAvoidRoadInfo.class])
            [avoidRoads addObject: (OAAvoidRoadInfo *)object];
        else if ([object isKindOfClass:OAFavoriteGroup.class])
            [favoriteItems addObject: (OAFavoriteGroup *)object];
        else if ([object isKindOfClass:OADestination.class])
            [activeMarkersList addObject: (OADestination *)object];
    }
    if (profiles.count > 0)
    {
        NSMutableArray *profilesSection = [NSMutableArray new];
        [profilesSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_profiles")]];
        [profilesSection addObjectsFromArray:profiles];
        [duplicates addObject:profilesSection];
    }
    if (actions.count > 0)
    {
        NSMutableArray *actionsSection = [NSMutableArray new];
        [actionsSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_quick_actions")]];
        [actionsSection addObjectsFromArray:actions];
        [duplicates addObject:actionsSection];
    }
    if (filters.count > 0)
    {
        NSMutableArray *filtersSection = [NSMutableArray new];
        [filtersSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_poi_types")]];
        [filtersSection addObjectsFromArray:filters];
        [duplicates addObject:filtersSection];
    }
    if (tileSources.count > 0)
    {
        NSMutableArray *tileSourcesSection = [NSMutableArray new];
        [tileSourcesSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"quick_action_map_source_title")]];
        [tileSourcesSection addObjectsFromArray:tileSources];
        [duplicates addObject:tileSourcesSection];
    }
    if (routingFilesList.count > 0)
    {
        NSMutableArray *routingSection = [NSMutableArray new];
        [routingSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_routing")]];
        [routingSection addObjectsFromArray:routingFilesList];
        [duplicates addObject:routingSection];
    }
    if (renderFilesList.count > 0)
    {
        NSMutableArray *renderSection = [NSMutableArray new];
        [renderSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_rendering_style")]];
        [renderSection addObjectsFromArray:renderFilesList];
        [duplicates addObject:renderSection];
    }
    if (avoidRoads.count > 0)
    {
        NSMutableArray *avoidRoadsSection = [NSMutableArray new];
        [avoidRoadsSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"avoid_road")]];
        [avoidRoadsSection addObjectsFromArray:avoidRoads];
        [duplicates addObject:avoidRoadsSection];
    }
    if (osmNotesPointList.count > 0)
    {
        NSMutableArray *osmNotesPointSection = [NSMutableArray new];
        [osmNotesPointSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"osm_notes")]];
        [osmNotesPointSection addObjectsFromArray:osmNotesPointList];
        [duplicates addObject:osmNotesPointSection];
    }
    if (osmEditsPointList.count > 0)
    {
        NSMutableArray *osmEditsPointSection = [NSMutableArray new];
        [osmEditsPointSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"osm_notes")]];
        [osmEditsPointSection addObjectsFromArray:osmEditsPointList];
        [duplicates addObject:osmEditsPointSection];
    }
    if (gpxFilesList.count > 0)
    {
        NSMutableArray *gpxSection = [NSMutableArray new];
        [gpxSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_gpx_tracks")]];
        [gpxSection addObjectsFromArray:gpxFilesList];
        [duplicates addObject:gpxSection];
    }
    if (mapFiles.count > 0)
    {
        NSMutableArray *mapsSection = [NSMutableArray new];
        [mapsSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"shared_string_maps")]];
        [mapsSection addObjectsFromArray:mapFiles];
        [duplicates addObject:mapsSection];
    }
    if (favoriteItems.count > 0)
    {
        NSMutableArray *favoritesSection = [NSMutableArray new];
        [favoritesSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"favorites_item")]];
        [favoritesSection addObjectsFromArray:favoriteItems];
        [duplicates addObject:favoritesSection];
    }
    if (activeMarkersList.count > 0)
    {
        NSMutableArray *markersSection = [NSMutableArray new];
        [markersSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"map_markers")]];
        [markersSection addObjectsFromArray:activeMarkersList];
        [duplicates addObject:markersSection];
    }
    return duplicates;
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[OASettingsHelper getSettingsToOperate:items importComplete:YES addEmptyItems:NO] fileName:[_file lastPathComponent]];
        [self showViewController:importCompleteVC];
        _settingsHelper.importTask = nil;
    }
    [OAUtilities denyAccessToFile:_file removeFromInbox:YES];
    [[OASettingsHelper sharedInstance] setCurrentBackupVersion:kVersion];
}

- (void)onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
}

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
}

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
}

@end
