//
//  OAMapillaryLayer.m
//  OsmAnd
//
//  Created by Alexey on 19/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAMapillaryImage.h"
#import "Localization.h"
#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"

#include "OAMapillaryTilesProvider.h"
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/MvtReader.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

#define kMapillaryOpacity 1.0f
#define kSearchRadius 100
#define EXTENT 4096.0

@implementation OAMapillaryLayer
{
    std::shared_ptr<OAMapillaryTilesProvider> _mapillaryMapProvider;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _currentImagePosition;

    std::shared_ptr<OsmAnd::MapMarker> _imageMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _imageMainIconKey;
    OsmAnd::MapMarker::OnSurfaceIconKey _imageHeadingIconKey;

    OAAutoObserverProxy* _mapillaryChangeObserver;
    
    OAAutoObserverProxy *_mapillaryImageChangedObserver;
}

- (NSString *) layerId
{
    return kMapillaryVectorLayerId;
}

- (void) initLayer
{
    _currentImagePosition = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    OsmAnd::MapMarkerBuilder imageAndCourseMarkerBuilder;
    imageAndCourseMarkerBuilder.setIsAccuracyCircleSupported(false);
    imageAndCourseMarkerBuilder.setBaseOrder(-100000);
    imageAndCourseMarkerBuilder.setIsHidden(true);
    
    _imageMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    imageAndCourseMarkerBuilder.addOnMapSurfaceIcon(_imageMainIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"map_mapillary_location"]);
    _imageHeadingIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
    imageAndCourseMarkerBuilder.addOnMapSurfaceIcon(_imageHeadingIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"map_mapillary_location_view_angle"]);
    _imageMarker = imageAndCourseMarkerBuilder.buildAndAddToCollection(_currentImagePosition);
    
    _mapillaryChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onMapillaryLayerChanged)
                                                          andObserve:self.app.data.mapillaryChangeObservable];
    
    _mapillaryImageChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onImageChanged:withKey:)
                                                                andObserve:self.app.mapillaryImageChangedObservable];
}

- (void) deinitLayer
{
}

- (void) resetLayer
{
    _mapillaryMapProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    [super updateLayer];

    if (self.app.data.mapillary)
    {
        auto mapillaryMapProvider = std::make_shared<OAMapillaryTilesProvider>(self.mapView.displayDensityFactor, [NSProcessInfo processInfo].physicalMemory);
        mapillaryMapProvider->setLocalCachePath(QString::fromNSString(self.app.cachePath));
        [self.mapView setProvider:mapillaryMapProvider forLayer:self.layerIndex];
        _mapillaryMapProvider = qMove(mapillaryMapProvider);
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(kMapillaryOpacity);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        
        [self showCurrentImageLayer];
        return YES;
    }
    else
    {
        [self hideCurrentImageLayer];
    }
    return NO;
}

- (void) clearCacheAndUpdate:(BOOL)vectorRasterOnly
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        auto mapillaryMapProvider = _mapillaryMapProvider;
        if (mapillaryMapProvider)
        {
            mapillaryMapProvider->clearDiskCache(vectorRasterOnly);
            if (!vectorRasterOnly)
                mapillaryMapProvider->clearMemoryCache();

            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLayer];
            });
        }
        
    });
}

- (void) didReceiveMemoryWarning
{
    auto mapillaryMapProvider = _mapillaryMapProvider;
    if (mapillaryMapProvider)
        mapillaryMapProvider->clearMemoryCache();
}

- (void) onMapillaryLayerChanged
{
    [self updateMapillaryLayer];
}

- (void) updateMapillaryLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUD];
    });
    [self.mapViewController runWithRenderSync:^{
        if (![self updateLayer])
        {
            [self.mapView resetProviderFor:self.layerIndex];
            _mapillaryMapProvider.reset();
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD];
    });
}

- (void) onImageChanged:(id)sender withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Display position
        if (key && [key isKindOfClass:OAMapillaryImage.class])
        {
            OAMapillaryImage *img = (OAMapillaryImage *) key;
            [self showCurrentImageLocation:img];
            OsmAnd::PointI newPositionI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(img.latitude, img.longitude));
            [self.mapViewController goToPosition:[OANativeUtilities convertFromPointI:newPositionI] animated:NO];
        }
        else
        {
            [self hideCurrentImageLocation];
        }
    });
}

- (void) showCurrentImageLayer
{
    if (_currentImagePosition)
        [self.mapView addKeyedSymbolsProvider:_currentImagePosition];
}

- (void) hideCurrentImageLayer
{
    if (_currentImagePosition)
        [self.mapView removeKeyedSymbolsProvider:_currentImagePosition];
}

- (void) showCurrentImageLocation:(OAMapillaryImage *) image
{
    if (_imageMarker && _imageHeadingIconKey)
    {
        _imageMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(image.latitude, image.longitude)));
        _imageMarker->setOnMapSurfaceIconDirection(_imageHeadingIconKey, OsmAnd::Utilities::normalizedAngleDegrees(image.ca));
        _imageMarker->setIsHidden(false);
    }
}

- (void) hideCurrentImageLocation
{
    if (_imageMarker)
        _imageMarker->setIsHidden(true);
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OAMapillaryImage class]])
    {
        OAMapillaryImage *item = (OAMapillaryImage *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetMapillaryImage;
        targetPoint.location = CLLocationCoordinate2DMake(item.latitude, item.longitude);
        targetPoint.targetObj = item;
        targetPoint.title = OALocalizedString(@"mapillary_image");
        targetPoint.icon = [UIImage imageNamed:@"ic_custom_mapillary_symbol"];
        
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
    const auto zoom = self.mapView.zoomLevel;
    auto mapillaryMapProvider = _mapillaryMapProvider;
    if (mapillaryMapProvider && zoom >= mapillaryMapProvider->getPointsZoom() && !symbolInfo)
    {
        const auto tileZoom = mapillaryMapProvider->getVectorTileZoom();
        const auto tileId = OsmAnd::TileId::fromXY(OsmAnd::Utilities::getTileNumberX(tileZoom, point.longitude), OsmAnd::Utilities::getTileNumberY(tileZoom, point.latitude));
        const auto& geometryTile = mapillaryMapProvider->readGeometry(tileId);
        if (geometryTile != nullptr && !geometryTile->empty())
        {
            int dzoom = zoom - tileZoom;
            double mult = (int) pow(2.0, dzoom);
            const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - zoom));
            const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - zoom;
            const auto touchLatLon = OsmAnd::LatLon(point.latitude, point.longitude);
            const auto point31 = OsmAnd::Utilities::convertLatLonTo31(touchLatLon);
            double searchRadius = MAX(5.0, kSearchRadius / mult);
            const auto searchAreaBBox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(searchRadius, point31);

            double minDist = DBL_MAX;
            OAMapillaryImage *image = nil;
            for (const auto& pnt : geometryTile->getGeometry())
            {
                if (pnt == nullptr || pnt->getType() != OsmAnd::MvtReader::GeomType::POINT)
                    continue;
                
                double px, py;
                const auto& p = std::dynamic_pointer_cast<const OsmAnd::MvtReader::Point>(pnt);
                OsmAnd::PointI coordinate = p->getCoordinate();
                px = coordinate.x / EXTENT;
                py = coordinate.y / EXTENT;
                
                double tileX = ((tileId.x << zoomShift) + (tileSize31 * px)) * mult;
                double tileY = ((tileId.y << zoomShift) + (tileSize31 * py)) * mult;
                
                if (searchAreaBBox31.contains(tileX, tileY))
                {
                    if ([OAAppSettings sharedManager].useMapillaryFilter.get && mapillaryMapProvider->filtered(p->getUserData(), geometryTile))
                            continue;
                    
                    auto latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(tileX, tileY));
                    double dist = OsmAnd::Utilities::distance(latLon, touchLatLon);
                    if (dist < minDist)
                    {
                        minDist = dist;
                        image = [[OAMapillaryImage alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
                        if (![image setData:pnt->getUserData() geometryTile:geometryTile])
                            image = nil;
                    }
                }
            }
            if (image)
            {
                OATargetPoint *targetPoint = [self getTargetPoint:image];
                if (![found containsObject:targetPoint])
                    [found addObject:targetPoint];
            }
        }
    }
}

@end
