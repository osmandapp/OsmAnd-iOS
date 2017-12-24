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

- (void) refreshGpxTracks:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs
{
    [self resetLayer];

    _gpxDocs << gpxDocs;
    
    [self refreshGpxTracks];
}

- (OsmAnd::ColorARGB) getTrackColor:(OsmAnd::Ref<OsmAnd::GeoInfoDocument::ExtraData>)extraData
{
    OsmAnd::ColorARGB color(kDefaultTrackColor);
    if (extraData)
    {
        const auto& values = extraData->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
        {
            //bool ok;
            //color = OsmAnd::Utilities::parseColor(it.value().toString(), OsmAnd::ColorARGB(kDefaultTrackColor), &ok);
            NSString *colorStr = it.value().toString().toNSString();
            UIColor *c = [OAUtilities colorFromString:colorStr];
            if (c)
            {
                CGFloat r, g, b, a;
                [c getRed:&r green:&g blue:&b alpha:&a];
                color = OsmAnd::ColorARGB(255 * a, 255 * r, 255 * g, 255 * b);
            }
        }
    }
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

        for (const auto& doc : _gpxDocs)
        {
            BOOL routePoints = NO;
            if (doc->hasTrkPt())
            {
                for (const auto& track : doc->tracks)
                {
                    for (const auto& seg : track->segments)
                    {
                        OsmAnd::ColorARGB color = [self getTrackColor:seg->extraData];
                        QVector<OsmAnd::PointI> points;
                        
                        for (const auto& pt : seg->points)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                        }
                        pointsList.push_back(qMakePair(color, points));
                    }
                }
            }
            else if (doc->hasRtePt())
            {
                routePoints = YES;
                for (const auto& route : doc->routes)
                {
                    QVector<OsmAnd::PointI> points;
                    for (const auto& pt : route->points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                    }
                    pointsList.push_back(qMakePair(OsmAnd::ColorARGB(kDefaultTrackColor), points));
                }
            }
            
            if (!doc->locationMarks.empty())
                locationMarksList.push_back(doc->locationMarks);
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

@end
