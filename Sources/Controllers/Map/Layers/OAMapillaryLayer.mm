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
#import "OARootViewController.h"

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
    
    OAAutoObserverProxy* _mapillaryChangeObserver;
    
    OAAutoObserverProxy *_mapillaryImageChangedObserver;
    
    CGFloat _cachedYViewPort;
}

- (NSString *) layerId
{
    return kMapillaryVectorLayerId;
}

- (void) initLayer
{
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
    if (self.app.data.mapillary)
    {
        _mapillaryMapProvider = std::make_shared<OAMapillaryTilesProvider>(self.mapView.displayDensityFactor);
        _mapillaryMapProvider->setLocalCachePath(QString::fromNSString(self.app.cachePath));
        [self.mapView setProvider:_mapillaryMapProvider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(kMapillaryOpacity);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        return YES;
    }
    return NO;
}

- (void) didReceiveMemoryWarning
{
    if (_mapillaryMapProvider)
        _mapillaryMapProvider->clearCache();
}

- (void) onMapillaryLayerChanged
{
    [self updateMapillaryLayer];
}

- (void) updateMapillaryLayer
{
    [self.mapViewController runWithRenderSync:^{
        if (![self updateLayer])
        {
            [self.mapView resetProviderFor:self.layerIndex];
            _mapillaryMapProvider.reset();
        }
    }];
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
            _cachedYViewPort = self.mapViewController.mapView.viewportYScale;
            self.mapViewController.mapView.viewportYScale = 1.5;
        }
        else
        {
            [self hideCurrentImageLayer];
            self.mapViewController.mapView.viewportYScale = _cachedYViewPort;
        }
    });
}


- (void) showCurrentImageLayer
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_currentImagePosition];
    }];
}

- (void) hideCurrentImageLayer
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_currentImagePosition];
    }];
}

- (void) showCurrentImageLocation:(OAMapillaryImage *) image
{
    [self hideCurrentImageLayer];
    _currentImagePosition.reset(new OsmAnd::MapMarkersCollection());
    
    OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(-100000)
    .setIsHidden(false)
    .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_mapillary_location"])
    .setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(image.latitude, image.longitude)))
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .buildAndAddToCollection(_currentImagePosition);
    
    OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(-90000)
    .setIsHidden(false)
    .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_mapillary_location_view_angle" rotatedBy:image.ca])
    .setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(image.latitude, image.longitude)))
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .buildAndAddToCollection(_currentImagePosition);
    
    [self showCurrentImageLayer];
    
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
    if (_mapillaryMapProvider && zoom >= _mapillaryMapProvider->getPointsZoom() && !symbolInfo)
    {
        const auto tileZoom = _mapillaryMapProvider->getVectorTileZoom();
        const auto tileId = OsmAnd::TileId::fromXY(OsmAnd::Utilities::getTileNumberX(tileZoom, point.longitude), OsmAnd::Utilities::getTileNumberY(tileZoom, point.latitude));
        const auto& geometry = _mapillaryMapProvider->readGeometry(tileId);
        if (!geometry.empty())
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
            for (const auto& pnt : geometry)
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
                    auto latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(tileX, tileY));
                    double dist = OsmAnd::Utilities::distance(latLon, touchLatLon);
                    if (dist < minDist)
                    {
                        minDist = dist;
                        image = [[OAMapillaryImage alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
                        if (![image setData:pnt->getUserData()])
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
