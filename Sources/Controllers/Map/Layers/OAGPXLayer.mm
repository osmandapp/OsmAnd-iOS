//
//  OAGPXLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXLayer.h"
#import "OAAppData.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
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
#import "OARouteColorize.h"
#import "OARouteColorize+cpp.h"
#import "OAGPXAppearanceCollection.h"
#import "QuadRect.h"
#import "OAMapUtils.h"
#import "OARouteImporter.h"
#import "OAAppVersion.h"
#import "OAGpxTrackAnalysis.h"
#import "OAOsmAndFormatter.h"
#import "OAAtomicInteger.h"
#import "OACompoundIconUtils.h"
#import "OAObservable.h"
#import "OAColoringType.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/GpxAdditionalIconsProvider.h>
#include <OsmAndCore/SingleSkImage.h>

static const CGFloat kSpeedToHeightScale = 10.0;
static const CGFloat kTemperatureToHeightOffset = 100.0;

@interface OAGPXLayer ()

@property (nonatomic) OAGPXAppearanceCollection *appearanceCollection;

@end

@implementation OAGPXLayer
{
    std::shared_ptr<OAWaypointsMapLayerProvider> _waypointsMapProvider;
    std::shared_ptr<OsmAnd::GpxAdditionalIconsProvider> _startFinishProvider;
    BOOL _showCaptionsCache;
    OsmAnd::PointI _hiddenPointPos31;
    double _textScaleFactor;
    double _elevationScaleFactor;

    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *_cachedTracks;
    QHash< QString, QList<OsmAnd::FColorARGB> > _cachedColors;
    QHash< QString, QList<OsmAnd::FColorARGB> > _cachedWallColors;
    NSMutableDictionary<NSString *, NSNumber *> *_cachedTrackWidth;
    
    NSOperationQueue *_splitLabelsQueue;
    NSObject* _splitLock;
    OAAtomicInteger *_splitCounter;
    QList<OsmAnd::PointI> _startFinishPoints;
    QList<float> _startFinishPointsElevations;
    QList<OsmAnd::GpxAdditionalIconsProvider::SplitLabel> _splitLabels;
    OASRTMPlugin *_plugin;
}

- (NSString *) layerId
{
    return kGpxLayerId;
}

- (void) initLayer
{
    [super initLayer];

    _splitLock = [[NSObject alloc] init];
    _splitLabelsQueue = [[NSOperationQueue alloc] init];
    
    _hiddenPointPos31 = OsmAnd::PointI();
    _showCaptionsCache = self.showCaptions;
    _textScaleFactor = [[OAAppSettings sharedManager].textSize get];

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();

    [self.mapView addKeyedSymbolsProvider:_linesCollection];

    _cachedTracks = [NSMutableDictionary dictionary];
    _cachedTrackWidth = [NSMutableDictionary dictionary];
    
    _plugin = (OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class];
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
    if (![super updateLayer])
        return NO;

    CGFloat textScaleFactor = [[OAAppSettings sharedManager].textSize get];
    if (self.showCaptions != _showCaptionsCache || _textScaleFactor != textScaleFactor)
    {
        _showCaptionsCache = self.showCaptions;
        _textScaleFactor = textScaleFactor;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshGpxWaypoints];
            [self refreshStartFinishPoints];
        });
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    });

    return YES;
}

- (void) refreshGpxTracks:(QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> >)gpxDocs reset:(BOOL)reset refreshColors:(BOOL)refreshColors
{
    if (reset)
        [self resetLayer];

    _gpxDocs = gpxDocs;
    [self refreshCachedTracks];
    [self refreshGpxTracks:refreshColors];
}

- (void)refreshCachedTracks
{
    if (_cachedTracks.count > 0)
    {
        [_cachedTracks.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            QString qKey = QString::fromNSString(key);
            if (!_gpxDocs.contains(qKey))
            {
                [_cachedTracks removeObjectForKey:key];
                _cachedColors.remove(qKey);
                _cachedWallColors.remove(qKey);
            }
        }];
    }
    
    for (auto it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
    {
        if (!it.value())
            continue;
        NSString *key = it.key().toNSString();
        if (![_cachedTracks.allKeys containsObject:key] || [key isEqualToString:kCurrentTrack])
            [self addTrackToCached:it.key() value:it.value()];
    }
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

- (void)addTrackToCached:(QString)key value:(std::shared_ptr<const OsmAnd::GpxDocument>)value
{
    if (!value)
        return;

    BOOL isCurrentTrack = [key.toNSString() isEqualToString:kCurrentTrack];
    NSString *filePath = key.toNSString();
    if (![_cachedTracks.allKeys containsObject:filePath] || isCurrentTrack)
    {
        OAGPX *gpx;
        OAGPXDocument *doc;
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
            doc = [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(value)];
            doc.path = gpx.absolutePath;
        }
        
        NSMutableDictionary<NSString *, id> *cachedTrack = [NSMutableDictionary dictionary];
        cachedTrack[@"gpx"] = gpx;
        cachedTrack[@"doc"] = doc;
        cachedTrack[@"colorization_scheme"] = @(COLORIZATION_NONE);
        cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
        cachedTrack[@"prev_color_palette"] = gpx.gradientPaletteName.length > 0 ? gpx.gradientPaletteName : @"default";
        cachedTrack[@"prev_wall_coloring_type"] = @(gpx.visualization3dWallColorType);
        _cachedTracks[filePath] = cachedTrack;
        _cachedColors[key] = QList<OsmAnd::FColorARGB>();
        _cachedWallColors[key] = QList<OsmAnd::FColorARGB>();
    }
}

- (void)configureCachedWallColorsFor:(OAColoringType *)type
                                 doc:(OAGPXDocument *)doc
                                 key:(QString)key
                            analysis:(OAGPXTrackAnalysis *_Nullable)analysis
               shouldCheckColorCache:(BOOL)shouldCheckColorCache
                     gradientPalette:(NSString *)gradientPalette
{
    // if color type line and wall type are equal, we try to select calculated data from _cachedColors
    if (shouldCheckColorCache && !_cachedColors[key].isEmpty())
    {
        _cachedWallColors[key] = _cachedColors[key];
    }
    else
    {
        ColorPalette *palette =
            [[ColorPaletteHelper shared] getGradientColorPaletteSync:(ColorizationType) [type toColorizationType]
                                                 gradientPaletteName:gradientPalette
                                                             refresh:NO];
        OARouteColorize *routeColorize =
            [[OARouteColorize alloc] initWithGpxFile:doc
                                            analysis:analysis ?: [doc getAnalysis:0]
                                                type:[type toColorizationType]
                                             palette:palette
                                     maxProfileSpeed:0];
        _cachedWallColors[key].clear();
        if (routeColorize)
            _cachedWallColors[key].append([routeColorize getResultQList]);
    }
}

- (void) refreshGpxTracks:(BOOL)refreshColors
{
    BOOL hasVolumetricSymbols;
    for (NSMutableDictionary<NSString *, id> *cachedTrack in _cachedTracks.allValues)
    {
        OAGPX *gpx = cachedTrack[@"gpx"];
        OAGPXDocument *doc = cachedTrack[@"doc"];
        if (gpx.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone && [doc hasTrkPtWithElevation])
        {
            hasVolumetricSymbols = YES;
            break;
        }
    }
    if (_linesCollection->hasVolumetricSymbols != hasVolumetricSymbols)
        _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>(hasVolumetricSymbols);

    if (!_gpxDocs.empty())
    {
        int baseOrder = self.baseOrder;
        int lineId = 1;
        for (auto it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
        {
            if (!it.value())
                continue;
            auto doc_ = std::const_pointer_cast<OsmAnd::GpxDocument>(it.value());
            QString key = it.key();
            NSString *keyStr = key.toNSString();
            BOOL isCurrentTrack = [keyStr isEqualToString:kCurrentTrack];
            NSMutableDictionary<NSString *, id> *cachedTrack = _cachedTracks[keyStr];
            OAGPX *gpx = cachedTrack[@"gpx"];
            OAGPXDocument *doc = cachedTrack[@"doc"];
            if (!gpx || !doc)
                continue;
            
            OAColoringType *type = gpx.coloringType.length > 0
            ? [OAColoringType getNonNullTrackColoringTypeByName:gpx.coloringType]
            : OAColoringType.TRACK_SOLID;
            
            BOOL isAvailable = [type isAvailableInSubscription];
            if (!isAvailable)
                type = OAColoringType.DEFAULT;
            
            OAGPXTrackAnalysis *analysis;
            
            if ([type isGradient]
                && (![cachedTrack[@"prev_coloring_type"] isEqualToString:gpx.coloringType]
                    || ![cachedTrack[@"prev_color_palette"] isEqualToString:gpx.gradientPaletteName]
                    || [cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_GRADIENT
                    || _cachedColors[key].isEmpty()))
            {
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_GRADIENT);
                cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
                cachedTrack[@"prev_color_palette"] = gpx.gradientPaletteName.length > 0 ? gpx.gradientPaletteName : @"default";
                BOOL shouldCalculateColorCache = YES;
                // check if we already have a cached array of wall color points that can be reused for route line color, provided that the coloring type matches
                switch (gpx.visualization3dWallColorType)
                {
                    case EOAGPX3DLineVisualizationWallColorTypeAltitude:
                        shouldCalculateColorCache = !([type isAltitude] && !_cachedWallColors[key].isEmpty());
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSlope:
                        shouldCalculateColorCache = !([type isSlope] && !_cachedWallColors[key].isEmpty());
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSpeed:
                        shouldCalculateColorCache = !([type isSpeed] && !_cachedWallColors[key].isEmpty());
                        break;
                    default:
                        break;
                }

                if (shouldCalculateColorCache)
                {
                    analysis = [doc getAnalysis:0];
                    ColorPalette *palette =
                        [[ColorPaletteHelper shared] getGradientColorPaletteSync:(ColorizationType) [type toColorizationType]
                                                             gradientPaletteName:cachedTrack[@"prev_color_palette"]
                                                                         refresh:refreshColors];
                    OARouteColorize *routeColorize =
                        [[OARouteColorize alloc] initWithGpxFile:doc
                                                        analysis:analysis
                                                            type:[type toColorizationType]
                                                         palette:palette
                                                 maxProfileSpeed:0];
                    _cachedColors[key].clear();
                    if (routeColorize)
                        _cachedColors[key].append([routeColorize getResultQList]);
                }
                else
                {
                    _cachedColors[key] = _cachedWallColors[key];
                }
            }
            else if ([type isRouteInfoAttribute]
                     && (![cachedTrack[@"prev_coloring_type"] isEqualToString:gpx.coloringType]
                         || ![cachedTrack[@"prev_color_palette"] isEqualToString:gpx.gradientPaletteName]
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
                cachedTrack[@"prev_color_palette"] = gpx.gradientPaletteName.length > 0 ? gpx.gradientPaletteName : @"default";
                _cachedColors[key].clear();
                [self calculateSegmentsColor:_cachedColors[key]
                                    attrName:gpx.coloringType
                               segmentResult:segs
                                   locations:locations];
            }
            else if ([type isSolidSingleColor]
                     && ([cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_NONE
                         || ![cachedTrack[@"prev_color_palette"] isEqualToString:gpx.gradientPaletteName]
                         || !_cachedColors[key].isEmpty()))
            {
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_NONE);
                cachedTrack[@"prev_coloring_type"] = gpx.coloringType;
                cachedTrack[@"prev_color_palette"] = gpx.gradientPaletteName.length > 0 ? gpx.gradientPaletteName : @"default";
                _cachedColors[key].clear();
            }
            
            if (cachedTrack[@"prev_wall_coloring_type"] != @(gpx.visualization3dWallColorType) || _cachedWallColors[key].isEmpty())
            {
                switch (gpx.visualization3dWallColorType)
                {
                    case EOAGPX3DLineVisualizationWallColorTypeAltitude:
                        [self configureCachedWallColorsFor:OAColoringType.ALTITUDE
                                                       doc:doc
                                                       key:key
                                                  analysis:analysis
                                     shouldCheckColorCache:[type isAltitude]
                                           gradientPalette:cachedTrack[@"prev_color_palette"]];
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSlope:
                        [self configureCachedWallColorsFor:OAColoringType.SLOPE
                                                       doc:doc
                                                       key:key
                                                  analysis:analysis
                                     shouldCheckColorCache:[type isSlope]
                                           gradientPalette:cachedTrack[@"prev_color_palette"]];
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSpeed:
                        [self configureCachedWallColorsFor:OAColoringType.SPEED
                                                       doc:doc
                                                       key:key
                                                  analysis:analysis
                                     shouldCheckColorCache:[type isSpeed]
                                           gradientPalette:cachedTrack[@"prev_color_palette"]];
                        break;
                    default:
                        _cachedWallColors[key].clear();
                        break;
                }
                cachedTrack[@"prev_wall_coloring_type"] = @(gpx.visualization3dWallColorType);
            }

            if (doc_->hasTrkPt())
            {
                int segStartIndex = 0;
                QVector<OsmAnd::PointI> points;
                NSMutableArray *elevations = [NSMutableArray array];
                QList<OsmAnd::FColorARGB> segmentColors;
                QList<OsmAnd::FColorARGB> segmentWallColors;
                NSArray<OATrack *> *tracks = [doc getTracks:NO];
                if ([self isSensorLineVisualizationType:gpx.visualization3dByType])
                {
                    [self processGPXDataElements:doc.tracks withGPX:gpx addToElevations:elevations];
                }
                for (const auto& track : doc_->tracks)
                {
                    for (const auto& seg : track->segments)
                    {
                        for (const auto& pt : seg->points)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                            double elevationValue = [self getValidElevation:pt->elevation];
                            switch (gpx.visualization3dByType)
                            {
                                case EOAGPX3DLineVisualizationByTypeAltitude:
                                    [elevations addObject:@(pt->elevation)];
                                    break;
                                case EOAGPX3DLineVisualizationByTypeSpeed:
                                    [elevations addObject:@([self is3DMapsEnabled] ? (pt->speed * kSpeedToHeightScale) + elevationValue : pt->speed * kSpeedToHeightScale)];
                                    break;
                                case EOAGPX3DLineVisualizationByTypeFixedHeight:
                                    [elevations addObject:@([self is3DMapsEnabled] ? elevationValue + gpx.elevationMeters : gpx.elevationMeters)];
                                    break;
                                default:
                                    break;
                            }
                        }
                        if (points.size() > 1 && !_cachedWallColors[key].isEmpty() && segStartIndex < _cachedWallColors[key].size() && segStartIndex + seg->points.size() - 1 < _cachedWallColors[key].size())
                        {
                            segmentWallColors.append(_cachedWallColors[key].mid(segStartIndex, seg->points.size()));
                        }
                        if (points.size() > 1 && !_cachedColors[key].isEmpty() && segStartIndex < _cachedColors[key].size() && segStartIndex + seg->points.size() - 1 < _cachedColors[key].size())
                        {
                            segmentColors.append(_cachedColors[key].mid(segStartIndex, seg->points.size()));
                        }
                        else if ([cachedTrack[@"colorization_scheme"] intValue] == COLORIZATION_NONE && segmentColors.isEmpty() && gpx.color == 0)
                        {
                            int trackIndex = doc_->tracks.indexOf(track);
                            OATrack *gpxTrack = tracks[trackIndex];
                            const auto colorARGB = [UIColorFromARGB([gpxTrack getColor:kDefaultTrackColor]) toFColorARGB];
                            segmentColors.push_back(colorARGB);
                        }
                        segStartIndex += seg->points.count();
                        if (!gpx.joinSegments)
                        {
                            if (isCurrentTrack)
                            {
                                [self refreshLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
                            }
                            else
                            {
                                [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
                            }
                            points.clear();
                            segmentColors.clear();
                            segmentWallColors.clear();
                            [elevations removeAllObjects];
                        }
                    }
                }
                if (gpx.joinSegments)
                {
                    if (isCurrentTrack)
                    {
                        [self refreshLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
                    }
                    else
                    {
                        [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
                    }
                }
            }
            else if (doc_->hasRtePt())
            {
                NSMutableArray *elevations = [NSMutableArray array];
                if ([self isSensorLineVisualizationType:gpx.visualization3dByType])
                {
                    [self processGPXDataElements:doc.routes withGPX:gpx addToElevations:elevations];
                }
                for (const auto& route : doc_->routes)
                {
                    QVector<OsmAnd::PointI> points;
                    for (const auto& pt : route->points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt->position)));
                        double elevationValue = [self getValidElevation:pt->elevation];
                        switch (gpx.visualization3dByType)
                        {
                            case EOAGPX3DLineVisualizationByTypeAltitude:
                                [elevations addObject:@(pt->elevation)];
                                break;
                            case EOAGPX3DLineVisualizationByTypeSpeed:
                                [elevations addObject:@([self is3DMapsEnabled] ? (pt->speed * kSpeedToHeightScale) + elevationValue : pt->speed * kSpeedToHeightScale)];
                                break;
                            case EOAGPX3DLineVisualizationByTypeFixedHeight:
                                [elevations addObject:@([self is3DMapsEnabled] ? elevationValue + gpx.elevationMeters : gpx.elevationMeters)];
                                break;
                            default:
                                break;
                        }
                    }
                    if (isCurrentTrack)
                    {
                        [self refreshLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:{} segmentWallColors:{} colorizationScheme:COLORIZATION_NONE elevations:elevations];
                    }
                    else
                    {
                        [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:{} segmentWallColors:{} colorizationScheme:COLORIZATION_NONE elevations:elevations];
                    }
                }
            }
        }
        [self.mapView addKeyedSymbolsProvider:_linesCollection];
    }
    [self setVectorLineProvider:_linesCollection sync:YES];
    [self refreshGpxWaypoints];
    [self refreshStartFinishPoints];
}

- (void)processGPXDataElements:(NSArray *)elements withGPX:(OAGPX *)gpx addToElevations:(NSMutableArray *)elevations
{
    for (id element in elements)
    {
        NSArray *points = @[];
        if ([element isKindOfClass:[OATrack class]])
        {
            for (OATrkSegment *segment in [(OATrack *)element segments])
            {
                [self evaluateSensorDataForPoints:segment.points withGPX:gpx addToElevations:elevations];
            }
        }
        else if ([element isKindOfClass:[OARoute class]])
        {
            points = [(OARoute *)element points];
            [self evaluateSensorDataForPoints:points withGPX:gpx addToElevations:elevations];
        }
    }
}

- (void)evaluateSensorDataForPoints:(NSArray *)points withGPX:(OAGPX *)gpx addToElevations:(NSMutableArray *)elevations
{
    for (OAWptPt *point in points)
    {
        if ([self isInstanceOfOAWptPt:point])
        {
            switch (gpx.visualization3dByType)
            {
                case EOAGPX3DLineVisualizationByTypeHeartRate:
                case EOAGPX3DLineVisualizationByTypeBicycleCadence:
                case EOAGPX3DLineVisualizationByTypeBicyclePower:
                case EOAGPX3DLineVisualizationByTypeTemperature:
                case EOAGPX3DLineVisualizationByTypeSpeedSensor:
                    [elevations addObject:@([self processSensorData:point forType:gpx.visualization3dByType])];
                    break;
                default:
                    break;
            }
        }
    }
}

- (float)processSensorData:(OAWptPt *)point forType:(EOAGPX3DLineVisualizationByType)visualizationType
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.decimalSeparator = @".";
    NSString *relevantTag = nil;
    float defaultValue = 0.0;
    BOOL isSpeedSensorTag = NO;
    switch (visualizationType)
    {
        case EOAGPX3DLineVisualizationByTypeHeartRate:
            relevantTag = OAPointAttributes.sensorTagHeartRate;
            break;
        case EOAGPX3DLineVisualizationByTypeBicycleCadence:
            relevantTag = OAPointAttributes.sensorTagCadence;
            break;
        case EOAGPX3DLineVisualizationByTypeBicyclePower:
            relevantTag = OAPointAttributes.sensorTagBikePower;
            break;
        case EOAGPX3DLineVisualizationByTypeTemperature:
            return [self processTemperatureData:point numberFormatter:numberFormatter];
        case EOAGPX3DLineVisualizationByTypeSpeedSensor:
            relevantTag = OAPointAttributes.sensorTagSpeed;
            isSpeedSensorTag = YES;
            break;
        default:
            return NAN;
    }
    
    double elevationValue = [self getValidElevation:point.elevation];
    OAGpxExtension *trackpointextension = [point getExtensionByKey:isSpeedSensorTag ? @"speed_sensor" : @"trackpointextension"];
    if (trackpointextension)
    {
        if (isSpeedSensorTag)
        {
            NSNumber *value = [numberFormatter numberFromString:trackpointextension.value];
            float processedValue = value ? [value floatValue] * kSpeedToHeightScale : defaultValue;
            return [self is3DMapsEnabled] && value ? processedValue + elevationValue : processedValue;
        }
        else
        {
            for (OAGpxExtension *subextension in trackpointextension.subextensions)
            {
                if ([subextension.name isEqualToString:relevantTag])
                {
                    NSNumber *value = [numberFormatter numberFromString:subextension.value];
                    float processedValue = value ? [value floatValue] : defaultValue;
                    return [self is3DMapsEnabled] && value ? processedValue + elevationValue : processedValue;
                }
            }
        }
    }
    
    return defaultValue;
}

- (float)processTemperatureData:(OAWptPt *)point numberFormatter:(NSNumberFormatter *)numberFormatter
{
    OAGpxExtension *trackpointextension = [point getExtensionByKey:@"trackpointextension"];
    NSNumber *waterTempValue = nil;
    NSNumber *airTempValue = nil;
    double elevationValue = [self getValidElevation:point.elevation];
    
    if (trackpointextension)
    {
        for (OAGpxExtension *subextension in trackpointextension.subextensions)
        {
            if ([subextension.name isEqualToString:OAPointAttributes.sensorTagTemperatureW])
            {
                waterTempValue = [numberFormatter numberFromString:subextension.value];
                float processedWaterTemp = waterTempValue ? [waterTempValue floatValue] : NAN;
                return [self is3DMapsEnabled] && waterTempValue ? processedWaterTemp + elevationValue : processedWaterTemp;
            }
            else if ([subextension.name isEqualToString:OAPointAttributes.sensorTagTemperatureA])
            {
                airTempValue = [numberFormatter numberFromString:subextension.value];
                float processedAirTemp = airTempValue ? [airTempValue floatValue] : NAN;
                return [self is3DMapsEnabled] && airTempValue ? processedAirTemp + elevationValue : processedAirTemp;
            }
        }
    }
    
    return NAN;
}

- (void) drawLine:(QVector<OsmAnd::PointI> &)points
              gpx:(OAGPX *)gpx
        baseOrder:(int)baseOrder
           lineId:(int)lineId
           colors:(const QList<OsmAnd::FColorARGB> &)colors
segmentWallColors:(const QList<OsmAnd::FColorARGB> &)segmentWallColors
colorizationScheme:(int)colorizationScheme
       elevations:(NSArray <NSNumber *>* _Nullable)elevations
{
    if (points.size() > 1)
    {
        
        CGFloat lineWidth;
        if (_cachedTrackWidth[gpx.width])
        {
            lineWidth = _cachedTrackWidth[gpx.width].floatValue;
        }
        else
        {
            lineWidth = [self getLineWidth:gpx.width];
            if (gpx)
                _cachedTrackWidth[gpx.width] = @(lineWidth);
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
        
        if (gpx.showArrows)
        {
            // Use black arrows for gradient colorization
            UIColor *color = gpx.coloringType.length != 0 && ![gpx.coloringType isEqualToString:@"solid"] ? UIColor.whiteColor : UIColorFromARGB(gpx.color);
            builder.setPathIcon(OsmAnd::SingleSkImage([self bitmapForColor:color fileName:@"map_direction_arrow"]))
                .setSpecialPathIcon(OsmAnd::SingleSkImage([self specialBitmapWithColor:colorARGB]))
                .setShouldShowArrows(true)
                .setScreenScale(UIScreen.mainScreen.scale);
        }
        
        if (gpx.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone)
        {
            [self configureRaisedLine:builder
                           elevations:elevations
                            colorARGB:colorARGB
                               colors:colors
                    segmentWallColors:segmentWallColors
                                  gpx:gpx
                            lineWidth:lineWidth];
        }
        else
        {
            // Add outline for colorized lines
            if (!colors.isEmpty() && colorizationScheme != COLORIZATION_NONE)
            {
                builder.setOutlineWidth(lineWidth + kOutlineWidth)
                       .setOutlineColor(kOutlineColor);
                builder.setColorizationMapping(colors)
                    .setColorizationScheme(colorizationScheme);
            }
        }
        
        builder.buildAndAddToCollection(_linesCollection);
    }
}

- (void)refreshLine:(QVector<OsmAnd::PointI> &)points
                gpx:(OAGPX *)gpx
          baseOrder:(int)baseOrder
             lineId:(int)lineId
             colors:(const QList<OsmAnd::FColorARGB> &)colors
  segmentWallColors:(const QList<OsmAnd::FColorARGB> &)segmentWallColors
 colorizationScheme:(int)colorizationScheme
         elevations:(NSArray <NSNumber *>* _Nullable)elevations
{
    if (points.size() > 1)
    {
        
        CGFloat lineWidth;
        if (_cachedTrackWidth[gpx.width])
        {
            lineWidth = _cachedTrackWidth[gpx.width].floatValue;
        }
        else
        {
            lineWidth = [self getLineWidth:gpx.width];
            _cachedTrackWidth[gpx.width] = @(lineWidth);
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

        auto line = [self getLineById:lineId];
        if (!line)
        {
            OsmAnd::VectorLineBuilder builder;
            builder.setBaseOrder(baseOrder)
                .setIsHidden(points.size() == 0)
                .setLineId(lineId)
                .setLineWidth(lineWidth)
                .setPoints(points)
                .setFillColor(colorARGB);

            if (gpx.showArrows)
            {
                // Use black arrows for gradient colorization
                UIColor *color = gpx.coloringType.length != 0 && ![gpx.coloringType isEqualToString:@"solid"] ? UIColor.whiteColor : UIColorFromARGB(gpx.color);
                builder.setPathIcon(OsmAnd::SingleSkImage([self bitmapForColor:color fileName:@"map_direction_arrow"]))
                    .setSpecialPathIcon(OsmAnd::SingleSkImage([self specialBitmapWithColor:colorARGB]))
                    .setShouldShowArrows(true)
                    .setScreenScale(UIScreen.mainScreen.scale);
            }
            
            if (gpx.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone)
            {
                [self configureRaisedLine:builder
                               elevations:elevations
                                colorARGB:colorARGB
                                   colors:colors
                        segmentWallColors:segmentWallColors
                                      gpx:gpx
                                lineWidth:lineWidth];
            }
            else
            {
                // Add outline for colorized lines
                if (!colors.isEmpty() && colorizationScheme != COLORIZATION_NONE)
                {
                    builder.setColorizationMapping(colors)
                        .setColorizationScheme(colorizationScheme)
                        .setOutlineWidth(lineWidth + kOutlineWidth)
                        .setOutlineColor(kOutlineColor);
                }
            }
            builder.buildAndAddToCollection(_linesCollection);
        }
        else
        {
            line->setIsHidden(points.size() == 0);
            line->setLineWidth(lineWidth);
            line->setPoints(points);
            line->setFillColor(colorARGB);
            
            line->setColorizationMapping(colors);
            line->setColorizationScheme(colorizationScheme);
            line->setShowArrows(gpx.showArrows);
        }
    }
}

- (OsmAnd::VectorLineBuilder &)configureRaisedLine:(OsmAnd::VectorLineBuilder &)builder
                 elevations:(NSArray <NSNumber *>* _Nullable)elevations
                  colorARGB:(OsmAnd::FColorARGB)colorARGB
                     colors:(const QList<OsmAnd::FColorARGB> &)colors
          segmentWallColors:(const QList<OsmAnd::FColorARGB> &)segmentWallColors
                        gpx:(OAGPX *)gpx
                  lineWidth:(CGFloat)lineWidth
{
    [self configureElevations:elevations elevationScaleFactor:gpx.verticalExaggerationScale builder:builder];
    
    // for setColorizationMapping use: colors or QList<OsmAnd::FColorARGB>()
    builder.setColorizationMapping(colors);
    
    if (!segmentWallColors.isEmpty())
    {
        builder.setOutlineColorizationMapping(segmentWallColors);
    }
    
    // configure visibility for Top and Bottom lines
    [self configureVisualization3dPositionType:gpx.visualization3dPositionType builder:builder];
   
    builder.setOutlineWidth(lineWidth * 2.0f / 2.0f);

    auto visualization3dWallColorType = gpx.visualization3dWallColorType;
    if (visualization3dWallColorType != EOAGPX3DLineVisualizationWallColorTypeNone && visualization3dWallColorType != EOAGPX3DLineVisualizationWallColorTypeSolid)
    {
        builder.setColorizationScheme(1);

        if (segmentWallColors.isEmpty())
        {
            BOOL upwardGradient = gpx.visualization3dWallColorType == EOAGPX3DLineVisualizationWallColorTypeUpwardGradient;
            // 0.0f...1.0f - to set up the 3D projection (wall) of the route line onto the plane.
            builder.setNearOutlineColor(OsmAnd::FColorARGB(upwardGradient ? 0.0f : 1.0f, colorARGB.r, colorARGB.g, colorARGB.b));
            // 1.0f...0.0f - to set up the 3D projection (wall) of the route line onto the plane.
            builder.setFarOutlineColor(OsmAnd::FColorARGB(upwardGradient ? 1.0f : 0.0f, colorARGB.r, colorARGB.g, colorARGB.b));
        }
        else
        {
            // Adjusts the brightness of the 3D projection (wall) of the route line on the plane if it is gradient.
            // (r,g,b) 0.0f...1.0f
            builder.setOutlineColor(OsmAnd::FColorARGB(1.0f, 1.0f, 1.0f, 1.0f));
        }
    }
    else
    {
        // Draw transparent or solid wall
        builder.setOutlineColor(OsmAnd::FColorARGB(gpx.visualization3dWallColorType == EOAGPX3DLineVisualizationWallColorTypeSolid ? 1.0f : 0.0f, colorARGB.r, colorARGB.g, colorARGB.b));
    }
    return builder;
}

- (void)configureElevations:(NSArray <NSNumber *>* _Nullable)elevations
       elevationScaleFactor:(CGFloat)elevationScaleFactor
                    builder:(OsmAnd::VectorLineBuilder &)builder
{
    if (elevations && elevations.count > 0)
    {
        if (builder.getElevationScaleFactor() != elevationScaleFactor)
        {
            builder.setElevationScaleFactor(elevationScaleFactor);
        }
        QList<float> heights;
        for (NSNumber *object in elevations)
        {
            double elevation = [object doubleValue];
            if (!isnan(elevation))
            {
                heights.append(elevation);
            }
        }
        builder.setHeights(heights);
    }
}

- (void)configureVisualization3dPositionType:(EOAGPX3DLineVisualizationPositionType)type
                                     builder:(OsmAnd::VectorLineBuilder &)builder
{
    switch (type)
    {
        case EOAGPX3DLineVisualizationPositionTypeTop:
            builder.setSurfaceLineVisibility(false);
            builder.setElevatedLineVisibility(true);
            break;
        case EOAGPX3DLineVisualizationPositionTypeBottom:
            builder.setElevatedLineVisibility(false);
            builder.setSurfaceLineVisibility(true);
            break;
        case EOAGPX3DLineVisualizationPositionTypeTopBottom:
            builder.setElevatedLineVisibility(true);
            builder.setSurfaceLineVisibility(true);
            break;
        default:
            break;
    }
}

- (std::shared_ptr<OsmAnd::VectorLine>) getLineById:(int)lineId
{
    for (auto& line : _linesCollection->getLines())
    {
        if (line->lineId == lineId)
            return line;
    }
    return nullptr;
}

- (void)processSplitLabels:(OAGPX *)gpx doc:(const std::shared_ptr<const OsmAnd::GpxDocument>)doc
{
    NSBlockOperation* operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation* weakOperation = operation;
    OAAtomicInteger *splitCounter = _splitCounter;

    [operation addExecutionBlock:^{
        if (splitCounter != _splitCounter || weakOperation.isCancelled)
            return;

        OAGPXDocument *document = [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(doc)];
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
            QList<OsmAnd::GpxAdditionalIconsProvider::SplitLabel> splitLabels;
            for (NSInteger i = 1; i < splitData.count; i++)
            {
                if (splitCounter != _splitCounter || weakOperation.isCancelled)
                    break;
                OAGPXTrackAnalysis *seg = splitData[i];
                double metricStartValue = splitData[i - 1].metricEnd;
                OAWptPt *pt = seg.locationStart;
                if (pt)
                {
                    CGFloat splitElevation = NULL;
                    double elevationValue = [self getValidElevation:pt.elevation];
                    switch (gpx.visualization3dByType)
                    {
                        case EOAGPX3DLineVisualizationByTypeAltitude:
                            splitElevation = pt.elevation;
                            break;
                        case EOAGPX3DLineVisualizationByTypeSpeed:
                            splitElevation = [self is3DMapsEnabled] ? (pt.speed * kSpeedToHeightScale) + elevationValue : pt.speed * kSpeedToHeightScale;
                            break;
                        case EOAGPX3DLineVisualizationByTypeHeartRate:
                        case EOAGPX3DLineVisualizationByTypeBicycleCadence:
                        case EOAGPX3DLineVisualizationByTypeBicyclePower:
                        case EOAGPX3DLineVisualizationByTypeTemperature:
                        case EOAGPX3DLineVisualizationByTypeSpeedSensor:
                            splitElevation = [self processSensorData:pt forType:gpx.visualization3dByType];
                            break;
                        case EOAGPX3DLineVisualizationByTypeFixedHeight:
                            splitElevation = [self is3DMapsEnabled] ? elevationValue + gpx.elevationMeters : gpx.elevationMeters;
                            break;
                        default:
                            splitElevation = NAN;
                            break;
                    }
                    
                    const auto pos31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude));
                    QString stringValue;
                    if (splitByDistance)
                        stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedDistance:metricStartValue]);
                    else if (splitByTime)
                        stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedTimeInterval:metricStartValue shortFormat:YES]);
                    const auto colorARGB = [UIColorFromARGB(gpx.color == 0 ? kDefaultTrackColor : gpx.color) toFColorARGB];
                    splitLabels.push_back(OsmAnd::GpxAdditionalIconsProvider::SplitLabel(pos31, stringValue, colorARGB, splitElevation));
                }
            }
            if (splitCounter == _splitCounter && !weakOperation.isCancelled)
                [self appendSplitLabels:splitLabels];
        }
        if (splitCounter == _splitCounter && !weakOperation.isCancelled)
        {
            int counter = [self decrementSplitCounter];
            if (counter == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshStartFinishProvider];
                });
            }
        }
    }];

    [self incrementSplitCounter];
    [_splitLabelsQueue addOperation:operation];
}

- (void) refreshStartFinishPoints
{
    [_splitLabelsQueue cancelAllOperations];
    [_splitLabelsQueue setSuspended:YES];
    [self resetSplitCounter];
    [self clearStartFinishPoints];
    [self clearConfigureStartFinishPointsElevations];
    [self clearSplitLabels];
    _elevationScaleFactor = kGpxExaggerationDefScale;
    if (_startFinishProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_startFinishProvider];
        _startFinishProvider = nullptr;
    }
    
    QList<OsmAnd::PointI> startFinishPoints;
    QList<float> startFinishPointsElevations;
    for (auto it = _gpxDocs.begin(); it != _gpxDocs.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        OAGPXDatabase *gpxDb = OAGPXDatabase.sharedDb;
        path = [[gpxDb getFileDir:path] stringByAppendingPathComponent:path.lastPathComponent];
        OAGPX *gpx = [gpxDb getGPXItem:path];
        OAGPXDocument *gpxFile = [[OAGPXDocument alloc] initWithGpxFile:path];
        const bool raiseRoutesAboveRelief = gpx.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone;
        const auto& doc = it.value();
        if ((!gpx && ![path isEqualToString:kCurrentTrack]) || gpx.showStartFinish)
        {
            if (!doc)
                continue;
            const auto& tracks = doc->tracks;
            OsmAnd::LatLon start, finish;
            CLLocationCoordinate2D startLoc, finishLoc;
            float startPointElevation, finishPointElevation;
            if ([self isSensorLineVisualizationType:gpx.visualization3dByType])
            {
                for (OATrack *track in gpxFile.tracks)
                {
                    NSArray *segments = [NSArray arrayWithArray:track.segments];
                    for (int i = 0; i < segments.count; i++)
                    {
                        OATrkSegment *segment = segments[i];
                        if (segment.points.count < 2)
                            continue;
                        if (gpx.joinSegments)
                        {
                            if (i == 0)
                            {
                                startLoc = segment.points.firstObject.position;
                                if (raiseRoutesAboveRelief)
                                {
                                    _elevationScaleFactor = gpx.verticalExaggerationScale;
                                    startPointElevation = [self processSensorData:segment.points.firstObject forType:gpx.visualization3dByType];
                                }
                            }
                            else if (i == segments.count - 1)
                            {
                                finishLoc = segment.points.lastObject.position;
                                if (raiseRoutesAboveRelief)
                                {
                                    finishPointElevation = [self processSensorData:segment.points.lastObject forType:gpx.visualization3dByType];
                                }
                            }
                        }
                        else
                        {
                            if (raiseRoutesAboveRelief)
                            {
                                _elevationScaleFactor = gpx.verticalExaggerationScale;
                                startFinishPointsElevations.append([self processSensorData:segment.points.firstObject forType:gpx.visualization3dByType]);
                                startFinishPointsElevations.append([self processSensorData:segment.points.lastObject forType:gpx.visualization3dByType]);
                            }
                            startFinishPoints.append(OsmAnd::Utilities::convertLatLonTo31(
                                                                                          OsmAnd::LatLon(segment.points.firstObject.position.latitude, segment.points.firstObject.position.longitude)
                                                                                          ));
                            startFinishPoints.append(OsmAnd::Utilities::convertLatLonTo31(
                                                                                          OsmAnd::LatLon(segment.points.lastObject.position.latitude, segment.points.lastObject.position.longitude)
                                                                                          ));
                        }
                    }
                }
            }
            else
            {
                for (const auto& trk : constOf(tracks))
                {
                    const auto& segments = constOf(trk->segments);
                    for (int i = 0; i < segments.size(); i++)
                    {
                        const auto& seg = segments[i];
                        if (seg->points.count() < 2)
                            continue;
                        double firstPointElevation = [self getValidElevation:seg->points.first()->elevation];
                        double lastPointElevation = [self getValidElevation:seg->points.last()->elevation];
                        if (gpx.joinSegments)
                        {
                            if (i == 0)
                            {
                                start = seg->points.first()->position;
                                if (raiseRoutesAboveRelief)
                                {
                                    _elevationScaleFactor = gpx.verticalExaggerationScale;
                                    if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeAltitude)
                                        startPointElevation = seg->points.first()->elevation;
                                    else if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeSpeed)
                                        startPointElevation = [self is3DMapsEnabled] ? (seg->points.first()->speed * kSpeedToHeightScale) + firstPointElevation : seg->points.first()->speed * kSpeedToHeightScale;
                                    else
                                        startPointElevation = [self is3DMapsEnabled] ? firstPointElevation + gpx.elevationMeters : gpx.elevationMeters;
                                }
                            }
                            else if (i == segments.size() - 1)
                            {
                                finish = seg->points.last()->position;
                                if (raiseRoutesAboveRelief)
                                {
                                    if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeAltitude)
                                        finishPointElevation = seg->points.last()->elevation;
                                    else if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeSpeed)
                                        finishPointElevation = [self is3DMapsEnabled] ? (seg->points.last()->speed * kSpeedToHeightScale) + lastPointElevation : seg->points.last()->speed * kSpeedToHeightScale;
                                    else
                                        finishPointElevation = [self is3DMapsEnabled] ? lastPointElevation + gpx.elevationMeters : gpx.elevationMeters;
                                }
                            }
                        }
                        else
                        {
                            if (raiseRoutesAboveRelief)
                            {
                                _elevationScaleFactor = gpx.verticalExaggerationScale;
                                if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeAltitude)
                                {
                                    startFinishPointsElevations.append(seg->points.first()->elevation);
                                    startFinishPointsElevations.append(seg->points.last()->elevation);
                                }
                                else if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeSpeed)
                                {
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? (seg->points.first()->speed * kSpeedToHeightScale) + firstPointElevation : seg->points.first()->speed * kSpeedToHeightScale);
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? (seg->points.last()->speed * kSpeedToHeightScale) + lastPointElevation : seg->points.last()->speed * kSpeedToHeightScale);
                                }
                                else
                                {
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? firstPointElevation + gpx.elevationMeters : gpx.elevationMeters);
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? lastPointElevation + gpx.elevationMeters : gpx.elevationMeters);
                                }
                            }
                            startFinishPoints.append({
                                OsmAnd::Utilities::convertLatLonTo31(seg->points.first()->position),
                                OsmAnd::Utilities::convertLatLonTo31(seg->points.last()->position)});
                        }
                    }
                }
            }
            if (gpx.joinSegments)
            {
                if (raiseRoutesAboveRelief)
                {
                    startFinishPointsElevations.append(startPointElevation);
                    startFinishPointsElevations.append(finishPointElevation);
                }
                if ([self isSensorLineVisualizationType:gpx.visualization3dByType])
                {
                    startFinishPoints.append(OsmAnd::Utilities::convertLatLonTo31(
                                                                                  OsmAnd::LatLon(startLoc.latitude, startLoc.longitude)
                                                                                  ));
                    startFinishPoints.append(OsmAnd::Utilities::convertLatLonTo31(
                                                                                  OsmAnd::LatLon(finishLoc.latitude, finishLoc.longitude)
                                                                                  ));
                }
                else
                {
                    startFinishPoints.append({
                        OsmAnd::Utilities::convertLatLonTo31(start),
                        OsmAnd::Utilities::convertLatLonTo31(finish)});
                }
            }
        }
        if (gpx.splitType != EOAGpxSplitTypeNone)
            [self processSplitLabels:gpx doc:doc];
    }
    if (!startFinishPoints.isEmpty())
    {
        [self appendStartFinishPoints:startFinishPoints];
        [self configureStartFinishPointsElevations:startFinishPointsElevations];
    }

    [self refreshStartFinishProvider];
    [_splitLabelsQueue setSuspended:NO];
}

- (void) refreshStartFinishProvider
{
    @synchronized(_splitLock)
    {
        if (_startFinishProvider)
        {
            [self.mapView removeTiledSymbolsProvider:_startFinishProvider];
            _startFinishProvider = nullptr;
        }
        
        sk_sp<SkImage> startIcon = [OACompoundIconUtils getScaledIcon:@"map_track_point_start" scale:_textScaleFactor];
        sk_sp<SkImage> finishIcon = [OACompoundIconUtils getScaledIcon:@"map_track_point_finish" scale:_textScaleFactor];
        sk_sp<SkImage> startFinishIcon = [OACompoundIconUtils getScaledIcon:@"map_track_point_start_finish" scale:_textScaleFactor];
        if (startIcon && finishIcon  && startFinishIcon)
        {
            _startFinishProvider.reset(new OsmAnd::GpxAdditionalIconsProvider(self.pointsOrder - 20000,
                                                                              UIScreen.mainScreen.scale,
                                                                              _startFinishPoints,
                                                                              _splitLabels,
                                                                              OsmAnd::SingleSkImage(startIcon),
                                                                              OsmAnd::SingleSkImage(finishIcon),
                                                                              OsmAnd::SingleSkImage(startFinishIcon),
                                                                              _startFinishPointsElevations,
                                                                              _elevationScaleFactor
                                                                              ));
            [self.mapView addTiledSymbolsProvider:_startFinishProvider];
        }
    }
}

- (void) resetSplitCounter
{
    @synchronized(_splitLock)
    {
        _splitCounter = [OAAtomicInteger atomicInteger:0];
    }
}

- (int) incrementSplitCounter
{
    @synchronized(_splitLock)
    {
        return [_splitCounter incrementAndGet];
    }
}

- (int) decrementSplitCounter
{
    @synchronized(_splitLock)
    {
        return [_splitCounter decrementAndGet];
    }
}

- (void) clearStartFinishPoints
{
    @synchronized(_splitLock)
    {
        _startFinishPoints.clear();
    }
}

- (void) appendStartFinishPoints:(QList<OsmAnd::PointI> &)startFinishPoints
{
    @synchronized(_splitLock)
    {
        _startFinishPoints.append(startFinishPoints);
    }
}

- (void)configureStartFinishPointsElevations:(QList<float>)startFinishPointsElevations
{
    @synchronized(_splitLock)
    {
        _startFinishPointsElevations = startFinishPointsElevations;
    }
}

- (void)clearConfigureStartFinishPointsElevations
{
    @synchronized(_splitLock)
    {
        _startFinishPointsElevations.clear();
    }
}

- (void) clearSplitLabels
{
    @synchronized(_splitLock)
    {
        _splitLabels.clear();
    }
}

- (void) appendSplitLabels:(QList<OsmAnd::GpxAdditionalIconsProvider::SplitLabel> &)splitLabels
{
    @synchronized(_splitLock)
    {
        _splitLabels.append(splitLabels);
    }
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
            
        _waypointsMapProvider.reset(new OAWaypointsMapLayerProvider(points, self.pointsOrder - points.count() - 1, hiddenPoints,
                                                                    self.showCaptions, self.captionStyle, self.captionTopSpace, rasterTileSize, _textScaleFactor));
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

- (void)updateCachedGpxItem:(NSString *)filePath
{
    NSMutableDictionary<NSString *, id> *cachedTrack = _cachedTracks[filePath];
    if (cachedTrack)
        cachedTrack[@"gpx"] = [self getGpxItem:QString::fromNSString(filePath)];
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
        OAGPXDocument *document = nil;
        NSString *filePath = isCurrentTrack ? kCurrentTrack : it.key().toNSString();
        if ([_cachedTracks.allKeys containsObject:filePath])
        {
            document = _cachedTracks[filePath][@"doc"];
        }
        else if (it.value() != nullptr)
        {
            document = isCurrentTrack
                    ? [OASavingTrackHelper sharedInstance].currentTrack
                    : [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(it.value())];
        }

        if (!document)
            continue;

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

- (BOOL)isSensorLineVisualizationType:(EOAGPX3DLineVisualizationByType)type 
{
    static NSSet *sensorTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sensorTypes = [NSSet setWithArray:@[@(EOAGPX3DLineVisualizationByTypeHeartRate), @(EOAGPX3DLineVisualizationByTypeBicycleCadence), @(EOAGPX3DLineVisualizationByTypeBicyclePower), @(EOAGPX3DLineVisualizationByTypeTemperature), @(EOAGPX3DLineVisualizationByTypeSpeedSensor)]];
    });
    return [sensorTypes containsObject:@(type)];
}

- (double)getValidElevation:(double)elevation
{
    return isnan(elevation) ? 0 : elevation;
}

- (BOOL)isInstanceOfOAWptPt:(id)point
{
    return [point isKindOfClass:[OAWptPt class]];
}

- (BOOL)is3DMapsEnabled
{
    return _plugin && [_plugin is3DMapsEnabled] && [_plugin isTerrainLayerEnabled];
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
    if ([object isKindOfClass:OAGpxWptItem.class])
    {
        OAGpxWptItem *item = (OAGpxWptItem *)object;
        return !item.routePoint;
    }
    return NO;
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
                doc->saveTo(QString::fromNSString(item.docPath), QString::fromNSString([OAAppVersion getFullVersionWithAppName]));
                QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> > docs;
                docs[QString::fromNSString(item.docPath)] = doc;
                [self refreshGpxTracks:docs reset:YES refreshColors:NO];
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
