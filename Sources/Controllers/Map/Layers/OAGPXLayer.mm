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
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OAGpxWptItem.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OAWaypointsMapLayerProvider.h"
#import "OAFavoritesLayer.h"
#import "OARouteColorizationHelper.h"
#import "OAGPXAppearanceCollection.h"
#import "QuadRect.h"
#import "OAMapUtils.h"
#import "OARouteImporter.h"
#import "OAAppVersionDependentConstants.h"
#import "OAGpxTrackAnalysis.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/GpxAdditionalIconsProvider.h>

@interface OAGPXLayer ()

@property (nonatomic) OAGPXAppearanceCollection *appearanceCollection;

@end

@implementation OAGPXLayer
{
    std::shared_ptr<OAWaypointsMapLayerProvider> _waypointsMapProvider;
    std::shared_ptr<OsmAnd::GpxAdditionalIconsProvider> _startFinishProvider;
    BOOL _showCaptionsCache;
    OsmAnd::PointI _hiddenPointPos31;

    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *_cachedTracks;
    QHash< QString, QList<OsmAnd::FColorARGB> > _cachedColors;
    NSMutableDictionary<NSString *, NSNumber *> *_cachedTrackWidth;
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

    _cachedTracks = [NSMutableDictionary dictionary];
    _cachedTrackWidth = [NSMutableDictionary dictionary];
}

- (void) resetLayer
{
    [super resetLayer];

    [self.mapView removeTiledSymbolsProvider:_waypointsMapProvider];
    [self.mapView removeTiledSymbolsProvider:_startFinishProvider];
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

    dispatch_async(dispatch_get_main_queue(), ^{
        self.appearanceCollection = [[OAGPXAppearanceCollection alloc] init];
    });

    return YES;
}

- (void) refreshGpxTracks:(QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> >)gpxDocs
{
    [self resetLayer];

    if (_cachedTracks.count > 0)
    {
        [_cachedTracks.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            QString qKey = QString::fromNSString(key);
            if (!gpxDocs.contains(qKey))
            {
                [_cachedTracks removeObjectForKey:key];
                _cachedColors.remove(qKey);
            }
        }];
    }

    _gpxDocs = gpxDocs;
    
    [self refreshGpxTracks];
}

- (OAGPX *)getGpxItem:(const QString &)filename
{
    NSString *filenameNS = filename.toNSString();
    filenameNS = [OAUtilities getGpxShortPath:filenameNS];
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filenameNS];
    return gpx;
}

- (OsmAnd::ColorARGB) getTrackColor:(QString)filename
{
    OAGPX * gpx = [self getGpxItem:filename];
    int colorValue = kDefaultTrackColor;
    if (gpx && gpx.color != 0)
        colorValue = (int) gpx.color;
    
    OsmAnd::ColorARGB color(colorValue);
    return color;
}

- (UIColor *) getWptColor:(OsmAnd::Ref<OsmAnd::GpxExtensions>)extensions
{
    if (extensions)
    {
        const auto& values = extensions->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            return [UIColor colorFromString:it.value().toString().toNSString()];
    }
    return nil;
}

- (void) refreshGpxTracks
{
    if (!_gpxDocs.empty())
    {
        int baseOrder = self.baseOrder;
        int lineId = 1;
        for (auto it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            QString key = it.key();
            if (!it.value())
                continue;

            BOOL isCurrentTrack = [key.toNSString() isEqualToString:kCurrentTrack];
            OAGPX *gpx;
            OAGPXDocument *doc;
            auto doc_ = std::const_pointer_cast<OsmAnd::GpxDocument>(it.value());

            NSString *filePath = key.toNSString();
            NSMutableDictionary<NSString *, id> *cachedTrack = _cachedTracks[filePath];
            if (!cachedTrack || isCurrentTrack)
            {
                if (isCurrentTrack)
                    gpx = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
                else
                    gpx = [self getGpxItem:key];

                if (isCurrentTrack)
                {
                    doc = [OASavingTrackHelper sharedInstance].currentTrack;
                }
                else
                {
                    doc = [[OAGPXDocument alloc] initWithGpxDocument:doc_];
                    doc.path = [self.app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
                }

                cachedTrack = [NSMutableDictionary dictionary];
                cachedTrack[@"gpx"] = gpx;
                cachedTrack[@"doc"] = doc;
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_NONE);
                cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
                _cachedTracks[filePath] = cachedTrack;
                _cachedColors[key] = QList<OsmAnd::FColorARGB>();
            }
            else
            {
                gpx = cachedTrack[@"gpx"];
                doc = cachedTrack[@"doc"];
            }

            OAColoringType *type = gpx.coloringType.length > 0
                    ? [OAColoringType getNonNullTrackColoringTypeByName:gpx.coloringType]
                    : OAColoringType.TRACK_SOLID;
            if ([type isGradient]
                    && (![cachedTrack[@"prev_coloring_type"] isEqualToString:gpx.coloringType]
                    || [cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_GRADIENT
                    || _cachedColors[key].isEmpty()))
            {
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_GRADIENT);
                cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
                OARouteColorizationHelper *routeColorization =
                        [[OARouteColorizationHelper alloc] initWithGpxFile:doc
                                analysis:[doc getAnalysis:0]
                                                                      type:type.toGradientScaleType.toColorizationType
                                                           maxProfileSpeed:0];
                _cachedColors[key] = routeColorization ? [routeColorization getResult] : QList<OsmAnd::FColorARGB>();
            }
            else if ([type isRouteInfoAttribute]
                    && (![cachedTrack[@"prev_coloring_type"] isEqualToString:gpx.coloringType]
                    || [cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_SOLID
                    || _cachedColors[key].isEmpty()))
            {
                OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithGpxFile:doc];
                auto segs = [routeImporter importRoute];
                NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
                for (OATrkSegment *seg in [doc getNonEmptyTrkSegments:YES])
                {
                    for (OAWptPt *point in seg.points)
                    {
                        [locations addObject:[[CLLocation alloc] initWithLatitude:point.position.latitude
                                                                        longitude:point.position.longitude]];
                    }
                }
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_SOLID);
                cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
                _cachedColors[key].clear();
                [self calculateSegmentsColor:_cachedColors[key]
                                    attrName:gpx.coloringType
                               segmentResult:segs
                                   locations:locations];
            }
            else if ([type isSolidSingleColor]
                    && ([cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_NONE
                    || !_cachedColors[key].isEmpty()))
            {
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_NONE);
                cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
                _cachedColors[key].clear();
            }

            if (doc_->hasTrkPt())
            {
                int segStartIndex = 0;
                QVector<OsmAnd::PointI> points;
                QList<OsmAnd::FColorARGB> segmentColors;
                for (const auto& track : doc_->tracks)
                {
                    for (const auto& seg : track->segments)
                    {
                        for (const auto& pt : seg->points)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                        }
                        if (points.size() > 1 && !_cachedColors[key].isEmpty() && segStartIndex < _cachedColors[key].size() && segStartIndex + points.size() - 1 < _cachedColors[key].size())
                        {
                            segmentColors = _cachedColors[key].mid(segStartIndex, points.size());
                        }
                        else if ([cachedTrack[@"colorization_scheme"] intValue] == COLORIZATION_NONE && segmentColors.isEmpty() && gpx.color == 0)
                        {
                            int trackIndex = doc_->tracks.indexOf(track);
                            OATrack *gpxTrack = doc.tracks[trackIndex];
                            const auto colorARGB = [UIColorFromARGB([gpxTrack getColor:kDefaultTrackColor]) toFColorARGB];
                            segmentColors.push_back(colorARGB);
                        }
                        segStartIndex += points.size() - 1;
                        if (!gpx.joinSegments || !segmentColors.isEmpty())
                        {
                            [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue]];
                            points.clear();
                            segmentColors.clear();
                        }
                    }
                }
                if (gpx.joinSegments && segmentColors.isEmpty())
                {
                    [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue]];
                }
            }
            else if (doc_->hasRtePt())
            {
                for (const auto& route : doc_->routes)
                {
                    QVector<OsmAnd::PointI> points;
                    for (const auto& pt : route->points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                    }
                    [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:{} colorizationScheme:COLORIZATION_NONE];
                }
            }
        }
        [self.mapView addKeyedSymbolsProvider:_linesCollection];
    }
    [self setVectorLineProvider:_linesCollection];
    [self refreshGpxWaypoints];
    [self refreshStartFinishPoints];
}

- (void) drawLine:(QVector<OsmAnd::PointI> &)points
              gpx:(OAGPX *)gpx
        baseOrder:(int)baseOrder
           lineId:(int)lineId
           colors:(const QList<OsmAnd::FColorARGB> &)colors
colorizationScheme:(int)colorizationScheme
{
    if (points.size() > 1)
    {
        CGFloat lineWidth;
        if ([_cachedTrackWidth.allKeys containsObject:gpx.width])
        {
            lineWidth = _cachedTrackWidth[gpx.width].floatValue;
        }
        else
        {
            lineWidth = [self getLineWidth:gpx.width];
            _cachedTrackWidth[gpx.width] = @(lineWidth);
        }

        // Add outline for colorized lines
        if (!colors.isEmpty() && colorizationScheme != COLORIZATION_NONE)
        {
            OsmAnd::VectorLineBuilder outlineBuilder;
            outlineBuilder.setBaseOrder(baseOrder--)
                .setIsHidden(points.size() == 0)
                .setLineId(lineId + 1000)
                .setLineWidth(lineWidth + kOutlineWidth)
                .setOutlineWidth(kOutlineWidth)
                .setPoints(points)
                .setFillColor(kOutlineColor)
                .setApproximationEnabled(false);
            
            outlineBuilder.buildAndAddToCollection(_linesCollection);
        }

        OsmAnd::FColorARGB colorARGB;
        if (gpx.color != 0)
        {
            colorARGB = OsmAnd::ColorARGB((int) gpx.color);
        }
        else
        {
            if (!colors.isEmpty() && colorizationScheme == COLORIZATION_NONE)
                colorARGB = colors[0];
            else
                colorARGB = [UIColorFromRGB(kDefaultTrackColor) toFColorARGB];
        }

        OsmAnd::VectorLineBuilder builder;
        builder.setBaseOrder(baseOrder)
            .setIsHidden(points.size() == 0)
            .setLineId(lineId)
            .setLineWidth(lineWidth)
            .setPoints(points)
            .setFillColor(colorARGB);

        if (!colors.empty() && colorizationScheme != COLORIZATION_NONE)
        {
            builder.setColorizationMapping(colors)
                .setColorizationScheme(colorizationScheme);
        }
        
        if (gpx.showArrows)
        {
            // Use black arrows for gradient colorization
            UIColor *color = gpx.coloringType.length != 0 && ![gpx.coloringType isEqualToString:@"solid"] ? UIColor.whiteColor : UIColorFromARGB(gpx.color);
            builder.setPathIcon([self bitmapForColor:color fileName:@"map_direction_arrow"])
                .setSpecialPathIcon([self specialBitmapWithColor:colorARGB])
                .setShouldShowArrows(true)
                .setScreenScale(UIScreen.mainScreen.scale);
        }
        
        builder.buildAndAddToCollection(_linesCollection);
    }
}

- (void) refreshStartFinishPoints
{
    if (_startFinishProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_startFinishProvider];
        _startFinishProvider = nullptr;
    }
    
    QList<OsmAnd::PointI> startFinishPoints;
    QList<OsmAnd::GpxAdditionalIconsProvider::SplitLabel> splitLabels;
    const auto& activeGpx = OASelectedGPXHelper.instance.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        OAGPXDatabase *gpxDb = OAGPXDatabase.sharedDb;
        path = [[gpxDb getFileDir:path] stringByAppendingPathComponent:path.lastPathComponent];
        OAGPX *gpx = [gpxDb getGPXItem:path];
        if (gpx.showStartFinish)
        {
            const auto& doc = it.value();
            if (!doc)
                continue;
            const auto& tracks = doc->tracks;
            OsmAnd::LatLon start, finish;
            for (const auto& trk : constOf(tracks))
            {
                const auto& segments = constOf(trk->segments);
                for (int i = 0; i < segments.size(); i++)
                {
                    const auto& seg = segments[i];
                    if (gpx.joinSegments)
                    {
                        if (i == 0)
                            start = seg->points.first()->position;
                        else if (i == segments.size() - 1)
                            finish = seg->points.last()->position;
                    }
                    else
                    {
                        startFinishPoints.append({
                            OsmAnd::Utilities::convertLatLonTo31(seg->points.first()->position),
                            OsmAnd::Utilities::convertLatLonTo31(seg->points.last()->position)});
                    }
                }
            }
            if (gpx.joinSegments)
            {
                startFinishPoints.append({
                    OsmAnd::Utilities::convertLatLonTo31(start),
                    OsmAnd::Utilities::convertLatLonTo31(finish)});
            }
        }
        if (gpx.splitType != EOAGpxSplitTypeNone)
        {
            OAGPXDocument *document = [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(it.value())];
            NSArray<OAGPXTrackAnalysis *> *splitData = nil;
            BOOL splitByTime = NO;
            BOOL splitByDistance = NO;
            switch (gpx.splitType) {
                case EOAGpxSplitTypeDistance: {
                    splitData = [document splitByDistance:gpx.splitInterval joinSegments:gpx.joinSegments];
                    splitByDistance = YES;
                    break;
                }
                case EOAGpxSplitTypeTime: {
                    splitData = [document splitByTime:gpx.splitInterval joinSegments:gpx.joinSegments];
                    splitByTime = YES;
                    break;
                }
                default:
                    break;
            }
            if (splitData && (splitByDistance || splitByTime))
            {
                for (NSInteger i = 1; i < splitData.count; i++)
                {
                    OAGPXTrackAnalysis *seg = splitData[i];
                    double metricStartValue = splitData[i - 1].metricEnd;
                    OAWptPt *pt = seg.locationStart;
                    if (pt)
                    {
                        const auto pos31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude));
                        QString stringValue;
                        if (splitByDistance)
                            stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedDistance:metricStartValue]);
                        else if (splitByTime)
                            stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedTimeInterval:metricStartValue shortFormat:YES]);

                        splitLabels.push_back(OsmAnd::GpxAdditionalIconsProvider::SplitLabel(pos31, stringValue, OsmAnd::ColorARGB((uint32_t) gpx.color)));
                    }
                }
            }
        }
    }
    
    _startFinishProvider.reset(new OsmAnd::GpxAdditionalIconsProvider(
        -120000, UIScreen.mainScreen.scale, startFinishPoints, splitLabels,
        [OANativeUtilities skImageFromPngResource:@"map_track_point_start"],
        [OANativeUtilities skImageFromPngResource:@"map_track_point_finish"],
        [OANativeUtilities skImageFromPngResource:@"map_track_point_start_finish"]));
        
    [self.mapView addTiledSymbolsProvider:_startFinishProvider];
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
        QList<OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>> points;
        QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> >::iterator it;
        for (it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            if (!it.value())
                continue;
            
            if (!it.value()->points.empty())
            {
                NSString *filePath = it.key().toNSString();
                OAGPX *gpx = [_cachedTracks.allKeys containsObject:filePath]
                        ? _cachedTracks[filePath][@"gpx"]
                        : it.key().isNull()
                                ? [[OASavingTrackHelper sharedInstance] getCurrentGPX]
                                : [self getGpxItem:it.key()];
                for (const auto& waypoint : it.value()->points)
                {
                    if (![gpx.hiddenGroups containsObject:waypoint->type.toNSString()])
                        points.append(waypoint);
                }
            }
        }
        
        const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
        QList<OsmAnd::PointI> hiddenPoints;
        if (_hiddenPointPos31 != OsmAnd::PointI())
            hiddenPoints.append(_hiddenPointPos31);
        
        _waypointsMapProvider.reset(new OAWaypointsMapLayerProvider(points, self.baseOrder - points.count() - 1, hiddenPoints,
                                                                    self.showCaptions, self.captionStyle, self.captionTopSpace, rasterTileSize));
        [self.mapView addTiledSymbolsProvider:_waypointsMapProvider];
    }
}

- (CGFloat)getLineWidth:(NSString *)gpxWidth
{
    CGFloat lineWidth = kDefaultWidthMultiplier;
    if (gpxWidth.length > 0 && self.appearanceCollection)
    {
        OAGPXTrackWidth *trackWidth = [self.appearanceCollection getWidthForValue:gpxWidth];
        if (trackWidth)
        {
            if ([trackWidth isCustom])
            {
                if (trackWidth.customValue.floatValue > [OAGPXTrackWidth getCustomTrackWidthMax])
                    lineWidth = [OAGPXTrackWidth getDefault].customValue.floatValue;
                else
                    lineWidth = trackWidth.customValue.floatValue;
            }
            else
            {
                double width = DBL_MIN;
                NSArray<NSArray<NSNumber *> *> *allValues = trackWidth.allValues;
                for (NSArray<NSNumber *> *values in allValues)
                {
                    width = fmax(values[2].intValue, width);
                }
                lineWidth = width;
            }
        }
    }

    return lineWidth * kWidthCorrectionValue;
}

- (int) getDefaultRadiusPoi
{
    int r;
    double zoom = self.mapView.zoom;
    if (zoom <= 15) {
        r = 10;
    } else if (zoom <= 16) {
        r = 14;
    } else if (zoom <= 17) {
        r = 16;
    } else {
        r = 18;
    }
    return (int) (r * self.mapView.displayDensityFactor);
}

- (void) getTracksFromPoint:(CLLocationCoordinate2D)point res:(NSMutableArray<OATargetPoint *> *)res
{
    double textSize = [OAAppSettings.sharedManager.textSize get];
    textSize = textSize < 1. ? 1. : textSize;
    int r = [self getDefaultRadiusPoi] * textSize;
    auto activeGpx = OASelectedGPXHelper.instance.activeGpx;

    auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>([[OASavingTrackHelper sharedInstance].currentTrack getDocument]);
    if (doc)
        activeGpx.insert(QString::fromNSString(kCurrentTrack), doc);

    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        BOOL isCurrentTrack = doc != nullptr && it.value() == doc;
        OAGPXDocument *document;
        NSString *filePath = isCurrentTrack ? kCurrentTrack : it.key().toNSString();
        if ([_cachedTracks.allKeys containsObject:filePath])
        {
            document = _cachedTracks[filePath][@"doc"];
        }
        else
        {
            document = isCurrentTrack
                    ? [OASavingTrackHelper sharedInstance].currentTrack
                    : [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(it.value())];
        }

        NSArray<OAWptPt *> *points = [self findPointsNearSegments:[document getPointsToDisplay] radius:r point:point];
        if (points != nil)
        {
            CLLocation *selectedGpxPoint = [OAMapUtils getProjection:[[CLLocation alloc] initWithLatitude:point.latitude
                                                                                                longitude:point.longitude]
                                                        fromLocation:[[CLLocation alloc] initWithLatitude:points.firstObject.position.latitude
                                                                                                longitude:points.firstObject.position.longitude]
                                                          toLocation:[[CLLocation alloc] initWithLatitude:points.lastObject.position.latitude
                                                                                                longitude:points.lastObject.position.longitude]];

            OAGPX *gpx = [_cachedTracks.allKeys containsObject:filePath] ? _cachedTracks[filePath][@"gpx"]
                    : isCurrentTrack ? [[OASavingTrackHelper sharedInstance] getCurrentGPX] : [self getGpxItem:it.key()];
            OATargetPoint *targetPoint = [self getTargetPoint:gpx];
            targetPoint.location = selectedGpxPoint.coordinate;
            if (targetPoint && ![res containsObject:targetPoint])
                [res addObject:targetPoint];
        }
    }
}

- (NSArray<OAWptPt *> *)findPointsNearSegments:(NSArray<OATrkSegment *> *)segments radius:(int)radius point:(CLLocationCoordinate2D)point
{
    const auto screenBbox = self.mapView.getVisibleBBox31;
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
    QuadRect *screenRect = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
    for (OATrkSegment *segment in segments)
    {
        QuadRect *trackBounds = [self.class calculateBounds:segment.points];
        if ([QuadRect intersects:screenRect b:trackBounds])
        {
            NSArray<OAWptPt *> *points = [self.class findPointsNearSegment:segment.points radius:radius point:point];
            if (points != nil)
                return points;
        }
    }
    return nil;
}

+ (QuadRect *) calculateBounds:(NSArray<OAWptPt *> *)pts
{
    return [self updateBounds:pts startIndex:0];
}

+ (QuadRect *) updateBounds:(NSArray<OAWptPt *> *)pts startIndex:(int)startIndex
{
    double left = DBL_MAX, top = DBL_MIN, right = DBL_MIN, bottom = DBL_MAX;
    for (NSInteger i = startIndex; i < pts.count; i++)
    {
        OAWptPt *pt = pts[i];
        right = MAX(right, pt.position.longitude);
        left = MIN(left, pt.position.longitude);
        top = MAX(top, pt.position.latitude);
        bottom = MIN(bottom, pt.position.latitude);
    }
    return [[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
}

+ (int) placeInBbox:(int)x y:(int)y mx:(int)mx my:(int)my halfw:(int)halfw halfh:(int)halfh
{
    int cross = 0;
    cross |= (x < mx - halfw ? 1 : 0);
    cross |= (x > mx + halfw ? 2 : 0);
    cross |= (y < my - halfh ? 4 : 0);
    cross |= (y > my + halfh ? 8 : 0);
    return cross;
}

+ (NSArray<OAWptPt *> *) findPointsNearSegment:(NSArray<OAWptPt *> *)points radius:(int)r point:(CLLocationCoordinate2D)coordinatePoint
{
    if (points.count == 0)
        return nil;
    
    CGPoint point;
    auto coordI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(coordinatePoint.latitude, coordinatePoint.longitude));
    if (![OARootViewController.instance.mapPanel.mapViewController.mapView convert:&coordI toScreen:&point checkOffScreen:YES])
        return nil;
    
    OAWptPt *prevPoint = points.firstObject;
    auto prevPointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(prevPoint.position.latitude, prevPoint.position.longitude));
    CGPoint prevPxPoint;
    [OARootViewController.instance.mapPanel.mapViewController.mapView convert:&prevPointI toScreen:&prevPxPoint checkOffScreen:YES];
    int pcross = [self placeInBbox:prevPxPoint.x y:prevPxPoint.y mx:point.x my:point.y halfw:r halfh:r];
    for (NSInteger i = 1; i < points.count; i++)
    {
        OAWptPt *pnt = points[i];
        auto ptI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pnt.position.latitude, pnt.position.longitude));
        CGPoint ptPx;
        if (![OARootViewController.instance.mapPanel.mapViewController.mapView convert:&ptI toScreen:&ptPx checkOffScreen:YES])
            continue;
        int cross = [self placeInBbox:ptPx.x y:ptPx.y mx:point.x my:point.y halfw:r halfh:r];
        if (cross == 0)
            return @[prevPoint, pnt];

        if ((pcross & cross) == 0)
        {
            int mpx = ptPx.x;
            int mpy = ptPx.y;
            int mcross = cross;
            while (fabs(mpx - prevPxPoint.x) > r || fabs(mpy - prevPxPoint.y) > r)
            {
                int mpxnew = mpx / 2 + prevPxPoint.x / 2;
                int mpynew = mpy / 2 + prevPxPoint.y / 2;
                int mcrossnew = [self placeInBbox:mpxnew y:mpynew mx:point.x my:point.y halfw:r halfh:r];
                if (mcrossnew == 0) {
                    return @[prevPoint, pnt];
                }
                if ((mcrossnew & mcross) != 0)
                {
                    mpx = mpxnew;
                    mpy = mpynew;
                    mcross = mcrossnew;
                } else if ((mcrossnew & pcross) != 0)
                {
                    prevPxPoint = CGPointMake(mpxnew, mpynew);
                    pcross = mcrossnew;
                }
                else
                {
                    // this should never happen theoretically
                    break;
                }
            }
        }
        pcross = cross;
        prevPxPoint = ptPx;
        prevPoint = pnt;
    }
    return nil;
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OAGPX class]])
    {
        OAGPX *item = (OAGPX *) obj;
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetGPX;
        targetPoint.targetObj = item;

        targetPoint.icon = [UIImage imageNamed:@"ic_custom_trip"];
        targetPoint.title = [item getNiceTitle];

        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        targetPoint.values = @{ @"opened_from_map": @YES };

        return targetPoint;
    }
    else if ([obj isKindOfClass:[OAGpxWptItem class]])
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
    if (!symbolInfo && !unknownLocation)
    {
        [self getTracksFromPoint:point res:found];
    }
    else if (symbolInfo)
    {
        if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo->mapSymbol->groupPtr) && [mapViewController findWpt:point])
        {
            OAWptPt *wpt = mapViewController.foundWpt;
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
            const auto& doc = activeGpx[QString::fromNSString(item.docPath)];
            if (doc != nullptr)
            {
                doc->saveTo(QString::fromNSString(item.docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
                QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> > docs;
                docs[QString::fromNSString(item.docPath)] = doc;
                [self refreshGpxTracks:docs];
            }
        }
        else
        {
            OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
            [helper updatePointCoordinates:item.point newLocation:position];
            item.point.wpt->position = OsmAnd::LatLon(position.latitude, position.longitude);
            [self.app.updateRecTrackOnMapObservable notifyEventWithKey:@(YES)];
        }
    }
}

- (UIImage *) getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        if ([OARootViewController instance].mapPanel.activeTargetType == OATargetNewMovableWpt)
            return [UIImage imageNamed:@"ic_map_pin"];

        OAGpxWptItem *point = (OAGpxWptItem *)object;
        return [OAFavoritesLayer getImageWithColor:point.color background:point.point.getBackgroundIcon icon:[@"mx_" stringByAppendingString:point.point.getIcon]];
    }
    OAFavoriteColor *def = [OADefaultFavorite nearestFavColor:OADefaultFavorite.builtinColors.firstObject];
    return [OAFavoritesLayer getImageWithColor:def.color background:@"circle" icon:[@"mx_" stringByAppendingString:DEFAULT_ICON_NAME]];
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
