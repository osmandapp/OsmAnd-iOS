//
//  OAMapSourcesListViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcesListViewController.h"

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#include "Localization.h"

#include <QSet>

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/MapStyle.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define _(name) OAMapSourcesListViewController__##name

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@end
@implementation Item
@end

#define Item_MapStyle _(Item_MapStyle)
@interface Item_MapStyle : Item
@property std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
@end
@implementation Item_MapStyle
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : Item
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAMapSourcesListViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapSourcesListViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _lastMapSourceChangeObserver;

    NSMutableArray* _offlineMapSources;
    NSMutableArray* _onlineMapSources;
}

#define kOfflineSourcesSection 0
#define kOnlineSourcesSection 1

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _app = [OsmAndApp instance];

    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onLastMapSourceChanged)
                                                            andObserve:_app.data.lastMapSourceChangeObservable];

    _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                 [self]
                                                                 (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                  const QList< QString >& added,
                                                                  const QList< QString >& removed,
                                                                  const QList< QString >& updated)
                                                                 {
                                                                     [self onLocalResourcesChanged];
                                                                 });

    _offlineMapSources = [[NSMutableArray alloc] init];
    _onlineMapSources = [[NSMutableArray alloc] init];
}

- (void)dtor
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Obtain initial map sources
    [self obtainMapSources];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Perform selection of proper preset
    [self selectMapSource:animated];
}

- (void)obtainMapSources
{
    [_offlineMapSources removeAllObjects];
    [_onlineMapSources removeAllObjects];

    // Collect all needed resources
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;

    const auto builtinResources = _app.resourcesManager->getBuiltInResources();
    for(const auto& builtinResource : builtinResources)
    {
        if (builtinResource->type == OsmAndResourceType::MapStyle)
            mapStylesResources.push_back(builtinResource);
        else if (builtinResource->type == OsmAndResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(builtinResource);
    }

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
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                    andVariant:onlineTileSource->name.toNSString()];
            item.resource = resource;
            item.onlineTileSource = onlineTileSource;

            [_onlineMapSources addObject:item];
        }
    }

    // Process map styles
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;

        NSString* resourceId = resource->id.toNSString();

        Item_MapStyle* item = [[Item_MapStyle alloc] init];
        item.mapSource = [_app.data lastMapSourceByResourceId:resourceId];
        if (item.mapSource == nil)
        {
            const auto presetsForMapStyle = _app.resourcesManager->mapStylesPresetsCollection->getCollectionFor(mapStyle->name);
            const auto itFirstFoundPreset = presetsForMapStyle.begin();
            NSString* variant = (itFirstFoundPreset == presetsForMapStyle.cend()) ? nil : (*itFirstFoundPreset)->name.toNSString();
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:variant];
        }
        item.resource = resource;
        item.mapStyle = mapStyle;

        [_offlineMapSources addObject:item];
    }
}

- (void)selectMapSource:(BOOL)animated
{
    if (!self.isViewLoaded)
        return;

    __block NSIndexPath* newSelected = nil;
    if (newSelected == nil)
    {
        [_offlineMapSources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Item* item = (Item*)obj;
            if (![_app.data.lastMapSource isEqual:item.mapSource])
                return;

            newSelected = [NSIndexPath indexPathForRow:idx
                                             inSection:kOfflineSourcesSection];
            *stop = YES;
        }];
    }
    if (newSelected == nil)
    {
        [_onlineMapSources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Item* item = (Item*)obj;
            if (![_app.data.lastMapSource isEqual:item.mapSource])
                return;

            newSelected = [NSIndexPath indexPathForRow:idx
                                             inSection:kOnlineSourcesSection];
            *stop = YES;
        }];
    }

    NSIndexPath* currentSelected = [self.tableView indexPathForSelectedRow];
    if (currentSelected != nil)
    {
        if ([currentSelected isEqual:newSelected])
            return;
        [self.tableView deselectRowAtIndexPath:currentSelected animated:YES];
    };

    if (newSelected != nil)
    {
        [self.tableView selectRowAtIndexPath:newSelected
                                    animated:animated
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectMapSource:YES];
    });
}

- (void)onLocalResourcesChanged
{
    [self obtainMapSources];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;
        [self.tableView reloadData];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2 /* Offline section, Online section */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kOfflineSourcesSection:
            return [_offlineMapSources count];
        case kOnlineSourcesSection:
            return [_onlineMapSources count];

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kOfflineSourcesSection:
            return OALocalizedString(@"Offline maps");
        case kOnlineSourcesSection:
            return OALocalizedString(@"Online maps");

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const mapSourceItemCell = @"mapSourceItemCell";

    // Get content for cell and it's type id
    NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSources : _onlineMapSources;
    NSString* caption = nil;
    NSString* description = nil;

    Item* someItem = [collection objectAtIndex:indexPath.row];
    if (someItem.resource->type == OsmAndResourceType::MapStyle)
    {
        Item_MapStyle* item = (Item_MapStyle*)someItem;

        caption = item.mapStyle->title.toNSString();
        description = nil;
#if defined(DEBUG)
        description = item.mapSource.variant;
#endif
    }
    else if (someItem.resource->type == OsmAndResourceType::OnlineTileSources)
    {
        Item_OnlineTileSource* item = (Item_OnlineTileSource*)someItem;

        caption = item.onlineTileSource->name.toNSString();
        description = nil;
#if defined(DEBUG)
        description = item.resource->id.toNSString();
#endif
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:mapSourceItemCell];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:mapSourceItemCell];

    // Fill cell content
    cell.textLabel.text = caption;
    cell.detailTextLabel.text = description;

    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect any currently selected (if not the same)
    NSIndexPath* currentlySelected = [tableView indexPathForSelectedRow];
    if (currentlySelected != nil)
    {
        if ([currentlySelected isEqual:indexPath])
            return indexPath;
        [tableView deselectRowAtIndexPath:currentlySelected animated:YES];
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSources : _onlineMapSources;
    Item* item = [collection objectAtIndex:indexPath.row];
    _app.data.lastMapSource = item.mapSource;

    // For iPhone/iPod, since this menu wasn't opened in popover, return
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disallow manual deselection of any map source
    return nil;
}

#pragma mark -

@end
