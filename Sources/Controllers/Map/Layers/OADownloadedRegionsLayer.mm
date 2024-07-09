//
//  OADownloadedRegionsLayer.m
//  OsmAnd
//
//  Created by Alexey on 24.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADownloadedRegionsLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAColors.h"
#import "OAPointIContainer.h"
#import "OAAutoObserverProxy.h"
#import "OAResourcesUIHelper.h"
#import "OADownloadsManager.h"
#import "OAManageResourcesViewController.h"
#import "OAWeatherToolbar.h"
#import "OAAppSettings.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/Polygon.h>
#include <OsmAndCore/Map/PolygonBuilder.h>
#include <OsmAndCore/Map/PolygonsCollection.h>
#include <OsmAndCore/WorldRegions.h>

#define ZOOM_TO_SHOW_MAP_NAMES 6
#define ZOOM_AFTER_BASEMAP 12
#define ZOOM_TO_SHOW_BORDERS_ST 4
#define ZOOM_TO_SHOW_BORDERS 7
#define ZOOM_TO_SHOW_SELECTION_ST 3
#define ZOOM_TO_SHOW_SELECTION 8

@implementation OADownloadMapObject

- (instancetype) initWithWorldRegion:(OAWorldRegion *)worldRegion indexItem:(OAResourceItem *)indexItem
{
    self = [super init];
    if (self) {
        _worldRegion = worldRegion;
        _indexItem = indexItem;
    }
    return self;
}

@end

@implementation OADownloadedRegionsLayer
{
    std::shared_ptr<OsmAnd::PolygonsCollection> _collection;
    
    std::shared_ptr<OsmAnd::PolygonsCollection> _selectedCollection;
    OAAutoObserverProxy* _localResourcesChangedObserver;
    BOOL _initDone;

    OAAutoObserverProxy *_weatherToolbarStateChangeObservable;
    BOOL _needsSettingsForToolbar;
}

- (NSString *) layerId
{
    return kDownloadedRegionsLayerId;
}

- (void) initLayer
{
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:self.app.localResourcesChangedObservable];
    _weatherToolbarStateChangeObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherToolbarStateChanged)
                                                                      andObserve:[OARootViewController instance].mapPanel.weatherToolbarStateChangeObservable];
    _collection = std::make_shared<OsmAnd::PolygonsCollection>();
    _selectedCollection = std::make_shared<OsmAnd::PolygonsCollection>();
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
}

- (void)deinitLayer
{
    [super deinitLayer];
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
    if (_weatherToolbarStateChangeObservable)
    {
        [_weatherToolbarStateChangeObservable detach];
        _weatherToolbarStateChangeObservable = nil;
    }
}

- (void) resetLayer
{
    [self.mapView removeKeyedSymbolsProvider:_collection];
    _collection = std::make_shared<OsmAnd::PolygonsCollection>();
    _selectedCollection = std::make_shared<OsmAnd::PolygonsCollection>();
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    [self refreshLayer];
    return YES;
}

- (void) refreshLayer
{
    if (!_needsSettingsForToolbar && [OAAppSettings.sharedManager.mapSettingShowBordersOfDownloadedMaps get])
    {
        NSMutableArray<OAWorldRegion *> *mapRegions = [NSMutableArray array];
        NSMutableArray<OAWorldRegion *> *toRemove = [NSMutableArray array];
        const auto& localResources = self.app.resourcesManager->getLocalResources();
        if (!localResources.isEmpty())
        {
            NSArray<OAWorldRegion *> *regions = self.app.worldRegion.flattenedSubregions;
            for (OAWorldRegion *region in regions)
            {
                for (const auto& resource : localResources)
                {
                    if (resource && resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed && resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                    {
                        if ([region.resourceTypes containsObject:@((int)OsmAnd::ResourcesManager::ResourceType::MapRegion)]
                            && !resource->id.isNull() && [resource->id.toLower().toNSString() hasPrefix:region.downloadsIdPrefix])
                        {
                            [mapRegions addObject:region];
                            [toRemove addObjectsFromArray:region.subregions];
                            break;
                        }
                    }
                }
            }
            [mapRegions removeObjectsInArray:toRemove];
        }
        if (mapRegions.count > 0)
        {
            [self.mapViewController runWithRenderSync:^{
                [self.mapView removeKeyedSymbolsProvider:_collection];
                _collection = std::make_shared<OsmAnd::PolygonsCollection>();
                BOOL hasPoints = NO;
                for (OAWorldRegion *r in mapRegions)
                {
                    NSArray<OAPointIContainer *> *polygons = [r getAllPolygons];
                    for (OAPointIContainer *pc in polygons)
                    {
                        if (!pc.qPoints.isEmpty())
                        {
                            [self drawRegion:pc.qPoints region:r];
                            hasPoints = YES;
                        }
                    }
                }
                if (hasPoints)
                    [self.mapView addKeyedSymbolsProvider:_collection];
            }];
        }
    }
}

- (void) drawRegion:(const QVector<OsmAnd::PointI> &)points region:(OAWorldRegion *)region
{
    int baseOrder = self.baseOrder;
    const auto& outdatedResources = self.app.resourcesManager->getOutdatedInstalledResources();
    const auto& resource = self.app.resourcesManager->getLocalResource(QString::fromNSString([region.downloadsIdPrefix stringByAppendingString:@"obf"]));
    BOOL outdated = NO;
    if (resource)
    {
        const auto it = find(outdatedResources.begin(), outdatedResources.end(), resource);
        outdated = it != outdatedResources.end();
    }
    OsmAnd::ColorARGB regionColor = OsmAnd::ColorARGB(outdated ? color_region_backuped_argb : color_region_uptodate_argb);
    
    OsmAnd::PolygonBuilder builder;
    builder.setBaseOrder(baseOrder--)
    .setIsHidden(points.size() == 0)
    .setPolygonId(1)
    .setPoints(points)
    .setFillColor(regionColor);
    
    builder.buildAndAddToCollection(_collection);
}

- (void) highlightRegion:(OAWorldRegion *)region
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_selectedCollection];
        _selectedCollection->removeAllPolygons();
        NSArray<OAPointIContainer *> *polygons = [region getAllPolygons];
        OsmAnd::ColorARGB regionColor = OsmAnd::ColorARGB(color_region_selected_argb);
        for (OAPointIContainer *pc in polygons)
        {
            const auto &points = pc.qPoints;
            if (!points.isEmpty())
            {
                OsmAnd::PolygonBuilder builder;
                builder.setBaseOrder(self.baseOrder - _collection->getPolygons().size())
                    .setIsHidden(points.size() == 0)
                    .setPolygonId(100)
                    .setPoints(points)
                    .setFillColor(regionColor);
                
                builder.buildAndAddToCollection(_selectedCollection);
            }
        }
        [self.mapView addKeyedSymbolsProvider:_selectedCollection];
    }];
}

- (void) hideRegionHighlight
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_selectedCollection];
        _selectedCollection = std::make_shared<OsmAnd::PolygonsCollection>();
    }];
}

- (OAResourceItem *)createLocalResourceItem:(OAWorldRegion *)region resource:(const std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> &)resource
{
    const auto localResource = self.app.resourcesManager->getLocalResource(resource->id);
    if (!localResource)
        return nil;

    OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
    item.resourceId = resource->id;
    item.resourceType = resource->type;
    item.title = [OAResourcesUIHelper titleOfResource:resource
                                             inRegion:region
                                       withRegionName:YES
                                     withResourceType:NO];
    item.downloadTask = [[self.app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
    item.size = resource->size;
    item.worldRegion = region;

    item.resource = localResource;
    item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];

    return item;
}

- (OAResourceItem *) resourceItemByResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> &)resource region:(OAWorldRegion *)region
{
    if (self.app.resourcesManager->isResourceInstalled(resource->id))
    {
        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:region
                                           withRegionName:YES
                                         withResourceType:NO];
        item.downloadTask = [[self.app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
        item.size = resource->size;
        item.worldRegion = region;

        const auto localResource = self.app.resourcesManager->getLocalResource(resource->id);
        item.resource = localResource;
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];

        return item;
    }
    else
    {
        OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:region
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [[self.app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
        item.size = resource->size;
        item.sizePkg = resource->packageSize;
        item.worldRegion = region;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];

        return item;
    }
}

- (void) getWorldRegionFromPoint:(CLLocationCoordinate2D)point dataObjects:(NSMutableArray<OADownloadMapObject *> *)dataObjects
{
    NSMutableArray<OADownloadMapObject *> *objectsToAdd = [NSMutableArray array];
    const auto zoom = self.mapView.zoomLevel;
    if (zoom >= ZOOM_TO_SHOW_SELECTION_ST && zoom < ZOOM_TO_SHOW_SELECTION)
    {
        const auto point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.latitude, point.longitude));
        NSMutableArray<OAWorldRegion *> *regions = [[self.app.worldRegion queryAtLat:point.latitude lon:point.longitude] mutableCopy];
        if (regions.count > 0)
        {
            [regions.copy enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![region contain:point.latitude lon:point.longitude])
                    [regions removeObject:region];
            }];
        }
        
        [regions sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber *first = [NSNumber numberWithDouble:[(OAWorldRegion *)a getArea]];
            NSNumber *second = [NSNumber numberWithDouble:[(OAWorldRegion *)b getArea]];
            return [second compare:first];
        }];
        
        const auto externalMaps = [OAResourcesUIHelper getExternalMapFilesAt:point31 routeData:NO];
        BOOL hasExternalMaps = !externalMaps.empty();
        for (OAWorldRegion *region in regions)
        {
            NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
            OAResourceItem *mapItem = nil;
            if (ids.count > 0)
            {
                for (NSString *resourceId in ids)
                {
                    const auto& resource = self.app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                    if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                    {
                        BOOL installed = resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed;
                        if (!hasExternalMaps || installed)
                        {
                            OAResourceItem *item = [self resourceItemByResource:resource region:region];
                            mapItem = item;
                        }
                    }
                }
                if (mapItem)
                    [objectsToAdd addObject:[[OADownloadMapObject alloc] initWithWorldRegion:region indexItem:mapItem]];
            }
        }
        if (objectsToAdd.count == 0 && hasExternalMaps)
        {
            OAWorldRegion *largestRegion = regions.firstObject;
            OAResourceItem *item = [self createLocalResourceItem:largestRegion resource:externalMaps.back()];
            if (item)
            	[objectsToAdd addObject:[[OADownloadMapObject alloc] initWithWorldRegion:largestRegion indexItem:item]];
        }
        [dataObjects addObjectsFromArray:objectsToAdd];
    }
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    if (OsmAndApp.instance.isInBackground)
    {
        self.invalidated = YES;
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLayer];
    });
}

- (void)onWeatherToolbarStateChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL needsSettingsForToolbar = [[OARootViewController instance].mapPanel.hudViewController needsSettingsForWeatherToolbar];
        if (_needsSettingsForToolbar != needsSettingsForToolbar)
        {
            _needsSettingsForToolbar = needsSettingsForToolbar;
            [self updateLayer];
        }
    });
}


#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OADownloadMapObject class]])
    {
        OADownloadMapObject *mapObject = (OADownloadMapObject *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.location = mapObject.worldRegion.regionCenter;
        targetPoint.title = mapObject.worldRegion.localizedName ? mapObject.worldRegion.localizedName : mapObject.worldRegion.nativeName;
   
        targetPoint.icon = [OAResourceType getIcon:mapObject.indexItem.resourceType templated:NO];
        targetPoint.type = OATargetMapDownload;
        targetPoint.targetObj = mapObject;
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    NSMutableArray<OADownloadMapObject *> *downloadObjects = [NSMutableArray array];
    [self getWorldRegionFromPoint:point dataObjects:downloadObjects];
    for (OADownloadMapObject *obj in downloadObjects)
    {
        OATargetPoint *pnt = [self getTargetPoint:obj];
        if (pnt)
            [found addObject:pnt];
    }
}

@end
