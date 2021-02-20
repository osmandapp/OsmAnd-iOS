//
//  OAImportDuplicatesViewControllers.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportDuplicatesViewController.h"
#import "OAImportCompleteViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAResourcesUIHelper.h"
#import "OASettingsImporter.h"
#import "OAApplicationMode.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickActionType.h"
#import "OAQuickAction.h"
#import "OAMapSource.h"
#import "OASQLiteTileSource.h"
#import "OAPOIUIFilter.h"
#import "OAAvoidRoadInfo.h"
#import "OAProfileDataObject.h"
#import "OAMenuSimpleCell.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OATitleTwoIconsRoundCell.h"
#import "OAActivityViewWithTitleCell.h"
#import "OAMapSource.h"
#import "OAIndexConstants.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItem.h"
#import "OASettingsHelper.h"
#import "OAFileNameTranslationHelper.h"
#import "OAFavoritesHelper.h"
#import "OAFavoritesSettingsItem.h"
#import "OAOsmNotePoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAMarkersSettingsItem.h"
#import "OADestination.h"

#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kTitleTwoIconsRoundCell @"OATitleTwoIconsRoundCell"
#define kCellTypeWithActivity @"OAActivityViewWithTitleCell"

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


@interface OAImportDuplicatesViewController () <UITableViewDelegate, UITableViewDataSource, OASettingsImportExportDelegate>

@end

@implementation OAImportDuplicatesViewController
{
    OsmAndAppInstance _app;
    NSArray *_duplicatesList;
    NSArray<OASettingsItem *> * _settingsItems;
    NSString *_file;
    OASettingsHelper *_settingsHelper;
    
    NSString *_title;
    NSString *_description;

    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithDuplicatesList:(NSArray *)duplicatesList settingsItems:(NSArray<OASettingsItem *> *)settingsItems file:(NSString *)file
{
    self = [super init];
    if (self)
    {
        _duplicatesList = duplicatesList;
        _settingsItems = settingsItems;
        _file = file;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _settingsHelper = [OASettingsHelper sharedInstance];
    
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

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    self.additionalNavBarButton.hidden = YES;
    [self setupBottomViewMultyLabelButtons];
    [super viewDidLoad];
    
    if (_duplicatesList)
        [self prepareData: [self prepareDuplicates:_duplicatesList]];
    if ([_settingsHelper.importTask getImportType] == EOAImportTypeImport)
        [self setupImportingUI];
    else
        _title = OALocalizedString(@"import_duplicates_title");
    _title = OALocalizedString(@"import_duplicates_title");
}

- (void) setupImportingUI
{
    [self turnOnLoadingIndicator];
    self.bottomBarView.hidden = YES;
    self.view.backgroundColor = self.tableView.backgroundColor;
    [self.tableView reloadData];
}

- (void) turnOnLoadingIndicator
{
    NSDictionary * loadingItem = @{@"cellType": kCellTypeWithActivity,
                                   @"label": OALocalizedString(@"shared_string_importing")};
    NSMutableArray *firstSection = [NSMutableArray arrayWithObject:loadingItem];
    _data = [NSArray arrayWithObject:firstSection];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (NSArray<NSArray *> *) prepareDuplicates:(NSArray *)duplicatesList
{
    NSMutableArray<NSMutableArray *> *duplicates = [NSMutableArray new];
    NSMutableArray<OAApplicationModeBean *> *profiles = [NSMutableArray new];
    NSMutableArray<OAQuickAction *> *actions = [NSMutableArray new];
    NSMutableArray<OAPOIUIFilter *> *filters = [NSMutableArray new];
    NSMutableArray<NSDictionary *> *tileSources = [NSMutableArray new];
    NSMutableArray<NSString *> *renderFilesList = [NSMutableArray new];
    NSMutableArray<NSString *> *routingFilesList = [NSMutableArray new];
    NSMutableArray<NSString *> *gpxFilesList = [NSMutableArray new];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray new];
    NSMutableArray<NSString *> *mapFiles = [NSMutableArray new];
    NSMutableArray<OAFavoriteGroup *> *favoriteItems = [NSMutableArray new];
    NSMutableArray<OAOsmNotePoint *> *osmNotesPointList = [NSMutableArray new];
    NSMutableArray<OAOpenStreetMapPoint *> *osmEditsPointList = [NSMutableArray new];
    NSMutableArray<OADestination *> *activeMarkersList = [NSMutableArray new];
    
    for (id object in duplicatesList)
    {
        if ([object isKindOfClass:OAApplicationModeBean.class])
            [profiles addObject: (OAApplicationModeBean *)object];
        else if ([object isKindOfClass:OAQuickAction.class])
            [actions addObject: (OAQuickAction *)object];
        if ([object isKindOfClass:OAPOIUIFilter.class])
            [filters addObject: (OAPOIUIFilter *)object];
        else if ([object isKindOfClass:NSDictionary.class])
            [tileSources addObject: (NSDictionary *)object];
        else if ([object isKindOfClass:NSString.class])
        {
            NSString *file = (NSString *)object;
            EOASettingsItemFileSubtype subType = [OAFileSettingsItemFileSubtype getSubtypeByFileName:file];
            if ([file hasSuffix:RENDERER_INDEX_EXT])
                [renderFilesList addObject:file];
            else if ([file hasSuffix:ROUTING_FILE_EXT])
                [routingFilesList addObject:file];
            else if ([file hasSuffix:GPX_FILE_EXT])
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
        [gpxSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"tracks")]];
        [gpxSection addObjectsFromArray:gpxFilesList];
        [duplicates addObject:gpxSection];
    }
    if (mapFiles.count > 0)
    {
        NSMutableArray *mapsSection = [NSMutableArray new];
        [mapsSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"maps")]];
        [mapsSection addObjectsFromArray:mapFiles];
        [duplicates addObject:mapsSection];
    }
    if (favoriteItems.count > 0)
    {
        NSMutableArray *favoritesSection = [NSMutableArray new];
        [favoritesSection addObject:[[OAHeaderType alloc] initWithTitle:OALocalizedString(@"favorites")]];
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

// from DuplicatesSettingsAdapter.java : onBindViewHolder()
- (void) prepareData:(NSArray<NSArray *> *)duplicates
{
    NSMutableArray *result = [NSMutableArray new];
    for (NSArray *section in duplicates)
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
                item[@"cellType"] = kMenuSimpleCellNoIcon;
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
                        routingProfile = [OARoutingProfileDataObject getLocalizedName: [OARoutingProfileDataObject getValueOf: [routingProfileValue upperCase]]];
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
                    item[@"description"] = [NSString stringWithFormat:OALocalizedString(@"nav_type_hint"), routingProfile];
                
                item[@"icon"] = [UIImage imageNamed:modeBean.iconName];
                item[@"iconColor"] = UIColorFromRGB(modeBean.iconColor);
                item[@"cellType"] = kMenuSimpleCell;
            }
            else if ([currentItem isKindOfClass:OAQuickAction.class])
            {
                OAQuickAction *action = (OAQuickAction *)currentItem;
                item[@"label"] = [action getName];
                item[@"icon"] = [UIImage imageNamed:[action getIconResName]];
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
            }
            else if ([currentItem isKindOfClass:OAPOIUIFilter.class])
            {
                OAPOIUIFilter *filter = (OAPOIUIFilter *)currentItem;
                item[@"label"] = [filter getName];
                NSString *iconRes = [filter getIconId];
                item[@"icon"] = [UIImage imageNamed: (![iconRes isEqualToString:@"0"] ? iconRes : @"ic_custom_user")]; // check this
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
            }
            else if ([currentItem isKindOfClass:NSDictionary.class])
            {
                NSString *caption = currentItem[@"name"];
                item[@"label"] = caption;
                item[@"icon"] = [UIImage imageNamed:@"ic_custom_map"];
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
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
                    item[@"icon"] = [UIImage imageNamed:@"ic_action_route_distance"];
                }
                else if ([file hasSuffix:GPX_FILE_EXT])
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
                item[@"iconColor"] = UIColorFromRGB(color_tint_gray);
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
            }
            else if ([currentItem isKindOfClass:OAAvoidRoadInfo.class])
            {
                item[@"label"] = ((OAAvoidRoadInfo *)currentItem).name;
                item[@"icon"] = [UIImage imageNamed:@"ic_custom_alert"];
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
            }
            else if ([currentItem isKindOfClass:OAFavoriteGroup.class])
            {
                OAFavoriteGroup *group = (OAFavoriteGroup *)currentItem;
                item[@"label"] = [OAFavoriteGroup getDisplayName:group.name];
                item[@"icon"] = [UIImage imageNamed:@"ic_custom_favorites"];
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
            }
            else if ([currentItem isKindOfClass:OADestination.class])
            {
                OADestination *marker = (OADestination *)currentItem;
                item[@"label"] = marker.desc;
                item[@"icon"] = [UIImage imageNamed:@"ic_custom_marker"];
                item[@"description"] = @"";
                item[@"cellType"] = kTitleTwoIconsRoundCell;
            }
            NSDictionary *newDict = [NSDictionary dictionaryWithDictionary:item];
            [sectionData addObject:newDict];
        }
        [result addObject:sectionData];
    }
    _data = [NSArray arrayWithArray:result];
}

- (void) applyLocalization
{
    _title = OALocalizedString(@"shared_string_importing");
    _description = [NSString stringWithFormat:OALocalizedString(@"importing_from"), _file];
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"import_duplicates_title");
}

- (void) setupBottomViewMultyLabelButtons
{
    self.primaryBottomButton.hidden = NO;
    self.secondaryBottomButton.hidden = NO;
    
    NSDictionary *secondaryButtonParams = @{
        @"firstLabelText": OALocalizedString(@"keep_both"),
        @"firstLabelColor": UIColorFromRGB(color_primary_purple),
        @"secondLabelText": OALocalizedString(@"keep_both_desc"),
        @"secondLabelColor": UIColorFromRGB(color_icon_inactive)
    };
    
    NSDictionary *primaryButtonParams = @{
        @"firstLabelText": OALocalizedString(@"replace_all"),
        @"firstLabelColor": [UIColor whiteColor],
        @"secondLabelText": OALocalizedString(@"replace_all_desc"),
        @"secondLabelColor": [[UIColor whiteColor] colorWithAlphaComponent:0.5]
    };
    
    [self setParams:secondaryButtonParams forTwoLabelButton:self.secondaryBottomButton];
    [self setParams:primaryButtonParams forTwoLabelButton:self.primaryBottomButton];
}

- (void) importItems:(BOOL)shouldReplace
{
    if (_settingsItems && _file)
    {
        [self setupImportingUI];
        for (OASettingsItem *item in _settingsItems)
        {
            [item setShouldReplace:shouldReplace];
        }
        [_settingsHelper importSettings:_file items:_settingsItems latestChanges:@"" version:1 delegate:self];
    }
}

- (IBAction)backImageButtonPressed:(id)sender
{
    OASettingsHelper.sharedInstance.importTask = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backButtonPressed:(id)sender
{
    OASettingsHelper.sharedInstance.importTask = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions

- (IBAction)primaryButtonPressed:(id)sender
{
    [self importItems: YES];
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    [self importItems: NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"cellType"];

    if ([type isEqualToString:kMenuSimpleCellNoIcon])
    {
        static NSString* const identifierCell = kMenuSimpleCellNoIcon;
        OAMenuSimpleCellNoIcon* cell;
        cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCellNoIcon owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
        }
        cell.descriptionView.hidden = NO;
        cell.textView.text = item[@"label"];
        cell.descriptionView.text = item[@"description"];
        return cell;
    }
    else if ([type isEqualToString:kMenuSimpleCell])
    {
        static NSString* const identifierCell = kMenuSimpleCell;
        OAMenuSimpleCell* cell;
        cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCell owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62., 0.0, 0.0);
        }
        cell.textView.text = item[@"label"];
        
        if (!item[@"description"] || ((NSString *)item[@"description"]).length > 0)
        {
            cell.descriptionView.hidden = NO;
            cell.descriptionView.text = item[@"description"];
        }
        else
        {
            cell.descriptionView.hidden = YES;
        }

        if (item[@"icon"] && item[@"iconColor"])
        {
            cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = item[@"iconColor"];
        }
        else if (item[@"icon"])
        {
            cell.imgView.image = item[@"icon"];
        }
        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
        return cell;
    }
    else if ([type isEqualToString:kTitleTwoIconsRoundCell])
    {
        static NSString* const identifierCell = kTitleTwoIconsRoundCell;
        OATitleTwoIconsRoundCell* cell;
        cell = (OATitleTwoIconsRoundCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleTwoIconsRoundCell owner:self options:nil];
            cell = (OATitleTwoIconsRoundCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62., 0.0, 0.0);
            cell.rightIconView.hidden = YES;
            cell.leftIconView.hidden = NO;
        }
        cell.titleView.text = item[@"label"];
        if (item[@"icon"] && item[@"iconColor"])
        {
            cell.leftIconView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.tintColor = item[@"iconColor"];
        }
        else if (item[@"icon"])
        {
            cell.leftIconView.image = item[@"icon"];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeWithActivity])
    {
        static NSString* const identifierCell = kCellTypeWithActivity;
        OAActivityViewWithTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
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

#pragma mark - UITableViewDelegate

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getHeaderForTableView:tableView withFirstSectionText:(NSString *)OALocalizedString(@"import_duplicates_description") boldFragment:nil forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:OALocalizedString(@"import_duplicates_description") boldFragment:nil inSection:section];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[_settingsHelper.importTask getSettingsToOperate:items importComplete:YES] fileName:[_file lastPathComponent]];
        [self.navigationController pushViewController:importCompleteVC animated:YES];
        _settingsHelper.importTask = nil;
    }
    [NSFileManager.defaultManager removeItemAtPath:_file error:nil];
}

- (void)onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items {
    
}


- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items {
    
}


- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed {
    
}

@end
