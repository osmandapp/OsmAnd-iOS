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

#include "OAMapillaryTilesProvider.h"
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/MvtReader.h>

#define kMapillaryOpacity 1.0f
#define kSearchRadius 100
#define EXTENT 4096.0

@implementation OAMapillaryLayer
{
    std::shared_ptr<OAMapillaryTilesProvider> _mapillaryMapProvider;
}

- (NSString *) layerId
{
    return kMapillaryVectorLayerId;
}

- (void) initLayer
{
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
    if ([OAAppSettings sharedManager].mapSettingShowMapillary)
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
    if (zoom >= _mapillaryMapProvider->getPointsZoom() && !symbolInfo)
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
            const auto point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.latitude, point.longitude));
            double searchRadius = MAX(5.0, kSearchRadius / mult);
            const auto searchAreaBBox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(searchRadius, point31);

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
                    OAMapillaryImage *image = [[OAMapillaryImage alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
                    // TODO: fill image object
                    OATargetPoint *targetPoint = [self getTargetPoint:image];
                    if (![found containsObject:targetPoint])
                        [found addObject:targetPoint];
                }
            }
        }
    }
}

@end
