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
#import "OAOsmAndFormatter.h"
#import "OAAtomicInteger.h"
#import "OACompoundIconUtils.h"
#import "OAObservable.h"
#import "OAColoringType.h"
#import "OAConcurrentCollections.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndSharedWrapper.h"

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
    OAConcurrentDictionary<NSString *, NSString *> *_updatedColorPaletteFiles;
    
    NSOperationQueue *_splitLabelsQueue;
    NSObject* _splitLock;
    OAAtomicInteger *_splitCounter;
    QList<OsmAnd::PointI> _startFinishPoints;
    QList<float> _startFinishPointsElevations;
    QList<OsmAnd::GpxAdditionalIconsProvider::SplitLabel> _splitLabels;
    OASRTMPlugin *_plugin;
    
    NSMutableDictionary<NSString *, OASGpxFile *> *_gpxFiles;
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
    _gpxFiles = [NSMutableDictionary dictionary];
    _cachedTracks = [NSMutableDictionary dictionary];
    _cachedTrackWidth = [NSMutableDictionary dictionary];
    _updatedColorPaletteFiles = [[OAConcurrentDictionary alloc] init];
    
    _plugin = (OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onColorPalettesFilesUpdated:)
                                                 name:ColorPaletteHelper.colorPalettesUpdatedNotification
                                               object:nil];
}

- (void) resetLayer
{
    [super resetLayer];

    [self.mapView removeTiledSymbolsProvider:_waypointsMapProvider];
    [self.mapView removeTiledSymbolsProvider:_startFinishProvider];
    [self.mapView removeKeyedSymbolsProvider:_linesCollection];

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    [_gpxFiles removeAllObjects];
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

- (void)onColorPalettesFilesUpdated:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSDictionary.class])
        return;

    NSDictionary<NSString *, NSString *> *colorPaletteFiles = (NSDictionary *) notification.object;
    if (!colorPaletteFiles)
        return;
    BOOL refresh = NO;
    for (NSString *colorPaletteFile in colorPaletteFiles)
    {
        if ([colorPaletteFile hasPrefix:ColorPaletteHelper.routePrefix])
        {
            [_updatedColorPaletteFiles setObjectSync:colorPaletteFiles[colorPaletteFile] forKey:colorPaletteFile];
            refresh = YES;
        }
    }
    if (refresh)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapViewController runWithRenderSync:^{
                [self refreshGpxTracks:_gpxFiles reset:YES];
            }];
        });
    }
}

- (void) refreshGpxTracks:(NSDictionary<NSString *, OASGpxFile *> *)gpxFiles reset:(BOOL)reset
{
    if (reset)
        [self resetLayer];

    _gpxFiles = (NSMutableDictionary *)[gpxFiles mutableCopy];
    [self refreshCachedTracks];
    [self refreshGpxTracks];
}

- (void)refreshCachedTracks
{
    if (_cachedTracks.count > 0)
    {
        [_cachedTracks.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![_gpxFiles objectForKey:key])
            {
                [_cachedTracks removeObjectForKey:key];
                QString qKey = QString::fromNSString(key);
                _cachedColors.remove(qKey);
                _cachedWallColors.remove(qKey);
            }
        }];
    }
    
    for (NSString *key in _gpxFiles.allKeys)
    {
        OASGpxFile *gpxFile = _gpxFiles[key];
        if (!gpxFile)
        {
            continue;
        }

        if (![_cachedTracks.allKeys containsObject:key] || [key isEqualToString:kCurrentTrack])
        {
            QString qKey = QString::fromNSString(key);
            [self addTrackToCached:qKey value:gpxFile];
        }
    }
}

- (OASGpxDataItem *)getGpxItem:(const QString &)filename
{
    NSString *filenameNS = filename.toNSString();
    OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filenameNS];
    return gpx;
}

- (void)addTrackToCached:(QString)key value:(OASGpxFile *)value
{
    if (!value)
        return;

    BOOL isCurrentTrack = [key.toNSString() isEqualToString:kCurrentTrack];
    NSString *filePath = key.toNSString();
    if (![_cachedTracks.allKeys containsObject:filePath] || isCurrentTrack)
    {
        OASGpxDataItem *gpx;
        OASGpxFile *gpxFile;

        
        if (isCurrentTrack) {
            gpx = nil;
        } else {
            gpx = [self getGpxItem:key];
        }
        
        if (isCurrentTrack)
        {
            gpxFile = [OASavingTrackHelper sharedInstance].currentTrack;
        }
        else
        {
            gpxFile = value;
        }
        GPXDataItemGPXFileWrapper *dataWrapper = [[GPXDataItemGPXFileWrapper alloc] initWithGpxDataItem:gpx gpxFile:gpxFile];
        
        NSMutableDictionary<NSString *, id> *cachedTrack = [NSMutableDictionary dictionary];
        cachedTrack[@"gpx"] = gpx;
        cachedTrack[@"gpxFile"] = gpxFile;
        cachedTrack[@"colorization_scheme"] = @(COLORIZATION_NONE);
        cachedTrack[@"prev_coloring_type"] = dataWrapper.coloringType;
        cachedTrack[@"prev_color_palette"] = dataWrapper.gradientPaletteName.length > 0 ? dataWrapper.gradientPaletteName : PaletteGradientColor.defaultName;
        cachedTrack[@"prev_wall_coloring_type"] = @(dataWrapper.visualization3dWallColorType);
        _cachedTracks[filePath] = cachedTrack;
        _cachedColors[key] = QList<OsmAnd::FColorARGB>();
        _cachedWallColors[key] = QList<OsmAnd::FColorARGB>();
    }
}

- (void)configureCachedWallColorsFor:(OAColoringType *)type
                                 gpxFile:(OASGpxFile *)gpxFile
                                 key:(QString)key
                            analysis:(OASGpxTrackAnalysis *_Nullable)analysis
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
                                                 gradientPaletteName:gradientPalette];
        if (!palette)
            return;
        OARouteColorize *routeColorize =
            [[OARouteColorize alloc] initWithGpxFile:gpxFile
                                            analysis:analysis ?: [gpxFile getAnalysisFileTimestamp:0]
                                                type:[type toColorizationType]
                                             palette:palette
                                     maxProfileSpeed:0];
        _cachedWallColors[key].clear();
        if (routeColorize)
            _cachedWallColors[key].append([routeColorize getResultQList]);
    }
}

- (void) refreshGpxTracks
{
    BOOL hasVolumetricSymbols;
    for (NSMutableDictionary<NSString *, id> *cachedTrack in _cachedTracks.allValues)
    {
        OASGpxDataItem *gpx = cachedTrack[@"gpx"];
        OASGpxFile *gpxFile = cachedTrack[@"gpxFile"];
        GPXDataItemGPXFileWrapper *dataWrapper = [[GPXDataItemGPXFileWrapper alloc] initWithGpxDataItem:gpx gpxFile:gpxFile];
        if (dataWrapper.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone && [gpxFile hasTrkPtWithElevation:YES])
        {
            hasVolumetricSymbols = YES;
            break;
        }
    }
    if (_linesCollection->hasVolumetricSymbols != hasVolumetricSymbols)
        _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>(hasVolumetricSymbols);

    if (_gpxFiles.count > 0)
    {
        int baseOrder = self.baseOrder;
        int lineId = 1;
        
        for (NSString *key in _gpxFiles.allKeys)
        {
            OASGpxFile *gpxFile_ = _gpxFiles[key];

            if (!gpxFile_)
            {
                continue;
            }
            
            QString qKey = QString::fromNSString(key);
            BOOL isCurrentTrack = [key isEqualToString:kCurrentTrack];
            NSMutableDictionary<NSString *, id> *cachedTrack = _cachedTracks[key];
            OASGpxDataItem *gpx = cachedTrack[@"gpx"];
            OASGpxFile *gpxFile = cachedTrack[@"gpxFile"];
            if (!gpx && !gpxFile)
                continue;
            GPXDataItemGPXFileWrapper *dataWrapper = [[GPXDataItemGPXFileWrapper alloc] initWithGpxDataItem:gpx gpxFile:gpxFile];
            OAColoringType *type = dataWrapper.coloringType.length > 0
                ? [OAColoringType getNonNullTrackColoringTypeByName:dataWrapper.coloringType]
                : OAColoringType.TRACK_SOLID;

            BOOL isAvailable = [type isAvailableInSubscription];
            if (!isAvailable)
                type = OAColoringType.DEFAULT;

            OASGpxTrackAnalysis *analysis;
            NSString *colorPaletteFile = @"";
            if ([type isGradient])
            {
                colorPaletteFile =
                    [ColorPaletteHelper getRoutePaletteFileName:(ColorizationType) [type toColorizationType]
                                            gradientPaletteName:cachedTrack[@"prev_color_palette"]];
            }
            if ([type isGradient]
                && (![cachedTrack[@"prev_coloring_type"] isEqualToString:dataWrapper.coloringType]
                    || ![cachedTrack[@"prev_color_palette"] isEqualToString:dataWrapper.gradientPaletteName]
                    || [cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_GRADIENT
                    || [_updatedColorPaletteFiles objectForKeySync:colorPaletteFile]
                    || _cachedColors[qKey].isEmpty()))
            {
                NSString *updatedColorPaletteValue = [_updatedColorPaletteFiles objectForKeySync:colorPaletteFile];
                BOOL isColorPaletteDeleted = [updatedColorPaletteValue isEqualToString:ColorPaletteHelper.deletedFileKey];
                [_updatedColorPaletteFiles removeObjectForKeySync:colorPaletteFile];

                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_GRADIENT);
                cachedTrack[@"prev_coloring_type"] = dataWrapper.coloringType;
                cachedTrack[@"prev_color_palette"] = dataWrapper.gradientPaletteName.length == 0 || isColorPaletteDeleted ? PaletteGradientColor.defaultName : dataWrapper.gradientPaletteName;
                BOOL shouldCalculateColorCache = YES;
                // check if we already have a cached array of wall color points that can be reused for route line color, provided that the coloring type matches
                switch (dataWrapper.visualization3dWallColorType)
                {
                    case EOAGPX3DLineVisualizationWallColorTypeAltitude:
                        shouldCalculateColorCache = !([type isAltitude] && !_cachedWallColors[qKey].isEmpty());
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSlope:
                        shouldCalculateColorCache = !([type isSlope] && !_cachedWallColors[qKey].isEmpty());
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSpeed:
                        shouldCalculateColorCache = !([type isSpeed] && !_cachedWallColors[qKey].isEmpty());
                        break;
                    default:
                        break;
                }

                if (shouldCalculateColorCache)
                {
                    analysis = [gpxFile getAnalysisFileTimestamp:0];
                    ColorPalette *palette =
                        [[ColorPaletteHelper shared] getGradientColorPaletteSync:(ColorizationType) [type toColorizationType]
                                                             gradientPaletteName:cachedTrack[@"prev_color_palette"]];
                    if (!palette)
                        return;
                    OARouteColorize *routeColorize =
                        [[OARouteColorize alloc] initWithGpxFile:gpxFile
                                                        analysis:analysis
                                                            type:[type toColorizationType]
                                                         palette:palette
                                                 maxProfileSpeed:0];
                    _cachedColors[qKey].clear();
                    if (routeColorize)
                        _cachedColors[qKey].append([routeColorize getResultQList]);
                }
                else
                {
                    _cachedColors[qKey] = _cachedWallColors[qKey];
                }
            }
            else if ([type isRouteInfoAttribute]
                     && (![cachedTrack[@"prev_coloring_type"] isEqualToString:dataWrapper.coloringType]
                         || ![cachedTrack[@"prev_color_palette"] isEqualToString:dataWrapper.gradientPaletteName]
                        || [cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_SOLID
                        || _cachedColors[qKey].isEmpty()))
            {
                OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithGpxFile:gpxFile];
                auto segs = [routeImporter importRoute];
                NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
                for (OASTrkSegment *seg in [gpxFile getNonEmptyTrkSegmentsRoutesOnly:YES])
                {
                    for (OASWptPt *point in seg.points)
                    {
                        [locations addObject:[[CLLocation alloc] initWithLatitude:point.position.latitude
                                                                        longitude:point.position.longitude]];
                    }
                }
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_SOLID);
                cachedTrack[@"prev_coloring_type"] = dataWrapper.coloringType;
                cachedTrack[@"prev_color_palette"] = dataWrapper.gradientPaletteName.length > 0 ? dataWrapper.gradientPaletteName : PaletteGradientColor.defaultName;
                _cachedColors[qKey].clear();
                [self calculateSegmentsColor:_cachedColors[qKey]
                                    attrName:dataWrapper.coloringType
                               segmentResult:segs
                                   locations:locations];
            }
            else if ([type isSolidSingleColor]
                     && ([cachedTrack[@"colorization_scheme"] intValue] != COLORIZATION_NONE
                         || ![cachedTrack[@"prev_color_palette"] isEqualToString:dataWrapper.gradientPaletteName]
                         || !_cachedColors[qKey].isEmpty()))
            {
                cachedTrack[@"colorization_scheme"] = @(COLORIZATION_NONE);
                cachedTrack[@"prev_coloring_type"] = dataWrapper.coloringType;
                cachedTrack[@"prev_color_palette"] = dataWrapper.gradientPaletteName.length > 0 ? dataWrapper.gradientPaletteName : PaletteGradientColor.defaultName;
                _cachedColors[qKey].clear();
            }
            
            if (cachedTrack[@"prev_wall_coloring_type"] != @(dataWrapper.visualization3dWallColorType) || _cachedWallColors[qKey].isEmpty())
            {
                switch (dataWrapper.visualization3dWallColorType)
                {
                    case EOAGPX3DLineVisualizationWallColorTypeAltitude:
                        [self configureCachedWallColorsFor:OAColoringType.ALTITUDE
                                                       gpxFile:gpxFile
                                                       key:qKey
                                                  analysis:analysis
                                     shouldCheckColorCache:[type isAltitude]
                                           gradientPalette:cachedTrack[@"prev_color_palette"]];
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSlope:
                        [self configureCachedWallColorsFor:OAColoringType.SLOPE
                                                       gpxFile:gpxFile
                                                       key:qKey
                                                  analysis:analysis
                                     shouldCheckColorCache:[type isSlope]
                                           gradientPalette:cachedTrack[@"prev_color_palette"]];
                        break;
                    case EOAGPX3DLineVisualizationWallColorTypeSpeed:
                        [self configureCachedWallColorsFor:OAColoringType.SPEED
                                                       gpxFile:gpxFile
                                                       key:qKey
                                                  analysis:analysis
                                     shouldCheckColorCache:[type isSpeed]
                                           gradientPalette:cachedTrack[@"prev_color_palette"]];
                        break;
                    default:
                        _cachedWallColors[qKey].clear();
                        break;
                }
                cachedTrack[@"prev_wall_coloring_type"] = @(dataWrapper.visualization3dWallColorType);
            }

            if (gpxFile_.hasTrkPt)
            {
                int segStartIndex = 0;
                QVector<OsmAnd::PointI> points;
                NSMutableArray *elevations = [NSMutableArray array];
                QList<OsmAnd::FColorARGB> segmentColors;
                QList<OsmAnd::FColorARGB> segmentWallColors;
                NSArray<OASTrack *> *tracksWithoutGeneralTrack = [gpxFile getTracksIncludeGeneralTrack:NO];
                if ([self isSensorLineVisualizationType:dataWrapper.visualization3dByType])
                {
                    [self processGPXDataElements:gpxFile.tracks withGPX:gpx addToElevations:elevations];
                }
                for (OASTrack *track in tracksWithoutGeneralTrack)
                {
                    for (OASTrkSegment *seg in track.segments)
                    {
                        for (OASWptPt *pt in seg.points)
                        {
                            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.lat, pt.lon)));
                            double elevationValue = [self getValidElevation:pt.ele];
                            switch (dataWrapper.visualization3dByType)
                            {
                                case EOAGPX3DLineVisualizationByTypeAltitude:
                                    [elevations addObject:@(pt.ele)];
                                    break;
                                case EOAGPX3DLineVisualizationByTypeSpeed:
                                    [elevations addObject:@([self is3DMapsEnabled] ? (pt.speed * kSpeedToHeightScale) + elevationValue : pt.speed * kSpeedToHeightScale)];
                                    break;
                                case EOAGPX3DLineVisualizationByTypeFixedHeight:
                                    [elevations addObject:@([self is3DMapsEnabled] ? elevationValue + dataWrapper.elevationMeters : dataWrapper.elevationMeters)];
                                    break;
                                default:
                                    break;
                            }
                        }
                        if (points.size() > 1 && !_cachedWallColors[qKey].isEmpty() && segStartIndex < _cachedWallColors[qKey].size() && segStartIndex + seg.points.count - 1 < _cachedWallColors[qKey].size())
                        {
                            segmentWallColors.append(_cachedWallColors[qKey].mid(segStartIndex, (int)seg.points.count));
                        }
                        if (points.size() > 1 && !_cachedColors[qKey].isEmpty() && segStartIndex < _cachedColors[qKey].size() && segStartIndex + seg.points.count - 1 < _cachedColors[qKey].size())
                        {
                            segmentColors.append(_cachedColors[qKey].mid(segStartIndex, (int)seg.points.count));
                        }
                        else if ([cachedTrack[@"colorization_scheme"] intValue] == COLORIZATION_NONE && segmentColors.isEmpty() && dataWrapper.color == 0)
                        {
                            NSArray<OASTrack *> *tracksCopy_ = [gpxFile_.tracks copy];
                            NSInteger trackIndex = [tracksCopy_ indexOfObject:track];
                            
                            if (trackIndex != NSNotFound)
                            {
                                OASTrack *gpxTrack = track;
                                OASInt *color = [[OASInt alloc] initWithInt:(int)kDefaultTrackColor];
                                const auto colorARGB = [UIColorFromARGB([[gpxTrack getColorDefColor:color] intValue]) toFColorARGB];
                                segmentColors.push_back(colorARGB);
                            }
                            else
                            {
                                NSLog(@"Track not found or index is out of bounds");
                            }
                        }
                        segStartIndex += seg.points.count;
                        if (!dataWrapper.joinSegments)
                        {
                            if (isCurrentTrack)
                            {
                                [self refreshLine:points gpx:gpxFile baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
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
                if (dataWrapper.joinSegments)
                {
                    if (isCurrentTrack)
                    {
                        [self refreshLine:points gpx:gpxFile baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
                    }
                    else
                    {
                        [self drawLine:points gpx:gpx baseOrder:baseOrder-- lineId:lineId++ colors:segmentColors segmentWallColors:segmentWallColors colorizationScheme:[cachedTrack[@"colorization_scheme"] intValue] elevations:elevations];
                    }
                }
            }
            else if (gpxFile_.hasRtePt)
            {
                NSMutableArray *elevations = [NSMutableArray array];
                if ([self isSensorLineVisualizationType:dataWrapper.visualization3dByType])
                {
                    [self processGPXDataElements:gpxFile.routes withGPX:gpx addToElevations:elevations];
                }
                for (OASRoute *route in gpxFile_.routes)
                {
                    QVector<OsmAnd::PointI> points;
                    for (OASWptPt *pt in route.points)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.lat, pt.lon)));
                        double elevationValue = [self getValidElevation:pt.ele];
                        switch (dataWrapper.visualization3dByType)
                        {
                            case EOAGPX3DLineVisualizationByTypeAltitude:
                                [elevations addObject:@(pt.ele)];
                                break;
                            case EOAGPX3DLineVisualizationByTypeSpeed:
                                [elevations addObject:@([self is3DMapsEnabled] ? (pt.speed * kSpeedToHeightScale) + elevationValue : pt.speed * kSpeedToHeightScale)];
                                break;
                            case EOAGPX3DLineVisualizationByTypeFixedHeight:
                                [elevations addObject:@([self is3DMapsEnabled] ? elevationValue + dataWrapper.elevationMeters : dataWrapper.elevationMeters)];
                                break;
                            default:
                                break;
                        }
                    }
                    if (isCurrentTrack)
                    {
                        [self refreshLine:points gpx:gpxFile baseOrder:baseOrder-- lineId:lineId++ colors:{} segmentWallColors:{} colorizationScheme:COLORIZATION_NONE elevations:elevations];
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

- (void)processGPXDataElements:(NSArray *)elements withGPX:(OASGpxDataItem *)gpx addToElevations:(NSMutableArray *)elevations
{
    for (id element in elements)
    {
        NSArray *points = @[];
        if ([element isKindOfClass:[OASTrack class]])
        {
            for (OASTrkSegment *segment in [(OASTrack *)element segments])
            {
                [self evaluateSensorDataForPoints:segment.points withGPX:gpx addToElevations:elevations];
            }
        }
        else if ([element isKindOfClass:[OASRoute class]])
        {
            points = [(OASRoute *)element points];
            [self evaluateSensorDataForPoints:points withGPX:gpx addToElevations:elevations];
        }
    }
}

- (void)evaluateSensorDataForPoints:(NSArray *)points withGPX:(OASGpxDataItem *)gpx addToElevations:(NSMutableArray *)elevations
{
    for (OASWptPt *point in points)
    {
        if ([self isInstanceOfOASWptPt:point])
        {
            switch (gpx.visualization3dByType)
            {
                case EOAGPX3DLineVisualizationByTypeHeartRate:
                case EOAGPX3DLineVisualizationByTypeBicycleCadence:
                case EOAGPX3DLineVisualizationByTypeBicyclePower:
                case EOAGPX3DLineVisualizationByTypeTemperatureA:
                case EOAGPX3DLineVisualizationByTypeTemperatureW:
                case EOAGPX3DLineVisualizationByTypeSpeedSensor:
                    [elevations addObject:@([self processSensorData:point forType:gpx.visualization3dByType])];
                    break;
                default:
                    break;
            }
        }
    }
}

- (float)processSensorData:(OASWptPt *)point forType:(EOAGPX3DLineVisualizationByType)visualizationType
{
    double pointElevation = [self getValidElevation:point.ele];
    double elevation = [self getSensorAttribute:point
                                           type:visualizationType
                                     attributes:point.attributes];
    return [self is3DMapsEnabled] && !isnan(elevation)
            ? elevation + pointElevation
            : elevation;
}

- (float)getSensorAttribute:(OASWptPt *)point
                       type:(EOAGPX3DLineVisualizationByType)type
                 attributes:(nullable OASPointAttributes *)attributes {
    BOOL hasAttributes = attributes != nil;
    
    OASSensorPointAnalyser *sensorPointAnalyser = [OASSensorPointAnalyser shared];
    
    switch (type)
    {
        case EOAGPX3DLineVisualizationByTypeHeartRate:
            return hasAttributes ? attributes.heartRate : [sensorPointAnalyser getPointAttributeWptPt:point key:OASPointAttributes.sensorTagHeartRate defaultValue:0];
        case EOAGPX3DLineVisualizationByTypeBicycleCadence:
            
            return hasAttributes ? attributes.bikeCadence : [sensorPointAnalyser getPointAttributeWptPt:point key:OASPointAttributes.sensorTagCadence defaultValue:0];
        case EOAGPX3DLineVisualizationByTypeBicyclePower:
            return hasAttributes ? attributes.bikePower : [sensorPointAnalyser getPointAttributeWptPt:point key:OASPointAttributes.sensorTagBikePower defaultValue:0];
        case EOAGPX3DLineVisualizationByTypeTemperatureA:
        case EOAGPX3DLineVisualizationByTypeTemperatureW:
        {
            float airTemp = hasAttributes ? attributes.airTemperature : [sensorPointAnalyser getPointAttributeWptPt:point key:OASPointAttributes.sensorTagTemperatureA defaultValue:NAN];
            if (!isnan(airTemp))
            {
                return airTemp + kTemperatureToHeightOffset;
            }
            
            float waterTemp = hasAttributes ? attributes.waterTemperature : [sensorPointAnalyser getPointAttributeWptPt:point key:OASPointAttributes.sensorTagTemperatureW defaultValue:NAN];
            if (!isnan((waterTemp)))
            {
                return waterTemp + kTemperatureToHeightOffset;
            }
        }
        case EOAGPX3DLineVisualizationByTypeSpeedSensor:
        {
            return hasAttributes ? attributes.sensorSpeed : [sensorPointAnalyser getPointAttributeWptPt:point key:OASPointAttributes.sensorTagBikePower defaultValue:0] * kSpeedToHeightScale;
        }
        default: return NAN;
    }
    return 0;
}

- (void) drawLine:(QVector<OsmAnd::PointI> &)points
              gpx:(OASGpxDataItem *)gpx
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
            auto iconBitmap = [self bitmapForColor:color fileName:@"map_direction_arrow"];
            if (iconBitmap)
            {
                builder.setPathIcon(OsmAnd::SingleSkImage(iconBitmap))
                       .setPathIconStep(iconBitmap->height() * kPathIconStepCoef)
                       .setShouldShowArrows(true);
            }
            auto specialIconBitmap = [self specialBitmapWithColor:colorARGB];
            if (specialIconBitmap)
            {
                builder.setSpecialPathIcon(OsmAnd::SingleSkImage(specialIconBitmap))
                       .setSpecialPathIconStep(specialIconBitmap->height() * kPathIconStepCoef)
                       .setShouldShowArrows(true);
            }
            builder.setScreenScale(UIScreen.mainScreen.scale);
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
                gpx:(OASGpxFile *)gpx
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
        if (_cachedTrackWidth[[gpx getWidthDefaultWidth:nil]])
        {
            lineWidth = _cachedTrackWidth[[gpx getWidthDefaultWidth:nil]].floatValue;
        }
        else
        {
            lineWidth = [self getLineWidth:[gpx getWidthDefaultWidth:nil]];
            _cachedTrackWidth[[gpx getWidthDefaultWidth:nil]] = @(lineWidth);
        }

        OsmAnd::FColorARGB colorARGB;
        if ([gpx getColorDefColor:nil].intValue != 0)
        {
            colorARGB = OsmAnd::ColorARGB([gpx getColorDefColor:nil].intValue);
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

            if ([gpx isShowArrows])
            {
                // Use black arrows for gradient colorization
                UIColor *color = gpx.getColoringType.length != 0 && ![gpx.getColoringType isEqualToString:@"solid"] ? UIColor.whiteColor : UIColorFromARGB([gpx getColorDefColor:nil].intValue);
                auto iconBitmap = [self bitmapForColor:color fileName:@"map_direction_arrow"];
                if (iconBitmap)
                {
                    builder.setPathIcon(OsmAnd::SingleSkImage(iconBitmap))
                           .setPathIconStep(iconBitmap->height() * kPathIconStepCoef)
                           .setShouldShowArrows(true);
                }
                auto specialIconBitmap = [self specialBitmapWithColor:colorARGB];
                if (specialIconBitmap)
                {
                    builder.setSpecialPathIcon(OsmAnd::SingleSkImage(specialIconBitmap))
                           .setSpecialPathIconStep(specialIconBitmap->height() * kPathIconStepCoef)
                           .setShouldShowArrows(true);
                }
                builder.setScreenScale(UIScreen.mainScreen.scale);
            }
            
            if ([OAGPXDatabase lineVisualizationByTypeForName:gpx.get3DVisualizationType] != EOAGPX3DLineVisualizationByTypeNone)
            {
                [self configureCurrentTrackRaisedLine:builder
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
            line->setShowArrows([gpx isShowArrows]);
        }
    }
}

- (OsmAnd::VectorLineBuilder &)configureCurrentTrackRaisedLine:(OsmAnd::VectorLineBuilder &)builder
                 elevations:(NSArray <NSNumber *>* _Nullable)elevations
                  colorARGB:(OsmAnd::FColorARGB)colorARGB
                     colors:(const QList<OsmAnd::FColorARGB> &)colors
          segmentWallColors:(const QList<OsmAnd::FColorARGB> &)segmentWallColors
      gpx:(OASGpxFile *)gpx
                  lineWidth:(CGFloat)lineWidth
{
    [self configureElevations:elevations elevationScaleFactor:[gpx getAdditionalExaggeration] builder:builder];
    
    // for setColorizationMapping use: colors or QList<OsmAnd::FColorARGB>()
    builder.setColorizationMapping(colors);
    
    if (!segmentWallColors.isEmpty())
    {
        builder.setOutlineColorizationMapping(segmentWallColors);
    }
    
    // configure visibility for Top and Bottom lines
    [self configureVisualization3dPositionType:[OAGPXDatabase lineVisualizationPositionTypeForName:gpx.get3DLinePositionType] builder:builder];
   
    builder.setOutlineWidth(lineWidth * 2.0f / 2.0f);

    auto visualization3dWallColorType = [OAGPXDatabase lineVisualizationWallColorTypeForName:gpx.get3DWallColoringType];
    if (visualization3dWallColorType != EOAGPX3DLineVisualizationWallColorTypeNone && visualization3dWallColorType != EOAGPX3DLineVisualizationWallColorTypeSolid)
    {
        builder.setColorizationScheme(1);

        if (segmentWallColors.isEmpty())
        {
            BOOL upwardGradient = [OAGPXDatabase lineVisualizationWallColorTypeForName:gpx.get3DWallColoringType] == EOAGPX3DLineVisualizationWallColorTypeUpwardGradient;
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
        builder.setOutlineColor(OsmAnd::FColorARGB([OAGPXDatabase lineVisualizationWallColorTypeForName:gpx.get3DWallColoringType] == EOAGPX3DLineVisualizationWallColorTypeSolid ? 1.0f : 0.0f, colorARGB.r, colorARGB.g, colorARGB.b));
    }
    return builder;
}

- (OsmAnd::VectorLineBuilder &)configureRaisedLine:(OsmAnd::VectorLineBuilder &)builder
                 elevations:(NSArray <NSNumber *>* _Nullable)elevations
                  colorARGB:(OsmAnd::FColorARGB)colorARGB
                     colors:(const QList<OsmAnd::FColorARGB> &)colors
          segmentWallColors:(const QList<OsmAnd::FColorARGB> &)segmentWallColors
                        gpx:(OASGpxDataItem *)gpx
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

- (void)processSplitLabels:(OASGpxDataItem *)gpx doc:(OASGpxFile *)doc
{
    NSBlockOperation* operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation* weakOperation = operation;
    OAAtomicInteger *splitCounter = _splitCounter;
    GPXDataItemGPXFileWrapper *dataWrapper = [[GPXDataItemGPXFileWrapper alloc] initWithGpxDataItem:gpx gpxFile:doc];
    [operation addExecutionBlock:^{
        if (splitCounter != _splitCounter || weakOperation.isCancelled)
            return;
        OASGpxFile *document = doc;
        NSArray<OASGpxTrackAnalysis *> *splitData = nil;
        BOOL splitByTime = NO;
        BOOL splitByDistance = NO;
        switch (dataWrapper.splitType) {
            case EOAGpxSplitTypeDistance: {
                NSMutableArray *array = [NSMutableArray array];
                for (OASTrack *subtrack in document.tracks)
                {
                    for (OASTrkSegment *segment in subtrack.segments)
                    {
                        [array addObjectsFromArray:[segment splitByDistanceMeters:gpx.splitInterval joinSegments:gpx.joinSegments]];
                    }
                }
                splitData = [array copy];
                splitByDistance = YES;
                break;
            }
            case EOAGpxSplitTypeTime: {
                NSMutableArray *array = [NSMutableArray array];
                for (OASTrack *subtrack in document.tracks)
                {
                    for (OASTrkSegment *segment in subtrack.segments)
                    {
                        [array addObjectsFromArray:[segment splitByTimeSeconds:gpx.splitInterval joinSegments:gpx.joinSegments]];
                    }
                }
                splitData = [array copy];
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
                OASGpxTrackAnalysis *seg = splitData[i];
                double metricStartValue = splitData[i - 1].metricEnd;
                OASWptPt *pt = seg.locationStart;
                if (pt)
                {
                    CGFloat splitElevation = NULL;
                    double elevationValue = [self getValidElevation:pt.ele];
                    switch (dataWrapper.visualization3dByType)
                    {
                        case EOAGPX3DLineVisualizationByTypeAltitude:
                            splitElevation = pt.ele;
                            break;
                        case EOAGPX3DLineVisualizationByTypeSpeed:
                            splitElevation = [self is3DMapsEnabled] ? (pt.speed * kSpeedToHeightScale) + elevationValue : pt.speed * kSpeedToHeightScale;
                            break;
                        case EOAGPX3DLineVisualizationByTypeHeartRate:
                        case EOAGPX3DLineVisualizationByTypeBicycleCadence:
                        case EOAGPX3DLineVisualizationByTypeBicyclePower:
                        case EOAGPX3DLineVisualizationByTypeTemperatureA:
                        case EOAGPX3DLineVisualizationByTypeTemperatureW:
                        case EOAGPX3DLineVisualizationByTypeSpeedSensor:
                            splitElevation = [self processSensorData:pt forType:dataWrapper.visualization3dByType];
                            break;
                        case EOAGPX3DLineVisualizationByTypeFixedHeight:
                            splitElevation = [self is3DMapsEnabled] ? elevationValue + dataWrapper.elevationMeters : dataWrapper.elevationMeters;
                            break;
                        default:
                            splitElevation = NAN;
                            break;
                    }
                    
                    const auto pos31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.lat, pt.lon));
                    QString stringValue;
                    if (splitByDistance)
                        stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedDistance:metricStartValue]);
                    else if (splitByTime)
                        stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedTimeInterval:metricStartValue shortFormat:YES]);
                    const auto colorARGB = [UIColorFromARGB(dataWrapper.color == 0 ? kDefaultTrackColor : dataWrapper.color) toFColorARGB];
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
    
    for (NSString *key in _gpxFiles.allKeys) {
        NSString *path = key;
        
        OASGpxDataItem *gpx = [OAGPXDatabase.sharedDb getGPXItem:path];
        
        OASGpxFile *gpxFile = [_gpxFiles objectForKey:key];
        GPXDataItemGPXFileWrapper *dataWrapper = [[GPXDataItemGPXFileWrapper alloc] initWithGpxDataItem:gpx gpxFile:gpxFile];
        if ((!gpx && ![path isEqualToString:kCurrentTrack]) || gpx.showStartFinish)
        {
            if (!gpxFile)
                continue;
            
            const bool raiseRoutesAboveRelief = gpx.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone;
            
            NSArray<OASTrack *> *tracks = [gpxFile.tracks copy];
            OsmAnd::LatLon start, finish;
            CLLocationCoordinate2D startLoc, finishLoc;
            float startPointElevation, finishPointElevation;
            if ([self isSensorLineVisualizationType:gpx.visualization3dByType])
            {
                for (OASTrack *track in gpxFile.tracks)
                {
                    NSArray *segments = [NSArray arrayWithArray:track.segments];
                    for (int i = 0; i < segments.count; i++)
                    {
                        OASTrkSegment *segment = segments[i];
                        if (segment.points.count < 2)
                            continue;
                        if (gpx.joinSegments)
                        {
                            if (i == 0)
                            {
                                startLoc = CLLocationCoordinate2DMake(segment.points.firstObject.lat, segment.points.firstObject.lon);
                                if (raiseRoutesAboveRelief)
                                {
                                    _elevationScaleFactor = gpx.verticalExaggerationScale;
                                    startPointElevation = [self processSensorData:segment.points.firstObject forType:gpx.visualization3dByType];
                                }
                            }
                            else if (i == segments.count - 1)
                            {
                                finishLoc =  CLLocationCoordinate2DMake(segment.points.lastObject.lat, segment.points.lastObject.lon);
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
                for (OASTrack *trk in tracks) {
                    NSArray<OASTrkSegment *> *segments = trk.segments;

                    for (NSUInteger i = 0; i < segments.count; i++) {
                        OASTrkSegment *seg = segments[i];
                        if (seg.points.count < 2) {
                            continue;
                        }
                        double firstPointElevation = [self getValidElevation:seg.points.firstObject.ele];
                        double lastPointElevation = [self getValidElevation:seg.points.lastObject.ele];
                        if (gpx.joinSegments)
                        {
                            if (i == 0)
                            {
                                CLLocationCoordinate2D position = seg.points.firstObject.position;
                                start = OsmAnd::LatLon(position.latitude, position.longitude);
                                if (raiseRoutesAboveRelief)
                                {
                                    _elevationScaleFactor = gpx.verticalExaggerationScale;
                                    if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeAltitude)
                                        startPointElevation = seg.points.firstObject.ele;
                                    else if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeSpeed)
                                        startPointElevation = [self is3DMapsEnabled] ? (seg.points.firstObject.speed * kSpeedToHeightScale) + firstPointElevation : seg.points.firstObject.speed * kSpeedToHeightScale;
                                    else
                                        startPointElevation = [self is3DMapsEnabled] ? firstPointElevation + gpx.elevationMeters : gpx.elevationMeters;
                                }
                            }
                            else if (i == segments.count - 1)
                            {
                                CLLocationCoordinate2D position = seg.points.lastObject.position;
                                finish = OsmAnd::LatLon(position.latitude, position.longitude);
                                
                                if (raiseRoutesAboveRelief)
                                {
                                    if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeAltitude)
                                        finishPointElevation = seg.points.lastObject.ele;
                                    else if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeSpeed)
                                        finishPointElevation = [self is3DMapsEnabled] ? (seg.points.lastObject.speed * kSpeedToHeightScale) + lastPointElevation : seg.points.lastObject.speed  * kSpeedToHeightScale;
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
                                    startFinishPointsElevations.append(seg.points.firstObject.ele);
                                    startFinishPointsElevations.append(seg.points.lastObject.ele);
                                }
                                else if (gpx.visualization3dByType == EOAGPX3DLineVisualizationByTypeSpeed)
                                {
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? (seg.points.firstObject.speed * kSpeedToHeightScale) + firstPointElevation : seg.points.firstObject.speed * kSpeedToHeightScale);
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? (seg.points.lastObject.speed * kSpeedToHeightScale) + lastPointElevation : seg.points.lastObject.speed * kSpeedToHeightScale);
                                }
                                else
                                {
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? firstPointElevation + gpx.elevationMeters : gpx.elevationMeters);
                                    startFinishPointsElevations.append([self is3DMapsEnabled] ? lastPointElevation + gpx.elevationMeters : gpx.elevationMeters);
                                }
                            }
                            CLLocationCoordinate2D positionStart = seg.points.firstObject.position;
                            CLLocationCoordinate2D positionFinish = seg.points.lastObject.position;
                            startFinishPoints.append({
                                OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(positionStart.latitude, positionStart.longitude)),
                                OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(positionFinish.latitude, positionFinish.longitude))});
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
        if (dataWrapper.splitType != EOAGpxSplitTypeNone)
            [self processSplitLabels:gpx doc:gpxFile];
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

    if (_gpxFiles.allKeys.count > 0)
    {
        NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
        
        for (NSString *key in _gpxFiles.allKeys) {
            OASGpxFile *value = [_gpxFiles objectForKey:key];
            if (!value)
                continue;

            if (value.getPointsList.count > 0)
            {
                NSString *filePath = key;
                OASGpxFile *gpx = [_cachedTracks.allKeys containsObject:filePath]
                        ? _cachedTracks[filePath][@"gpxFile"]
                        : key == nil
                			? OASavingTrackHelper.sharedInstance.currentTrack
                			: [self getGpxItem:QString::fromNSString(key)];

                for (OASWptPt *waypoint in value.getPointsList)
                {
                    OASGpxUtilitiesPointsGroup *group = [gpx.pointsGroups objectForKey:waypoint.category];
                    if (!group || !group.hidden)
                        [points addObject:waypoint];
                }
            }
        }
        
        const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
        QList<OsmAnd::PointI> hiddenPoints;
        if (_hiddenPointPos31 != OsmAnd::PointI())
            hiddenPoints.append(_hiddenPointPos31);
            
        _waypointsMapProvider.reset(new OAWaypointsMapLayerProvider(points, self.pointsOrder - (int)points.count - 1, hiddenPoints,
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
    NSMutableDictionary<NSString *, OASGpxFile *> *activeGpx = [OASelectedGPXHelper.instance.activeGpx mutableCopy];
    OASGpxFile *currentTrackGpxFile = [OASavingTrackHelper sharedInstance].currentTrack;
    if (currentTrackGpxFile)
        activeGpx[kCurrentTrack] = currentTrackGpxFile;
    
    for (NSString *key in activeGpx.allKeys) {
        OASGpxFile *gpxFile = activeGpx[key];

        BOOL isCurrentTrack = currentTrackGpxFile && gpxFile == currentTrackGpxFile;

        OASGpxFile *document = nil;
        NSString *filePath = isCurrentTrack ? kCurrentTrack : key;
        if ([_cachedTracks.allKeys containsObject:filePath])
        {
            document = _cachedTracks[filePath][@"gpxFile"];
        }
        else if (gpxFile)
        {
            document = isCurrentTrack
                    ? currentTrackGpxFile
                    : gpxFile;
        }

        if (!document)
            continue;

        BOOL isJointSegments = NO;
        OASGpxDataItem *gpxDataItem;
        if (isCurrentTrack)
        {
            isJointSegments = [[OAAppSettings sharedManager].currentTrackIsJoinSegments get];
        }
        else
        {
            if ([_cachedTracks.allKeys containsObject:filePath]) {
                gpxDataItem = _cachedTracks[filePath][@"gpx"];
            }
            else
            {
                gpxDataItem = [self getGpxItem:QString::fromNSString(key)];
            }
            if (gpxDataItem)
            {
                isJointSegments = gpxDataItem.joinSegments;
            }
        }
        // NOTE: The old logic called processPoints during each initialization of the document (OAGPXDocument -> OASGpxFile). This was necessary for the correct recalculation for getPointsToDisplay. Now this is handled by recalculateProcessPoint. If recalculation is needed, call [document recalculateProcessPoint
        [document recalculateProcessPoint];
        NSArray<OASWptPt *> *points = [self findPointsNearSegments:[document getPointsToDisplayWithIsJoinSegments:isJointSegments] radius:r point:point];
        if (points != nil)
        {
            CLLocation *selectedGpxPoint = [OAMapUtils getProjection:[[CLLocation alloc] initWithLatitude:point.latitude
                                                                                                longitude:point.longitude]
                                                        fromLocation:[[CLLocation alloc] initWithLatitude:points.firstObject.position.latitude
                                                                                                longitude:points.firstObject.position.longitude]
                                                          toLocation:[[CLLocation alloc] initWithLatitude:points.lastObject.position.latitude
                                                                                                longitude:points.lastObject.position.longitude]];
            OATargetPoint *targetPoint = gpxDataItem
            ? [self getTargetPoint:gpxDataItem]
            : [self getTargetPoint:[OASavingTrackHelper sharedInstance].currentTrack];

            targetPoint.location = selectedGpxPoint.coordinate;
            if (targetPoint && ![res containsObject:targetPoint])
                [res addObject:targetPoint];
        }
    }
}

- (NSArray<OASWptPt *> *)findPointsNearSegments:(NSArray<OASTrkSegment *> *)segments radius:(int)radius point:(CLLocationCoordinate2D)point
{
    const auto screenBbox = self.mapView.getVisibleBBox31;
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
    QuadRect *screenRect = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
    for (OASTrkSegment *segment in segments)
    {
        QuadRect *trackBounds = [self.class calculateBounds:segment.points];
        if ([QuadRect intersects:screenRect b:trackBounds])
        {
            NSArray<OASWptPt *> *points = [self.class findPointsNearSegment:segment.points radius:radius point:point];
            if (points != nil)
                return points;
        }
    }
    return nil;
}

+ (QuadRect *) calculateBounds:(NSArray<OASWptPt *> *)pts
{
    return [self updateBounds:pts startIndex:0];
}

+ (QuadRect *) updateBounds:(NSArray<OASWptPt *> *)pts startIndex:(int)startIndex
{
    double left = DBL_MAX, top = DBL_MIN, right = DBL_MIN, bottom = DBL_MAX;
    for (NSInteger i = startIndex; i < pts.count; i++)
    {
        OASWptPt *pt = pts[i];
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

+ (NSArray<OASWptPt *> *) findPointsNearSegment:(NSArray<OASWptPt *> *)points radius:(int)r point:(CLLocationCoordinate2D)coordinatePoint
{
    if (points.count == 0)
        return nil;
    
    CGPoint point;
    auto coordI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(coordinatePoint.latitude, coordinatePoint.longitude));
    if (![OARootViewController.instance.mapPanel.mapViewController.mapView convert:&coordI toScreen:&point checkOffScreen:YES])
        return nil;
    
    OASWptPt *prevPoint = points.firstObject;
    auto prevPointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(prevPoint.position.latitude, prevPoint.position.longitude));
    CGPoint prevPxPoint;
    [OARootViewController.instance.mapPanel.mapViewController.mapView convert:&prevPointI toScreen:&prevPxPoint checkOffScreen:YES];
    int pcross = [self placeInBbox:prevPxPoint.x y:prevPxPoint.y mx:point.x my:point.y halfw:r halfh:r];
    for (NSInteger i = 1; i < points.count; i++)
    {
        OASWptPt *pnt = points[i];
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
        sensorTypes = [NSSet setWithArray:@[
            @(EOAGPX3DLineVisualizationByTypeHeartRate),
            @(EOAGPX3DLineVisualizationByTypeBicycleCadence),
            @(EOAGPX3DLineVisualizationByTypeBicyclePower),
            @(EOAGPX3DLineVisualizationByTypeTemperatureA),
            @(EOAGPX3DLineVisualizationByTypeTemperatureW),
            @(EOAGPX3DLineVisualizationByTypeSpeedSensor)]];
    });
    return [sensorTypes containsObject:@(type)];
}

- (double)getValidElevation:(double)elevation
{
    return isnan(elevation) ? 0 : elevation;
}

- (BOOL)isInstanceOfOASWptPt:(id)point
{
    return [point isKindOfClass:[OASWptPt class]];
}

- (BOOL)is3DMapsEnabled
{
    return _plugin && [_plugin is3DMapsEnabled] && [_plugin isTerrainLayerEnabled];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OASGpxDataItem class]] || [obj isKindOfClass:[OASGpxFile class]])
    {
        OASGpxDataItem *item = (OASGpxDataItem *) obj;
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetGPX;
        targetPoint.targetObj = [obj isKindOfClass:[OASGpxDataItem class]] ? (OASGpxDataItem *)obj : (OASGpxFile *) obj;

        targetPoint.icon = [UIImage imageNamed:@"ic_custom_trip"];
        targetPoint.title = [obj isKindOfClass:[OASGpxDataItem class]] ? item.gpxFileNameWithoutExtension :  OALocalizedString(@"shared_string_currently_recording_track");

        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        targetPoint.values = @{ @"opened_from_map": @YES };

        return targetPoint;
    }
    else if ([obj isKindOfClass:[OAGpxWptItem class]])
    {
        OAGpxWptItem *item = (OAGpxWptItem *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetWpt;
        targetPoint.location = CLLocationCoordinate2DMake(item.point.lat, item.point.lon);
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
            OASWptPt *wpt = mapViewController.foundWpt;
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
            item.point.lat = position.latitude;
            item.point.lon = position.longitude;
            item.point.position = position;

            OASGpxFile *gpxFile = [[OASelectedGPXHelper instance] getGpxFileFor:item.docPath];
            if (gpxFile)
            {
                OASKFile *file = [[OASKFile alloc] initWithFilePath:item.docPath];
                gpxFile.author = [OAAppVersion getFullVersionWithAppName];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpxFile];
                
                NSDictionary<NSString *, OASGpxFile *> *dic = @{ item.docPath : gpxFile };
                [self refreshGpxTracks:dic reset:YES];
            }
        }
        else
        {
            OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
            [helper updatePointCoordinates:item.point newLocation:position];
            item.point.position = position;
            [self.app.updateRecTrackOnMapObservable notifyEventWithKey:@(YES)];
        }
    }
}

- (UIImage *)getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        if ([OARootViewController instance].mapPanel.activeTargetType == OATargetNewMovableWpt)
            return [UIImage imageNamed:@"ic_map_pin"];

        OAGpxWptItem *point = (OAGpxWptItem *)object;
        NSString *backgroundType = point.point.getBackgroundType ?: DEFAULT_ICON_SHAPE_KEY;
        NSString *iconName = point.point.getIconName ?: DEFAULT_ICON_NAME_KEY;

        return [OAFavoritesLayer getImageWithColor:point.color
                                        background:backgroundType
                                              icon:[@"mx_" stringByAppendingString:iconName]];
    }
    OAFavoriteColor *def = [OADefaultFavorite nearestFavColor:OADefaultFavorite.builtinColors.firstObject];
    return [OAFavoritesLayer getImageWithColor:def.color
                                    background:DEFAULT_ICON_SHAPE_KEY
                                          icon:[@"mx_" stringByAppendingString:DEFAULT_ICON_NAME_KEY]];
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
