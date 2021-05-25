//
//  OAMapSettingsMapTypeScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsMapTypeScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OAMapStyleTitles.h"
#import "OAMapCreatorHelper.h"
#include "Localization.h"
#import "Reachability.h"
#import "OAResourcesUIHelper.h"

#include <QSet>

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#import "OAIAPHelper.h"

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;


@implementation OAMapSettingsMapTypeScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSMutableArray* _offlineMapSources;
    NSArray* _onlineMapSources;
    NSDictionary *stylesTitlesOffline;
}

#define kOfflineSourcesSection 0
#define kOnlineSourcesSection 1

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        title = OALocalizedString(@"map_settings_type");

        settingsScreen = EMapSettingsScreenMapType;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
    _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                 [self]
                                                                 (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                  const QList< QString >& added,
                                                                  const QList< QString >& removed,
                                                                  const QList< QString >& updated)
                                                                 {
                                                                     [self onLocalResourcesChanged];
                                                                 });
    
    _offlineMapSources = [NSMutableArray array];
    _onlineMapSources = [NSMutableArray array];
}

- (void) deinit
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);
}

- (void) setupView
{
    [_offlineMapSources removeAllObjects];
    _onlineMapSources = [OAResourcesUIHelper getSortedRasterMapSources:YES];
    
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    
    const auto localResources = _app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAndResourceType::MapStyle)
            mapStylesResources.push_back(localResource);
    }
    
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode;
    
    // Process map styles
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        
        NSString* resourceId = resource->id.toNSString();
        
        OAMapStyleResourceItem* item = [[OAMapStyleResourceItem alloc] init];
        item.mapSource = [_app.data lastMapSourceByResourceId:resourceId];
        if (item.mapSource == nil)
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:mode.variantKey];
        
        NSString *caption = mapStyle->title.toNSString();
        OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
        if ([caption isEqualToString:@"Ski-map"] && ![iapHelper.skiMap isActive])
            continue;
        if ([caption isEqualToString:@"nautical"] && ![iapHelper.nautical isActive])
            continue;
        
        NSString *newCaption = [stylesTitlesOffline objectForKey:caption];
        if (newCaption)
            caption = newCaption;
        
        item.mapSource.name = caption;
        item.resourceType = OsmAndResourceType::MapStyle;
        item.resource = resource;
        item.mapStyle = mapStyle;

        item.sortIndex = [OAMapStyleTitles getSortIndexForTitle:item.mapStyle->title.toNSString()];
        [_offlineMapSources addObject:item];
    }

    NSArray *arr = [_offlineMapSources sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleResourceItem* obj1, OAMapStyleResourceItem* obj2) {
        if (obj1.sortIndex < obj2.sortIndex)
            return NSOrderedAscending;
        if (obj1.sortIndex > obj2.sortIndex)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    [_offlineMapSources setArray:arr];
}


- (void) initData
{
    stylesTitlesOffline = [OAMapStyleTitles getMapStyleTitles];
    
}

- (void) onLocalResourcesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded)
            return;
        [self setupView];
        [tblView reloadData];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2 /* Offline section, Online section */;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kOfflineSourcesSection:
            return [_offlineMapSources count];
        case kOnlineSourcesSection:
            return [_onlineMapSources count] + 1;
            
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kOfflineSourcesSection:
            return OALocalizedString(@"map_settings_offline");
        case kOnlineSourcesSection:
            return OALocalizedString(@"map_settings_online");
            
        default:
            return nil;
    }
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const mapSourceItemCell = @"mapSourceItemCell";
    
    // Get content for cell and it's type id
    NSArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSources : _onlineMapSources;
    NSString* caption = nil;
    NSString* description = nil;
    OAResourceItem* someItem;
    
    if (indexPath.row < collection.count)
    {
        someItem = [collection objectAtIndex:indexPath.row];
        if ([someItem isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *sqlite = (OASqliteDbResourceItem *) someItem;
            caption = sqlite.mapSource.name;
            description = nil;
        }
        else if (someItem.resourceType == OsmAndResourceType::MapStyle)
        {
            OAMapStyleResourceItem* item = (OAMapStyleResourceItem*)someItem;
            
            caption = item.mapSource.name;
            description = nil;
        }
        else if ([someItem isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem* item = (OAOnlineTilesResourceItem*)someItem;
            caption = item.mapSource.name;
            description = nil;
        }
    }
    else
    {
        caption = OALocalizedString(@"map_settings_install_more");
    }
    
    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:mapSourceItemCell];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:mapSourceItemCell];
        
    // Fill cell content
    cell.textLabel.text = caption;
    cell.detailTextLabel.text = description;
    
    OAMapSourceResourceItem *itm = nil;
    if (someItem && [someItem isKindOfClass:OAMapSourceResourceItem.class])
        itm = (OAMapSourceResourceItem *) someItem;

    if (itm && [_app.data.lastMapSource isEqual:itm.mapSource])
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
    else
        cell.accessoryView = nil;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSources : _onlineMapSources;
        if (indexPath.row < collection.count)
        {
            OAResourceItem* item = [collection objectAtIndex:indexPath.row];
            OAMapSourceResourceItem *source = nil;
            if ([item isKindOfClass:OAMapSourceResourceItem.class])
                source = (OAMapSourceResourceItem *) item;
            _app.data.lastMapSource = source.mapSource;
            if (indexPath.section == kOfflineSourcesSection)
                [_app.data setPrevOfflineSource:source.mapSource];
            
            [tableView reloadData];
        }
        else
        {
            if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            {
                OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOnlineSources];
                [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            }
            else
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_upload_no_internet") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                [self.vwController presentViewController:alert animated:YES completion:nil];
            }
        }
    });
}



@end
