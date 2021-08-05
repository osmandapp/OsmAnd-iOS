//
//  OAGPXLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "OAGpxWptItem.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OAWaypointsMapLayerProvider.h"
#import "OAFavoritesLayer.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@implementation OAGPXLayer
{
    std::shared_ptr<OAWaypointsMapLayerProvider> _waypointsMapProvider;
    BOOL _showCaptionsCache;
    OsmAnd::PointI _hiddenPointPos31;
}

- (NSString *) layerId
{
    return kGpxLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _hiddenPointPos31 = OsmAnd::PointI();
    _showCaptionsCache = self.showCaptions;

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
    [self.mapView addKeyedSymbolsProvider:_linesCollection];
}

- (void) resetLayer
{
    [super resetLayer];

    [self.mapView removeTiledSymbolsProvider:_waypointsMapProvider];
    [self.mapView removeKeyedSymbolsProvider:_linesCollection];

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
    _gpxDocs.clear();
}

- (BOOL) updateLayer
{
    [super updateLayer];
    
    if (self.showCaptions != _showCaptionsCache)
    {
        _showCaptionsCache = self.showCaptions;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshGpxWaypoints];
        });
    }
    
    return YES;
}

- (void) refreshGpxTracks:(QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >)gpxDocs
{
    [self resetLayer];

    _gpxDocs = gpxDocs;
    
    [self refreshGpxTracks];
}

- (OsmAnd::ColorARGB) getTrackColor:(QString)filename
{
    NSString *filenameNS = filename.toNSString();
    filenameNS = [OAUtilities getGpxShortPath:filenameNS];
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filenameNS];
    int colorValue = kDefaultTrackColor;
    if (gpx && gpx.color != 0)
        colorValue = gpx.color;
    
    OsmAnd::ColorARGB color(colorValue);
    
//    if (extraData)
//    {
//        const auto& values = extraData->getValues();
//        const auto& it = values.find(QStringLiteral("color"));
//        if (it != values.end())
//        {
//            //bool ok;
//            //color = OsmAnd::Utilities::parseColor(it.value().toString(), OsmAnd::ColorARGB(kDefaultTrackColor), &ok);
//            NSString *colorStr = it.value().toString().toNSString();
//            UIColor *c = [OAUtilities colorFromString:colorStr];
//            if (c)
//            {
//                CGFloat r, g, b, a;
//                [c getRed:&r green:&g blue:&b alpha:&a];
//                color = OsmAnd::ColorARGB(255 * a, 255 * r, 255 * g, 255 * b);
//            }
//        }
//    }
    return color;
}

- (UIColor *) getWptColor:(OsmAnd::Ref<OsmAnd::GeoInfoDocument::ExtraData>)extraData
{
    if (extraData)
    {
        const auto& values = extraData->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            return [OAUtilities colorFromString:it.value().toString().toNSString()];
    }
    return nil;
}

- (void) refreshGpxTracks
{
    if (!_gpxDocs.empty())
    {
        QList<QPair<OsmAnd::ColorARGB, QVector<OsmAnd::PointI>>> pointsList;
        QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >::iterator it;
        for (it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            if (!it.value())
                continue;
            BOOL routePoints = NO;

            if (it.value()->hasTrkPt())
            {
                for (const auto& track : it.value()->tracks)
                {
                    for (const auto& seg : track->segments)
                    {
                        OsmAnd::ColorARGB color = [self getTrackColor:it.key()];
                        QVector<OsmAnd::PointI> points;
                        
                        for (const auto& pt : seg->points)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                        }
                        pointsList.push_back(qMakePair(color, points));
                    }
                }
            }
            else if (it.value()->hasRtePt())
            {
                routePoints = YES;
                for (const auto& route : it.value()->routes)
                {
                    QVector<OsmAnd::PointI> points;
                    for (const auto& pt : route->points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                    }
                    pointsList.push_back(qMakePair(OsmAnd::ColorARGB(kDefaultTrackColor), points));
                }
            }
        }
        
        int baseOrder = self.baseOrder;
        int lineId = 1;
        
        for (const auto& it : OsmAnd::rangeOf(OsmAnd::constOf(pointsList)))
        {
            const auto& color = it->first;
            const auto& points = it->second;
            
            if (points.size() > 1)
            {
                OsmAnd::VectorLineBuilder builder;
                builder.setBaseOrder(baseOrder--)
                .setIsHidden(points.size() == 0)
                .setLineId(lineId++)
                .setLineWidth(30)
                .setPoints(points)
                .setFillColor(color)
                .setPathIcon([OANativeUtilities skBitmapFromMmPngResource:@"arrow_triangle_white_nobg"])
                .setPathIconStep(40);
                
                builder.buildAndAddToCollection(_linesCollection);
            }
        }

        [self.mapView addKeyedSymbolsProvider:_linesCollection];
    }
    
    [self refreshGpxWaypoints];
}

- (void) refreshGpxWaypoints
{
    if (_waypointsMapProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_waypointsMapProvider];
        _waypointsMapProvider = nullptr;
    }

    if (!_gpxDocs.empty())
    {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> locationMarks;
        QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >::iterator it;
        for (it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            if (!it.value())
                continue;
            
            if (!it.value()->locationMarks.empty())
                locationMarks.append(it.value()->locationMarks);
        }
        
        const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
        QList<OsmAnd::PointI> hiddenPoints;
        if (_hiddenPointPos31 != OsmAnd::PointI())
            hiddenPoints.append(_hiddenPointPos31);
        
        _waypointsMapProvider.reset(new OAWaypointsMapLayerProvider(locationMarks, self.baseOrder - locationMarks.count() - 1, hiddenPoints,
                                                                    self.showCaptions, self.captionStyle, self.captionTopSpace, rasterTileSize));
        [self.mapView addTiledSymbolsProvider:_waypointsMapProvider];
    }
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OAGpxWptItem class]])
    {
        OAGpxWptItem *item = (OAGpxWptItem *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetWpt;
        targetPoint.location = item.point.position;
        targetPoint.targetObj = item;

        targetPoint.icon = item.getCompositeIcon;
        targetPoint.title = item.point.name;
        
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
    OAMapViewController *mapViewController = self.mapViewController;
    if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo->mapSymbol->groupPtr))
    {
        if ([mapViewController findWpt:point])
        {
            OAGpxWpt *wpt = mapViewController.foundWpt;
            NSArray *foundWptGroups = mapViewController.foundWptGroups;
            NSString *foundWptDocPath = mapViewController.foundWptDocPath;

            OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
            item.point = wpt;
            item.groups = foundWptGroups;
            item.docPath = foundWptDocPath;

            OATargetPoint *targetPoint = [self getTargetPoint:item];
            if (![found containsObject:targetPoint])
                [found addObject:targetPoint];
        }
    }
}

#pragma mark - OAMoveObjectProvider

- (BOOL) isObjectMovable:(id)object
{
    return [object isKindOfClass:OAGpxWptItem.class];
}

- (void) applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OAGpxWptItem *item = (OAGpxWptItem *)object;
        
        if (item.docPath)
        {
            item.point.position = position;
            item.point.wpt->position = OsmAnd::LatLon(position.latitude, position.longitude);
            const auto activeGpx = [OASelectedGPXHelper instance].activeGpx;
            const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(activeGpx[QString::fromNSString(item.docPath)]);
            if (doc != nullptr)
            {
                doc->saveTo(QString::fromNSString(item.docPath));
                QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> > docs;
                docs[QString::fromNSString(item.docPath)] = doc;
                [self refreshGpxTracks:docs];
            }
        }
        else
        {
            OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
            [helper updatePointCoordinates:item.point newLocation:position];
            item.point.wpt->position = OsmAnd::LatLon(position.latitude, position.longitude);
            [self.app.trackRecordingObservable notifyEventWithKey:@(YES)];
        }
    }
}

- (UIImage *) getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        OAGpxWptItem *point = (OAGpxWptItem *)object;
        return [OAFavoritesLayer getImageWithColor:point.color background:point.point.getBackgroundIcon icon:[@"mx_" stringByAppendingString:point.point.getIcon]];
    }
    return [OADefaultFavorite nearestFavColor:OADefaultFavorite.builtinColors.firstObject].icon;
}

- (void) setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OAGpxWptItem *point = (OAGpxWptItem *)object;
        const auto& pos = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.point.getLatitude, point.point.getLongitude));
        _hiddenPointPos31 = hidden ? pos : OsmAnd::PointI();
        [self refreshGpxWaypoints];
    }
}

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment
{
    return EOAPinAlignmentCenterVertical;
}


- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment
{
    return EOAPinAlignmentCenterHorizontal;
}

@end
