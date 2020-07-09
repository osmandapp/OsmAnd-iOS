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
#import "OASQLiteTileSource.h"

#include <QSet>

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#import "OAIAPHelper.h"

#define _(name) OAMapSourcesViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@end
@implementation Item
@end

#define Item_MapStyle _(Item_MapStyle)
@interface Item_MapStyle : Item
@property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@property int sortIndex;
@end
@implementation Item_MapStyle
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : Item
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

#define Item_SqliteDbTileSource _(Item_SqliteDbTileSource)
@interface Item_SqliteDbTileSource : Item
@end
@implementation Item_SqliteDbTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;


@implementation OAMapSettingsMapTypeScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSMutableArray* _offlineMapSources;
    NSMutableArray* _onlineMapSources;
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
    [_onlineMapSources removeAllObjects];
    
    // Collect all needed resources
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;
    
    const auto localResources = _app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAndResourceType::MapStyle)
            mapStylesResources.push_back(localResource);
        else if (localResource->type == OsmAndResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(localResource);
    }
    
    // Process online tile sources resources
    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();
        
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
            
            NSString *caption = onlineTileSource->name.toNSString();
            
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:onlineTileSource->name.toNSString() name:caption];
            item.resource = resource;
            item.onlineTileSource = onlineTileSource;
            
            [_onlineMapSources addObject:item];
        }
    }
    
    
    NSArray *arr = [_onlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_OnlineTileSource* obj1, Item_OnlineTileSource* obj2) {
        NSString *caption1 = obj1.onlineTileSource->name.toNSString();
        NSString *caption2 = obj2.onlineTileSource->name.toNSString();
        return [caption2 compare:caption1];
    }];
    
    [_onlineMapSources setArray:arr];
    
    NSMutableArray *sqlitedbArr = [NSMutableArray array];
    for (NSString *fileName in [OAMapCreatorHelper sharedInstance].files.allKeys)
    {
        NSString *filePath = [OAMapCreatorHelper sharedInstance].files[fileName];
        NSString *label = [OASQLiteTileSource getLabelFor:filePath];
        Item_SqliteDbTileSource* item = [[Item_SqliteDbTileSource alloc] init];
        item.mapSource = [[OAMapSource alloc] initWithResource:fileName andVariant:@"" name:@"sqlitedb" optionalLabel:label];
        [sqlitedbArr addObject:item];
    }

    [sqlitedbArr sortUsingComparator:^NSComparisonResult(Item_SqliteDbTileSource *obj1, Item_SqliteDbTileSource *obj2) {
        return [obj1.mapSource.resourceId caseInsensitiveCompare:obj2.mapSource.resourceId];
    }];

    [_onlineMapSources addObjectsFromArray:sqlitedbArr];
    
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode;
    
    // Process map styles
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        
        NSString* resourceId = resource->id.toNSString();
        
        Item_MapStyle* item = [[Item_MapStyle alloc] init];
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
        
        item.resource = resource;
        item.mapStyle = mapStyle;

        item.sortIndex = [OAMapStyleTitles getSortIndexForTitle:item.mapStyle->title.toNSString()];
        [_offlineMapSources addObject:item];
    }

    arr = [_offlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_MapStyle* obj1, Item_MapStyle* obj2) {
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
    NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSources : _onlineMapSources;
    NSString* caption = nil;
    NSString* description = nil;
    Item* someItem;
    
    if (indexPath.row < collection.count)
    {
        someItem = [collection objectAtIndex:indexPath.row];
        if ([someItem isKindOfClass:Item_SqliteDbTileSource.class])
        {
            if (someItem.mapSource.optionalLabel.length > 0)
                caption = someItem.mapSource.optionalLabel;
            else
                caption = [[someItem.mapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            
            description = nil;
        }
        else if (someItem.resource->type == OsmAndResourceType::MapStyle)
        {
            Item_MapStyle* item = (Item_MapStyle*)someItem;
            
            caption = item.mapSource.name;
            description = nil;
#if defined(OSMAND_IOS_DEV)
            description = item.mapSource.variant;
#endif // defined(OSMAND_IOS_DEV)
        }
        else if (someItem.resource->type == OsmAndResourceType::OnlineTileSources)
        {
            Item_OnlineTileSource* item = (Item_OnlineTileSource*)someItem;
            
            caption = item.mapSource.name;
            description = nil;
#if defined(OSMAND_IOS_DEV)
            description = item.resource->id.toNSString();
#endif // defined(OSMAND_IOS_DEV)
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

    if (someItem && [_app.data.lastMapSource isEqual:someItem.mapSource]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
    } else {
        cell.accessoryView = nil;
    }
    
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
        
        NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSources : _onlineMapSources;
        if (indexPath.row < collection.count)
        {
            Item* item = [collection objectAtIndex:indexPath.row];
            _app.data.lastMapSource = item.mapSource;
            if (indexPath.section == kOfflineSourcesSection)
                [_app.data setPrevOfflineSource:item.mapSource];
            
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
