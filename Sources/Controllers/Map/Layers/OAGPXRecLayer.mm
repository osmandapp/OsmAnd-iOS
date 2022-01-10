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
#import "OAGPXDatabase.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@interface OAGPXRecLayer ()

@property (nonatomic) CGFloat defaultTrackWidth;
@property (nonatomic) NSDictionary<NSString *, NSArray<NSNumber *> *> *gpxWidthAttrs;

@end

@implementation OAGPXRecLayer

- (NSString *) layerId
{
    return kGpxRecLayerId;
}

- (void) refreshGpxTracks:(QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >)gpxDocs
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
    const auto& doc = [helper.currentTrack getDocument];
    if (doc)
    {
        const auto path = QString::fromNSString(helper.currentTrack.path);
        if (gpxDocs.contains(path) && self.gpxDocs.contains(path))
        {
            [self updateGpxTrack:gpxDocs];
        }
        else
        {
            [super refreshGpxTracks:gpxDocs];
        }
    }
}

- (void) updateGpxTrack:(QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> >)gpxDocs
{
    if (!gpxDocs.empty())
    {
        [self.mapView removeKeyedSymbolsProvider:self.linesCollection];
        QList<QVector<OsmAnd::PointI>> pointsList;
        
        const auto& doc = gpxDocs.begin().value();
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
        CGFloat lineWidth = [self getLineWidth:[[OASavingTrackHelper sharedInstance] getCurrentGPX].width];

        const auto& lines = self.linesCollection->getLines();
        for (const auto& points : OsmAnd::constOf(pointsList))
        {
            if (points.size() > 1)
            {
                if (lineIndex == self.linesCollection->getLines().size())
                {
                    OsmAnd::VectorLineBuilder builder;
                    builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(lineId++)
                    .setLineWidth(lineWidth)
                    .setPoints(points)
                    .setFillColor(OsmAnd::ColorARGB(kDefaultTrackColor))
                    .setPathIcon([OANativeUtilities skImageFromMmPngResource:@"arrow_triangle_white_nobg"])
                    .setSpecialPathIcon([OANativeUtilities skImageFromMmPngResource:@"arrow_triangle_white_nobg"])
                    .setShouldShowArrows(true)
                    .setScreenScale(UIScreen.mainScreen.scale);
                    
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
        [self.mapView addKeyedSymbolsProvider:self.linesCollection];
    }
}

#pragma mark - OAContextMenuProvider

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    // collected by parent layer
}

#pragma mark - OAMoveObjectProvider

- (BOOL)isObjectMovable:(id)object
{
    BOOL movable = NO;
    if ([object isKindOfClass:OAGpxWptItem.class])
        movable = ((OAGpxWptItem *)object).docPath == nil;
    
    return movable;
}

@end
