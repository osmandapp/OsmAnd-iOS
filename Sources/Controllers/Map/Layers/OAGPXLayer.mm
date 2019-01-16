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

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@implementation OAGPXLayer

- (NSString *) layerId
{
    return kGpxLayerId;
}

- (void) initLayer
{
    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _markersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();

    [self.mapView addKeyedSymbolsProvider:_linesCollection];
    [self.mapView addKeyedSymbolsProvider:_markersCollection];
}

- (void) resetLayer
{
    [self.mapView removeKeyedSymbolsProvider:_markersCollection];
    [self.mapView removeKeyedSymbolsProvider:_linesCollection];

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _markersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    _gpxDocs.clear();
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
        QList<QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>>> locationMarksList;
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
            
            if (!it.value()->locationMarks.empty())
                locationMarksList.push_back(it.value()->locationMarks);
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
        
        for (const auto& locationMarks : locationMarksList)
        {
            for (const auto& locationMark : locationMarks)
            {
                UIColor* color = [self getWptColor:locationMark->extraData];
                OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
                
                OsmAnd::MapMarkerBuilder()
                .setIsAccuracyCircleSupported(false)
                .setBaseOrder(baseOrder--)
                .setIsHidden(false)
                .setPinIcon([OANativeUtilities skBitmapFromPngResource:favCol.iconName])
                .setPosition(OsmAnd::Utilities::convertLatLonTo31(locationMark->position))
                .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
                .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
                .buildAndAddToCollection(_markersCollection);
            }
        }

        [self.mapView addKeyedSymbolsProvider:_linesCollection];
        [self.mapView addKeyedSymbolsProvider:_markersCollection];
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

        UIColor* color = item.color;
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        targetPoint.icon = [UIImage imageNamed:favCol.iconName];
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

@end
