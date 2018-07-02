//
//  OARecGPXLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXRecLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@implementation OAGPXRecLayer

- (NSString *) layerId
{
    return kGpxRecLayerId;
}

- (void) refreshGpxTracks:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs
{
    if (!gpxDocs.empty() && !self.gpxDocs.empty() && gpxDocs.first().get() == self.gpxDocs.first().get())
    {
        [self updateGpxTrack:gpxDocs];
    }
    else
    {
        [super refreshGpxTracks:gpxDocs];
    }
}

- (void) updateGpxTrack:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs
{
    if (!self.gpxDocs.empty())
    {
        QList<QVector<OsmAnd::PointI>> pointsList;
        
        const auto& doc = gpxDocs.first();
        if (doc->hasTrkPt())
        {
            for (const auto& track : doc->tracks)
            {
                for (const auto& seg : track->segments)
                {
                    QVector<OsmAnd::PointI> points;
                    
                    for (const auto& pt : seg->points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                    }
                    pointsList.push_back(points);
                }
            }
        }
        
        int baseOrder = self.baseOrder;
        int lineId = 1;
        int lineIndex = 0;

        const auto& lines = self.linesCollection->getLines();
        for (const auto& points : OsmAnd::constOf(pointsList))
        {
            if (points.size() > 1)
            {
                if (lineIndex == lines.size())
                {
                    OsmAnd::VectorLineBuilder builder;
                    builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(lineId++)
                    .setLineWidth(30)
                    .setPoints(points)
                    .setFillColor(OsmAnd::ColorARGB(kDefaultTrackColor))
                    .setPathIcon([OANativeUtilities skBitmapFromMmPngResource:@"arrow_triangle_white_nobg"])
                    .setPathIconStep(40);
                    
                    builder.buildAndAddToCollection(self.linesCollection);
                }
                else
                {
                    const auto& line = lines.at(lineIndex);
                    line->setPoints(points);
                }
                lineIndex++;
            }
        }
    }
}

- (std::shared_ptr<OsmAnd::MapMarker>) getMapMarkerAtPos:(OsmAnd::PointI)position31
{
    const auto& mapMarkers = self.markersCollection->getMarkers();
    for (const auto& marker : mapMarkers)
    {
        if (marker->getPosition() == position31)
            return marker;
    }
    return nullptr;
}

#pragma mark - OAContextMenuProvider

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    // collected by parent layer
}

@end
