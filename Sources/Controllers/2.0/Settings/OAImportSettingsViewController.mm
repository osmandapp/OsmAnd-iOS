//
//  OAImportProfileViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportSettingsViewController.h"
#import "OAImportDuplicatesViewController.h"
#import "OAImportCompleteViewController.h"
#import "OAAppSettings.h"
#import "OASettingsImporter.h"
#import "OsmAndApp.h"
#import "OAQuickActionType.h"
#import "OAQuickAction.h"
#import "OAPOIUIFilter.h"
#import "OAMapSource.h"
#import "OAResourcesUIHelper.h"
#import "OAAvoidRoadInfo.h"
#import "OACustomSelectionCollapsableCell.h"
#import "OAExportSettingsType.h"
#import "OAMenuSimpleCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAActivityViewWithTitleCell.h"
#import "OAProfileDataObject.h"
#import "OAAvoidRoadInfo.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesUIHelper.h"
#import "OAOsmNotePoint.h"
#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAProfileSettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OAQuickActionsSettingsItem.h"
#import "OAPoiUiFilterSettingsItem.h"
#import "OAMapSourcesSettingsItem.h"
#import "OAAvoidRoadsSettingsItem.h"
#import "OAFileNameTranslationHelper.h"
#import "OAFavoritesSettingsItem.h"
#import "OAFavoritesHelper.h"
#import "OAOsmEditingPlugin.h"
#import "OAMarkersSettingsItem.h"
#import "OASettingsCategoryItems.h"
#import "OAExportSettingsCategory.h"
#import "OADestination.h"
#import "OAGpxSettingsItem.h"
#import "OAGPXDatabase.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6
#define kBottomPadding 32
#define kCellTypeWithActivity @"OAActivityViewWithTitleCell"
#define kCellTypeSectionHeader @"OACustomSelectionCollapsableCell"
#define kCellTypeTitleDescription @"OAMenuSimpleCell"
#define kCellTypeTitle @"OAIconTextCell"

@interface OATableGroupToImport : NSObject
    @property NSString* type;
    @property BOOL isOpen;
    @property NSString* groupName;
    @property NSMutableArray* groupItems;
@end

@implementation OATableGroupToImport

-(instancetype) init
{
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OAImportSettingsViewController () <UITableViewDelegate, UITableViewDataSource, OASettingsImportExportDelegate>

@end

@implementation OAImportSettingsViewController
{
    OASettingsHelper *_settingsHelper;
    NSArray<OATableGroupToImport *> *_data;
    NSArray<OASettingsItem *> *_settingsItems;
    NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *_itemsMap;
    NSArray<OAExportSettingsCategory *> *_itemTypes;
    NSMutableDictionary<OAExportSettingsType *, NSArray *> *_selectedItemsMap;
//    NSMutableArray<NSIndexPath *> *_selectedIndexPaths;
    NSString *_file;
    NSString *_descriptionText;
    NSString *_descriptionBoldText;
    CGFloat _heightForHeader;
}

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settingsHelper = OASettingsHelper.sharedInstance;
        _settingsItems = [NSArray arrayWithArray:items];
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.additionalNavBarButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [self.primaryBottomButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (void) updateNavigationBarItem
{
    [self.additionalNavBarButton setTitle:_selectedItemsMap.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all") forState:UIControlStateNormal];
}

- (void) setupButtonView
{
    self.primaryBottomButton.backgroundColor = UIColorFromRGB(color_primary_purple);
    [self.primaryBottomButton setTintColor:UIColor.whiteColor];
    [self.primaryBottomButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    _descriptionText = OALocalizedString(@"import_profile_select_descr");
    _descriptionBoldText = nil;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self.additionalNavBarButton addTarget:self action:@selector(selectDeselectAllItems:) forControlEvents:UIControlEventTouchUpInside];
    self.secondaryBottomButton.hidden = YES;
    [self setupButtonView];
    self.backImageButton.hidden = YES;
    _selectedItemsMap = [[NSMutableDictionary alloc] init];
    [self setTableHeaderView:OALocalizedString(@"shared_string_import")];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
    [self.tableView setEditing:YES];
    self.bottomBarView.hidden = NO;
}

- (void) setupView
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    if (importTask)
    {
        if (!_settingsItems)
            _settingsItems = [NSArray arrayWithArray:[importTask getItems]];
        if (!_file)
            _file = importTask.getFile;
        
        NSArray *duplicates = [importTask getDuplicates];
        NSArray *selectedItems = [importTask getSelectedItems];
        
        if (!duplicates)
        {
            importTask.delegate = self;
        }
        else if (duplicates.count == 0)
        {
            if (selectedItems && _file)
                [_settingsHelper importSettings:_file items:selectedItems latestChanges:@"" version:1 delegate:self];
        }
    }
    
    if (_settingsItems)
    {
        _itemsMap = [OASettingsHelper getSettingsToOperateByCategory:_settingsItems importComplete:NO];
        _itemTypes = _itemsMap.allKeys;
        [self generateData];
    }
    
    [self setTableHeaderView:OALocalizedString(@"shared_string_import")];
    
    EOAImportType importTaskType = [importTask getImportType];
    
    if (importTaskType == EOAImportTypeCheckDuplicates)
    {
        [self updateUI:OALocalizedString(@"shared_string_preparing") descriptionRes:OALocalizedString(@"checking_for_duplicate_description") activityLabel:OALocalizedString(@"checking_for_duplicates")];
    }
    else if (importTaskType == EOAImportTypeImport)
    {
        [self updateUI:OALocalizedString(@"shared_string_importing") descriptionRes:OALocalizedString(@"importing_from") activityLabel:OALocalizedString(@"shared_string_importing")];
    }
    else
        [self setTableHeaderView:OALocalizedString(@"shared_string_import")];
    
//    if (_itemsMap.count == 1 && [_itemsMap objectForKey:[OAExportSettingsType typeName:EOAExportSettingsTypeProfile]] && ![[_data objectAtIndex:0] isKindOfClass:NSDictionary.class])
//    {
//        OATableGroupToImport* groupData = [_data objectAtIndex:0];
//        groupData.isOpen = YES;
//    }
//
//    if (_itemsMap.count == 1 && [_itemsMap objectForKey:[OAExportSettingsType typeName:EOAExportSettingsTypeProfile]] && ![[_data objectAtIndex:0] isKindOfClass:NSDictionary.class])
//    {
//        OATableGroupToImport* groupData = [_data objectAtIndex:0];
//        groupData.isOpen = YES;
//    }
}

- (void) updateUI:(NSString *)toolbarTitleRes descriptionRes:(NSString *)descriptionRes activityLabel:(NSString *)activityLabel
{
    if (_file)
    {
        NSString *filename = [_file lastPathComponent];
        [self setTableHeaderView:toolbarTitleRes];
        _descriptionText = [NSString stringWithFormat:descriptionRes, filename];
        _descriptionBoldText = filename;
        self.bottomBarView.hidden = YES;
        [self showActivityIndicatorWithLabel:activityLabel];
        [self.tableView reloadData];
    }
}

- (NSInteger) getSelectedItemsAmount:(OAExportSettingsType *)type
{
    return _selectedItemsMap[type].count;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray array];
    for (OAExportSettingsCategory *type in _itemTypes)
    {
        OASettingsCategoryItems *categoryItems = _itemsMap[type];
        OATableGroupToImport *group = [[OATableGroupToImport alloc] init];
        group.groupName = type.title;
        group.type = kCellTypeSectionHeader;
        group.isOpen = NO;
        for (OAExportSettingsType *type in categoryItems.getTypes)
        {
            [group.groupItems addObject:@{
                @"icon" :  type.icon,
                @"title" : type.title,
                @"type" : kCellTypeTitleDescription
            }];
        }
        [data addObject:group];
    }
    
    _data = [NSArray arrayWithArray:data];
        
        
        //TODO: maybe reuse this code in the bottomsheet
        
//        NSArray *settings = [NSArray arrayWithArray:[_itemsMap objectForKey:type]];
//        switch (itemType)
//        {
//            case EOAExportSettingsTypeProfile:
//            {
//                profilesSection.groupName = OALocalizedString(@"shared_string_profiles");
//                profilesSection.type = kCellTypeSectionHeader;
//                profilesSection.isOpen = NO;
//                for (OAApplicationModeBean *modeBean in settings)
//                {
//                    NSString *title = modeBean.userProfileName;
//                    if (!title || title.length == 0)
//                    {
//                        OAApplicationMode* appMode = [OAApplicationMode valueOfStringKey:modeBean.stringKey def:nil];
//
//                        if (appMode)
//                            title = [appMode toHumanString];
//                        else
//                            title = modeBean.stringKey.capitalizedString;
//                    }
//
//                    NSString *routingProfile = @"";
//                    NSString *routingProfileValue = modeBean.routingProfile;
//                    if (routingProfileValue && routingProfileValue.length > 0)
//                    {
//                        try
//                        {
//                            routingProfile = [OARoutingProfileDataObject getLocalizedName: [OARoutingProfileDataObject getValueOf: [routingProfileValue upperCase]]];
//                            routingProfile = [NSString stringWithFormat: OALocalizedString(@"nav_type_hint"), [routingProfile capitalizedString]];
//
//                        } catch (NSException *e)
//                        {
//                            routingProfile = [routingProfileValue capitalizedString];
//                            NSLog(@"Error trying to get routing resource for %@ \n %@ %@", routingProfileValue, e.name, e.reason);
//                        }
//                    }
//
//                    [profilesSection.groupItems addObject:@{
//                        @"icon" :  [UIImage imageNamed:modeBean.iconName],
//                        @"color" : UIColorFromRGB(modeBean.iconColor),
//                        @"title" : title ? title : @"",
//                        @"description" : routingProfile,
//                        @"type" : kCellTypeTitleDescription,
//                    }];
//                }
//                [data addObject:profilesSection];
//                break;
//            }
//            case EOAExportSettingsTypeQuickActions:
//            {
//                quickActionsSection.groupName = OALocalizedString(@"shared_string_quick_actions");
//                quickActionsSection.type = kCellTypeSectionHeader;
//                quickActionsSection.isOpen = NO;
//                for (OAQuickAction *quickAction in [_itemsMap objectForKey:type])
//                {
//                    [quickActionsSection.groupItems addObject:@{
//                        @"icon" : [quickAction getIconResName],
//                        @"color" : UIColor.orangeColor,
//                        @"title" : quickAction.getName ? quickAction.getName : quickAction.actionType.name,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:quickActionsSection];
//                break;
//            }
//            case EOAExportSettingsTypePoiTypes:
//            {
//                poiTypesSection.groupName = OALocalizedString(@"poi_type");
//                poiTypesSection.type = kCellTypeSectionHeader;
//                poiTypesSection.isOpen = NO;
//
//                [data addObject:poiTypesSection];
//                break;
//            }
//            case EOAExportSettingsTypeMapSources:
//            {
//                mapSourcesSection.groupName = OALocalizedString(@"map_sources");
//                mapSourcesSection.type = kCellTypeSectionHeader;
//                mapSourcesSection.isOpen = NO;
//
//                for (NSDictionary *item in settings)
//                {
//                    NSString *caption = item[@"name"];
//                    [mapSourcesSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_map",
//                        @"title" : caption,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:mapSourcesSection];
//                break;
//            }
//            case EOAExportSettingsTypeCustomRendererStyles:
//            {
//                customRendererStyleSection.groupName = OALocalizedString(@"shared_string_rendering_style");
//                customRendererStyleSection.type = kCellTypeSectionHeader;
//                customRendererStyleSection.isOpen = NO;
//                for (NSString *rendererItem in settings)
//                {
//                    NSString *rendererName = [[[rendererItem lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
//                    [customRendererStyleSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_map_style",
//                        @"title" : [rendererName stringByDeletingPathExtension],
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:customRendererStyleSection];
//                break;
//            }
//            case EOAExportSettingsTypeMapFiles:
//            {
//                customObfMapSection.groupName = OALocalizedString(@"maps");
//                customObfMapSection.type = kCellTypeSectionHeader;
//                customObfMapSection.isOpen = NO;
//                for (OAFileSettingsItem *mapItem in settings)
//                {
//
//                    NSString *mapName = [OAFileNameTranslationHelper getMapName:mapItem.name];
//                    [customObfMapSection.groupItems addObject:@{
//                        @"icon" : mapItem.getIconName,
//                        @"title" : mapName,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:customObfMapSection];
//                break;
//            }
//            case EOAExportSettingsTypeCustomRouting:
//            {
//                customRoutingSection.groupName = OALocalizedString(@"shared_string_routing");
//                customRoutingSection.type = kCellTypeSectionHeader;
//                customRoutingSection.isOpen = NO;
//                for (NSString *routingItem in settings)
//                {
//                    NSString *routingName = [[[routingItem lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
//                    [customRoutingSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_route",
//                        @"title" : routingName,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:customRoutingSection];
//                break;
//            }
//            case EOAExportSettingsTypeGPX:
//            {
//                customGPXSection.groupName = OALocalizedString(@"tracks");
//                customGPXSection.type = kCellTypeSectionHeader;
//                customGPXSection.isOpen = NO;
//                for (OAGpxSettingsItem *gpxItem in settings)
//                {
//                    NSString *gpxName = [[gpxItem.name stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
//                    [customGPXSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_trip",
//                        @"title" : gpxName,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:customGPXSection];
//                break;
//            }
//            case EOAExportSettingsTypeAvoidRoads:
//            {
//                avoidRoadsStyleSection.groupName = OALocalizedString(@"impassable_road");
//                avoidRoadsStyleSection.type = kCellTypeSectionHeader;
//                avoidRoadsStyleSection.isOpen = NO;
//                for (OAAvoidRoadsSettingsItem *avoidRoads in settings)
//                {
//                    [avoidRoadsStyleSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_alert",
//                        @"title" : [avoidRoads name],
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:avoidRoadsStyleSection];
//                break;
//            }
//            case EOAExportSettingsTypeFavorites:
//            {
//                favoritesSection.groupName = OALocalizedString(@"my_places");
//                favoritesSection.type = kCellTypeSectionHeader;
//                favoritesSection.isOpen = NO;
//
//                for (OAFavoriteGroup *group in settings)
//                {
//                    NSString *groupName = [OAFavoriteGroup getDisplayName:group.name];
//                    NSString *groupDescription = [NSString stringWithFormat:@"%@ %ld", OALocalizedString(@"points_count"), group.points.count];
//                    UIImage *favoriteIcon = [UIImage imageNamed:@"ic_custom_folder"];
//                    [favoritesSection.groupItems addObject:@{
//                        @"icon" : favoriteIcon,
//                        @"color" : group.color,
//                        @"title" : groupName,
//                        @"description" : groupDescription,
//                        @"type" : kCellTypeTitleDescription,
//                    }];
//                }
//                [data addObject:favoritesSection];
//                break;
//            }
//            case EOAExportSettingsTypeOsmNotes:
//            {
//                notesPointStyleSection.groupName = OALocalizedString(@"osm_notes");
//                notesPointStyleSection.type = kCellTypeSectionHeader;
//                notesPointStyleSection.isOpen = NO;
//
//                for (OAOsmNotePoint *item in settings)
//                {
//                    NSString *caption = [item getText];
//                    [notesPointStyleSection.groupItems addObject:@{
//                        @"icon" : @"ic_action_add_osm_note",
//                        @"title" : caption,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:notesPointStyleSection];
//                break;
//            }
//            case EOAExportSettingsTypeOsmEdits:
//            {
//                editsPointStyleSection.groupName = OALocalizedString(@"osm_edits_title");
//                editsPointStyleSection.type = kCellTypeSectionHeader;
//                editsPointStyleSection.isOpen = NO;
//                for (OAOsmPoint *item in settings)
//                {
//                    NSString *caption = [OAOsmEditingPlugin getTitle:item];
//                    [editsPointStyleSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_poi",
//                        @"title" : caption,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//                [data addObject:editsPointStyleSection];
//                break;
//            }
//            case EOAExportSettingsTypeActiveMarkers:
//            {
//                activeMarkersStyleSection.groupName = OALocalizedString(@"map_markers");
//                activeMarkersStyleSection.type = kCellTypeSectionHeader;
//                activeMarkersStyleSection.isOpen = NO;
//                for (OADestination *item in settings)
//                {
//                    [activeMarkersStyleSection.groupItems addObject:@{
//                        @"icon" : @"ic_custom_marker",
//                        @"title" : item.desc,
//                        @"type" : kCellTypeTitle,
//                    }];
//                }
//
//                [data addObject:activeMarkersStyleSection];
//                break;
//            }
//            default:
//                break;
//        }
//    }
}

- (void) showActivityIndicatorWithLabel:(NSString *)labelText
{
    _data = [NSMutableArray arrayWithObject:
                 @{
                     @"cellType": kCellTypeWithActivity,
                     @"label": labelText
                 }];
    
    [self.tableView setEditing:NO];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView reloadData];
    self.bottomBarView.hidden =YES;
}

#pragma mark - Base settings items methods

- (OAProfileSettingsItem *) getBaseProfileSettingsItem:(OAApplicationModeBean *)modeBean
{
    for (OASettingsItem *settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeProfile)
        {
            OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *)settingsItem;
            OAApplicationModeBean *bean = [profileItem modeBean];
            if ([bean.stringKey isEqualToString:modeBean.stringKey] && [bean.userProfileName isEqualToString:modeBean.userProfileName])
                return profileItem;
        }
    }
    return nil;
}

- (OAQuickActionsSettingsItem *) getBaseQuickActionsSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeQuickActions)
            return (OAQuickActionsSettingsItem *)settingsItem;
    }
    return nil;
}
 
- (OAPoiUiFilterSettingsItem *) getBasePoiUiFiltersSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypePoiUIFilters)
            return (OAPoiUiFilterSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAMapSourcesSettingsItem *) getBaseMapSourcesSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeMapSources)
            return (OAMapSourcesSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAAvoidRoadsSettingsItem *) getBaseAvoidRoadsSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeAvoidRoads)
            return (OAAvoidRoadsSettingsItem *)settingsItem;
    }
    return nil;
}

//TODO: in Android it uses Generics
- (id) getBaseItem:(EOASettingsItemType)settingsItemType clazz:(id)clazz
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == settingsItemType && [settingsItem isKindOfClass:clazz])
            return settingsItem;
    }
    return nil;
}

- (NSArray <OASettingsItem *>*) getSettingsItemsFromData
{
//    NSMutableArray<OASettingsItem *> *settingsItems = [NSMutableArray array];
//    NSMutableArray<OAApplicationModeBean *> *appModeBeans = [NSMutableArray array];
//    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray array];
//    NSMutableArray<OAPOIUIFilter *> *poiUIFilters = [NSMutableArray array];
//    NSMutableArray<NSDictionary *> *tileSourceTemplates = [NSMutableArray array];
//    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
//    NSMutableArray<OAFavoriteGroup *> *favoiriteItems = [NSMutableArray array];
//    NSMutableArray<OAOsmNotePoint *> *osmNotesPointList = [NSMutableArray array];
//    NSMutableArray<OAOsmPoint *> *osmEditsPointList = [NSMutableArray array];
//    NSMutableArray<OADestination *> *activeMarkersList = [NSMutableArray array];
//
//    for (NSObject *object in _selectedItems)
//    {
//        if ([object isKindOfClass:OAApplicationModeBean.class])
//            [appModeBeans addObject:(OAApplicationModeBean *)object];
//        else if ([object isKindOfClass:OAQuickAction.class])
//            [quickActions addObject:(OAQuickAction *)object];
//        else if ([object isKindOfClass:OAPOIUIFilter.class])
//            [poiUIFilters addObject:(OAPOIUIFilter *)object];
//        else if ([object isKindOfClass:NSDictionary.class])
//            [tileSourceTemplates addObject:(NSDictionary *)object];
//        else if ([object isKindOfClass:NSString.class])
//            [settingsItems addObject:[[OAFileSettingsItem alloc] initWithFilePath:(NSString *)object error:nil]];
//        else if ([object isKindOfClass:OAAvoidRoadInfo.class])
//            [avoidRoads addObject:(OAAvoidRoadInfo *)object];
//        else if ([object isKindOfClass:OAOsmNotePoint.class])
//            [osmNotesPointList addObject:(OAOsmNotePoint *)object];
//        else if ([object isKindOfClass:OAOsmPoint.class])
//            [osmEditsPointList addObject:(OAOsmPoint *)object];
//        else if ([object isKindOfClass:OAFileSettingsItem.class])
//            [settingsItems addObject:(OAFileSettingsItem *)object];
//        else if ([object isKindOfClass:OAFavoriteGroup.class])
//            [favoiriteItems addObject:(OAFavoriteGroup *)object];
//        else if ([object isKindOfClass:OADestination.class])
//            [activeMarkersList addObject:(OADestination *)object];
//    }
//    if (appModeBeans.count > 0)
//        for (OAApplicationModeBean *modeBean in appModeBeans)
//            [settingsItems addObject:[self getBaseProfileSettingsItem:modeBean]];
//    if (quickActions.count > 0)
//        [settingsItems addObject: [[OAQuickActionsSettingsItem alloc] initWithItems:quickActions]];
//    if (poiUIFilters.count > 0)
//        [settingsItems addObject:[self getBasePoiUiFiltersSettingsItem]];
//    if (tileSourceTemplates.count > 0)
//        [settingsItems addObject:[[OAMapSourcesSettingsItem alloc] initWithItems:tileSourceTemplates]];
//    if (avoidRoads.count > 0)
//        [settingsItems addObject:[[OAAvoidRoadsSettingsItem alloc] initWithItems:avoidRoads]];
//    if (favoiriteItems.count > 0)
//        [settingsItems addObject:[[OAFavoritesSettingsItem alloc] initWithItems:favoiriteItems]];
//    if (osmNotesPointList.count > 0)
//    {
//        OAOsmNotesSettingsItem  *baseItem = [self getBaseItem:EOASettingsItemTypeOsmNotes clazz:OAOsmNotesSettingsItem.class];
//        [settingsItems addObject:baseItem];
//    }
//    if (osmEditsPointList.count > 0)
//    {
//        OAOsmNotesSettingsItem  *baseItem = [self getBaseItem:EOASettingsItemTypeOsmEdits clazz:OAOsmEditsSettingsItem.class];
//        [settingsItems addObject:baseItem];
//    }
//    if (activeMarkersList.count > 0)
//    {
//        [settingsItems addObject:[[OAMarkersSettingsItem alloc] initWithItems:activeMarkersList]];
//    }
//    return settingsItems;
}

#pragma mark - Actions

- (IBAction) primaryButtonPressed:(id)sender
{
    if (_selectedItemsMap.count == 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"shared_string_nothing_selected") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self importItems];
    }
}

- (IBAction) backButtonPressed:(id)sender
{
    [NSFileManager.defaultManager removeItemAtPath:_file error:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) importItems
{
    [self updateUI:OALocalizedString(@"shared_string_preparing") descriptionRes:OALocalizedString(@"checking_for_duplicate_description") activityLabel:OALocalizedString(@"checking_for_duplicates")];
    NSArray <OASettingsItem *> *selectedItems = [self getSettingsItemsFromData];
    
    if (_file && _settingsItems)
        [_settingsHelper checkDuplicates:_file items:_settingsItems selectedItems:selectedItems delegate:self];
}

- (void) selectDeselectAllItems:(id)sender
{
//    if (_selectedIndexPaths.count > 1)
//        for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++)
//            [self deselectAllGroup:[NSIndexPath indexPathForRow:0 inSection:section]];
//    else
//        for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++)
//            [self selectAllGroup:[NSIndexPath indexPathForRow:0 inSection:section]];
//    [self updateNavigationBarItem];
}

- (void) openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    
    [self openCloseGroup:indexPath];
}

- (void) onGroupCheckmarkPressed:(UIButton *)sender
{
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
//    NSArray<NSString *> *itemTypes = _itemsMap[_itemTypes[indexPath.section]];
//    NSInteger selectedAmount = [self getSelectedItemsAmount:itemTypes];
//
//    if (selectedAmount > 0)
//        [self deselectAllGroup:indexPath];
//    else
//        [self selectAllGroup:indexPath];
}

- (void) openCloseGroup:(NSIndexPath *)indexPath
{
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
//        if ([_selectedIndexPaths containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
//            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self selectPreselectedCells:indexPath];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        OATableGroupToImport* groupData = [_data objectAtIndex:section];
        if (groupData.isOpen)
            return [groupData.groupItems count] + 1;
        return 1;
}

- (UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (indexPath.row == 0)
    {
        static NSString* const identifierCell = @"OACustomSelectionCollapsableCell";
        OACustomSelectionCollapsableCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OACustomSelectionCollapsableCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.openCloseGroupButton.hidden = NO;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            OASettingsCategoryItems *itemTypes = _itemsMap[_itemTypes[indexPath.section]];
            NSInteger selectedAmount = [self getSelectedItemsAmount:nil];
            cell.textView.text = groupData.groupName;
            cell.descriptionView.text = [NSString stringWithFormat: OALocalizedString(@"selected_profiles"), selectedAmount, groupData.groupItems.count];
            if (selectedAmount == groupData.groupItems.count)
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            
            cell.selectionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.selectionButton addTarget:self action:@selector(onGroupCheckmarkPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            if (selectedAmount > 0)
            {
                UIImage *selectionImage = selectedAmount < itemTypes.getTypes.count ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
                [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
            }
            else
            {
                [cell.selectionButton setImage:nil forState:UIControlStateNormal];
            }
            
            if (groupData.isOpen)
            {
                cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_up"]
                                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_down"]
                                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                if ([cell isDirectionRTL])
                    [cell.iconView setImage:cell.iconView.image.imageFlippedForRightToLeftLayoutDirection];
            }
        }
        return cell;
    }
    else
    {
        NSInteger dataIndex = indexPath.row - 1;
        NSDictionary* item = [groupData.groupItems objectAtIndex:dataIndex];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kCellTypeTitleDescription])
        {
            static NSString* const identifierCell = kCellTypeTitleDescription;
            OAMenuSimpleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 70., 0., 0.);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            if (cell)
            {
                cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imgView.tintColor = item[@"color"];
                cell.textView.text = item[@"title"];
                OASettingsCategoryItems *items = _itemsMap[_itemTypes[indexPath.section]];
                OAExportSettingsType *settingType = items.getTypes[indexPath.row - 1];
                NSInteger selectedAmount = [self getSelectedItemsAmount:settingType];
                NSInteger itemsTotal = [items getItemsForType:settingType].count;
                NSString *selectedStr = selectedAmount == 0 ? OALocalizedString(@"sett_no_ext_input") : (selectedAmount == itemsTotal ? OALocalizedString(@"shared_string_all") : [NSString stringWithFormat:OALocalizedString(@"some_of"), selectedAmount, itemsTotal]);
                cell.descriptionView.text = selectedStr;
            }
            return cell;
        }
        else if ([cellType isEqualToString:kCellTypeTitle])
        {
            
            static NSString* const identifierCell = kCellTypeTitle;
            OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.arrowIconView.hidden = YES;
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.iconView.tintColor = item[@"color"] ? item[@"color"] : UIColorFromRGB(color_tint_gray);
            }
            return cell;
        }
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getHeaderForTableView:tableView withFirstSectionText:_descriptionText boldFragment:_descriptionBoldText forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:_descriptionText boldFragment:_descriptionBoldText inSection:section];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self selectAllGroup:indexPath];
    else
        [self selectGroupItem:indexPath];
    [self updateNavigationBarItem];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self deselectAllGroup:indexPath];
    else
        [self deselectGroupItem:indexPath];
    [self updateNavigationBarItem];
}

- (void) selectAllItemsInGroup:(NSIndexPath *)indexPath selectHeader:(BOOL)selectHeader
{
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:indexPath.section];
    
    [self.tableView beginUpdates];
    if (selectHeader)
        for (int i = 0; i < rowsCount; i++)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
    else
        for (int i = 0; i < rowsCount; i++)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES];
        }
    [self.tableView endUpdates];
}

- (void) selectAllGroup:(NSIndexPath *)indexPath
{
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (!groupData.isOpen)
        for (NSInteger i = 0; i <= groupData.groupItems.count; i++)
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    [self selectAllItemsInGroup:indexPath selectHeader:YES];
}

- (void) deselectAllGroup:(NSIndexPath *)indexPath
{
//    NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:_selectedIndexPaths];
//    for (NSUInteger i = 0; i < tmp.count; i++)
//        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
//    [self selectAllItemsInGroup:indexPath selectHeader: NO];
}

- (void) selectGroupItem:(NSIndexPath *)indexPath
{
    BOOL isGroupHeaderSelected = [self.tableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    NSInteger numberOfRowsInSection = [self.tableView numberOfRowsInSection:indexPath.section] - 1;
    NSInteger numberOfSelectedRowsInSection = 0;
    for (NSIndexPath *item in selectedRows)
    {
        if(item.section == indexPath.section)
            numberOfSelectedRowsInSection++;
        [self addIndexPathToSelectedCellsArray:item];
    }
    if (numberOfSelectedRowsInSection == numberOfRowsInSection && !isGroupHeaderSelected)
    {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    }
    return;
}

- (void) deselectGroupItem:(NSIndexPath *)indexPath
{
    BOOL isGroupHeaderSelected = [self.tableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    NSInteger numberOfRowsInSection = [self.tableView numberOfRowsInSection:indexPath.section] - 1;
    NSInteger numberOfSelectedRowsInSection = 0;
    for (NSIndexPath *item in selectedRows)
    {
        if(item.section == indexPath.section)
            numberOfSelectedRowsInSection++;
    }
    [self removeIndexPathFromSelectedCellsArray:indexPath];
    
    if (indexPath.row == 0)
    {
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
    else if (numberOfSelectedRowsInSection == numberOfRowsInSection && isGroupHeaderSelected)
    {
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
    return;
}

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
//    NSArray* objects = [NSArray arrayWithArray:[_itemsMap objectForKey:_itemTypes[indexPath.section]]];
//    if (![_selectedIndexPaths containsObject:indexPath])
//    {
//        [_selectedIndexPaths addObject:indexPath];
//        if (indexPath.row != 0)
//            [_selectedItems addObject:objects[indexPath.row - 1]];
//        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationNone];
//    }
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
//    NSArray* objects = [NSArray arrayWithArray:[_itemsMap objectForKey:_itemsType[indexPath.section]]];
//    if ([_selectedIndexPaths containsObject:indexPath])
//    {
//        [_selectedIndexPaths removeObject:indexPath];
//        if (indexPath.row != 0)
//            [_selectedItems removeObject:objects[indexPath.row - 1]];
//        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationNone];
//    }
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
//    for (NSIndexPath *itemPath in _selectedIndexPaths)
//        if (itemPath.section == indexPath.section)
//            [self.tableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - OASettingsImportExportDelegate

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        [self.tableView reloadData];
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[OASettingsHelper getSettingsToOperate:items importComplete:YES] fileName:[_file lastPathComponent]];
        [self.navigationController pushViewController:importCompleteVC animated:YES];
        _settingsHelper.importTask = nil;
    }
    [NSFileManager.defaultManager removeItemAtPath:_file error:nil];
}

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    [self processDuplicates:duplicates items:items];
}

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
    
}

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
    
}

- (void) processDuplicates:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    if (_file)
    {
        if (duplicates.count == 0)
        {
            [self updateUI:OALocalizedString(@"shared_string_importing") descriptionRes:OALocalizedString(@"importing_from") activityLabel:OALocalizedString(@"shared_string_importing")];
            [_settingsHelper importSettings:_file items:items latestChanges:@"" version:1 delegate:self];
        }
        else
        {
            OAImportDuplicatesViewController *dublicatesVC = [[OAImportDuplicatesViewController alloc] initWithDuplicatesList:duplicates settingsItems:items file:_file];
            [self.navigationController pushViewController:dublicatesVC animated:YES];
        }
    }
}

@end
