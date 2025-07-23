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
#import "OAAppSettings.h"
#import "OAAppData.h"
#import "OAObservable.h"
#import "OAMapUtils.h"
#import "OAPointDescription.h"
#import "OsmAnd_Maps-Swift.h"

#include "OAMapillaryTilesProvider.h"
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/MvtReader.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SingleSkImage.h>

#define kMapillaryOpacity 1.0f
#define kSearchRadius 100
#define EXTENT 4096.0

static int MIN_POINTS_ZOOM = 17;

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
    imageAndCourseMarkerBuilder.setBaseOrder(self.pointsOrder);
    imageAndCourseMarkerBuilder.setIsHidden(true);
    
    _imageMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    imageAndCourseMarkerBuilder.addOnMapSurfaceIcon(_imageMainIconKey,
                                                       OsmAnd::SingleSkImage([OANativeUtilities skImageFromPngResource:@"map_mapillary_location"]));
    _imageHeadingIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
    imageAndCourseMarkerBuilder.addOnMapSurfaceIcon(_imageHeadingIconKey,
                                                    OsmAnd::SingleSkImage([OANativeUtilities skImageFromPngResource:@"map_mapillary_location_view_angle"]));
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
    [self.mapView resetProviderFor:self.layerIndex];
    _mapillaryMapProvider.reset();
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

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
        [self.mapViewController runWithRenderSync:^{
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
        }];
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
    //dispatch_async(dispatch_get_main_queue(), ^{
    //    [self showProgressHUD];
    //});
    [self.mapViewController runWithRenderSync:^{
        if (![self updateLayer])
        {
            [self.mapView resetProviderFor:self.layerIndex];
            _mapillaryMapProvider.reset();
        }
    }];
    //dispatch_async(dispatch_get_main_queue(), ^{
    //    [self hideProgressHUD];
    //});
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
        _imageMarker->setOnMapSurfaceIconDirection(_imageHeadingIconKey, OsmAnd::Utilities::normalizedAngleDegrees(image.compassAngle));
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

- (void) collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    if (!_mapillaryMapProvider || [self.mapViewController getMapZoom] < MIN_POINTS_ZOOM)
        return;
    
    CGPoint pixel = result.point;
    OsmAnd::PointI center31 = [OANativeUtilities getPoint31From:pixel];
    const auto latLon = [OANativeUtilities getLanlonFromPoint31:center31];

    int radius = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
    const auto touchPolygon31 = [self getMapillaryTouchPolygon:pixel radius:radius];
    if (touchPolygon31 == OsmAnd::AreaI())
        return;
    
    const auto zoom = self.mapView.zoomLevel;
    const auto tileZoom = _mapillaryMapProvider->getVectorTileZoom();
    const auto tileId = OsmAnd::TileId::fromXY(OsmAnd::Utilities::getTileNumberX(tileZoom, latLon.longitude), OsmAnd::Utilities::getTileNumberY(tileZoom, latLon.latitude));
    
    const auto& geometryTile = _mapillaryMapProvider->readGeometry(tileId);
    if (geometryTile != nullptr && !geometryTile->empty())
    {
        int dzoom = zoom - tileZoom;
        double mult = (int) pow(2.0, dzoom);
        const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - zoom));
        const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - zoom;
        
        double minDistance = DBL_MAX;
        OAMapillaryImage *closestImage = nil;
        
        for (const auto& pnt : geometryTile->getGeometry())
        {
            if (pnt == nullptr || pnt->getType() != OsmAnd::MvtReader::GeomType::POINT)
                continue;
            
            const auto& p = std::dynamic_pointer_cast<const OsmAnd::MvtReader::Point>(pnt);
            
            double px = p->getCoordinate().x / EXTENT;
            double py = p->getCoordinate().y / EXTENT;
            double tileX = ((tileId.x << zoomShift) + (tileSize31 * px)) * mult;
            double tileY = ((tileId.y << zoomShift) + (tileSize31 * py)) * mult;
            auto pointLatLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(tileX, tileY));
            
            BOOL shouldAdd = [OANativeUtilities isPointInsidePolygon:pointLatLon.latitude lon:pointLatLon.longitude polygon31:touchPolygon31];
            if (shouldAdd)
            {
                OAMapillaryImage *newImage = [[OAMapillaryImage alloc] initWithLatitude:pointLatLon.latitude longitude:pointLatLon.longitude];
                if ([newImage setData:pnt->getUserData() geometryTile:geometryTile])
                {
                    double distance = OsmAnd::Utilities::distance(latLon, pointLatLon);
                    if (!closestImage || distance < minDistance)
                    {
                        minDistance = distance;
                        closestImage = newImage;
                    }
                }
            }
        }
        
        if (closestImage)
        {
            [result collect:closestImage provider:self];
        }
    }
}

- (OsmAnd::AreaI) getMapillaryTouchPolygon:(CGPoint)pixel radius:(int)radius
{
    OsmAnd::AreaI touchPolygon31 = [OANativeUtilities getPolygon31FromPixelAndRadius:pixel radius:radius];
    if (touchPolygon31 == OsmAnd::AreaI())
        return OsmAnd::AreaI();
    
    int32_t minX31 = INT32_MAX;
    int32_t minY31 = INT32_MAX;
    int32_t maxX31 = INT32_MIN;
    int32_t maxY31 = INT32_MIN;
    
    QVector<OsmAnd::PointI> touchPolygonList = {touchPolygon31.topLeft, touchPolygon31.bottomRight};
    for (auto point31 : touchPolygonList)
    {
        minX31 = min(minX31, point31.x);
        minY31 = min(minY31, point31.y);
        maxX31 = max(maxX31, point31.x);
        maxY31 = max(maxY31, point31.y);
    }
    
    return OsmAnd::AreaI(minY31, minX31, maxY31, maxX31);
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OAMapillaryImage.class])
    {
        OAMapillaryImage * image = (OAMapillaryImage *)obj;
        return [[CLLocation alloc] initWithLatitude:image.latitude longitude:image.longitude];
    }
    return nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OAMapillaryImage.class])
    {
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_MAPILLARY_IMAGE name:OALocalizedString(@"mapillary_image")];
    }
    return nil;
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t) getSelectionPointOrder:(id)selectedObject
{
    return 0;
}

@end
