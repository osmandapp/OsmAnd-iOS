//
//  OAGpxAdditionalIconsProvider.m
//  OsmAnd
//
//  Created by Paul on 13/10/21.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxAdditionalIconsProvider.h"
#import "OANativeUtilities.h"
#import "OAGpxTrackAnalysis.h"

#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/GpxDocument.h>
#import <OsmAndCore/TextRasterizer.h>

#include <SkBitmapDevice.h>
#include <SkBitmap.h>
#include <SkRect.h>

#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OASelectedGPXHelper.h"
#import "OANativeUtilities.h"
#import "OAOsmAndFormatter.h"

#define kIconShadowInset 11.0

static const UIFont *textFont = [UIFont systemFontOfSize:15.];

OAGpxAdditionalIconsProvider::OAGpxAdditionalIconsProvider()
: _startIcon([OANativeUtilities skBitmapFromPngResource:@"map_track_point_start"])
, _finishIcon([OANativeUtilities skBitmapFromPngResource:@"map_track_point_finish"])
, _startFinishIcon([OANativeUtilities skBitmapFromPngResource:@"map_track_point_start_finish"])
, _textRasterizer(TextRasterizer::getDefault())
, _cachedZoomLevel(MinZoomLevel)
{
    _captionStyle
        .setWrapWidth(100)
        .setMaxLines(1)
        .setBold(false)
        .setItalic(false)
        .setSize(15.0 * UIScreen.mainScreen.scale);
    
    const auto& activeGpx = OASelectedGPXHelper.instance.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        OAGPXDatabase *gpxDb = OAGPXDatabase.sharedDb;
        path = [[gpxDb getFileDir:path] stringByAppendingPathComponent:path.lastPathComponent];
        OAGPX *gpx = [gpxDb getGPXItem:path];
        if (gpx.showStartFinish)
        {
            const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(it.value());
            if (!doc)
                continue;
            const auto& tracks = doc->tracks;
            for (auto trkIt = tracks.begin(); trkIt != tracks.end(); ++trkIt)
            {
                const auto& trk = *trkIt;
                for (auto segIt = trk->segments.begin(); segIt != trk->segments.end(); ++segIt)
                {
                    const auto& seg = *segIt;
                    _startFinishLocations.append({OsmAnd::Utilities::convertLatLonTo31(seg->points.first()->position),
                        OsmAnd::Utilities::convertLatLonTo31(seg->points.last()->position)});
                }
            }
        }
        if (gpx.splitType != EOAGpxSplitTypeNone)
        {
            QWriteLocker scopedLocker(&_lock);
            
            auto docConst = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(it.value());
            auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(docConst);
            OAGPXDocument *gpxDoc = [[OAGPXDocument alloc] initWithGpxDocument:doc];
            NSArray<OAGPXTrackAnalysis *> *splitData = nil;
            BOOL splitByTime = NO;
            BOOL splitByDistance = NO;
            switch (gpx.splitType) {
                case EOAGpxSplitTypeDistance: {
                    splitData = [gpxDoc splitByDistance:gpx.splitInterval];
                    splitByDistance = YES;
                    break;
                }
                case EOAGpxSplitTypeTime: {
                    splitData = [gpxDoc splitByTime:gpx.splitInterval];
                    splitByTime = YES;
                    break;
                }
                default:
                    break;
            }
            if (!splitByDistance && !splitByTime)
                return;
            
            if (splitData)
            {
                for (NSInteger i = 1; i < splitData.count; i++)
                {
                    OAGPXTrackAnalysis *seg = splitData[i];
                    double metricStartValue = splitData[i - 1].metricEnd;
                    OAGpxWpt *pt = seg.locationStart;
                    if (pt)
                    {
                        const auto pos31 = Utilities::convertLatLonTo31(LatLon(pt.getLatitude, pt.getLongitude));
                        QString stringValue;
                        if (splitByDistance)
                            stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedDistance:metricStartValue]);
                        else if (splitByTime)
                            stringValue = QString::fromNSString([OAOsmAndFormatter getFormattedTimeInterval:metricStartValue shortFormat:YES]);
                        _labelsAndCoordinates.push_back({pos31, {stringValue, (int) gpx.color}});
                    }
                }
            }
        }
    }
}

OAGpxAdditionalIconsProvider::~OAGpxAdditionalIconsProvider()
{
}

OsmAnd::ZoomLevel OAGpxAdditionalIconsProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel5;
}

OsmAnd::ZoomLevel OAGpxAdditionalIconsProvider::getMaxZoom() const
{
    return OsmAnd::MaxZoomLevel;
}

bool OAGpxAdditionalIconsProvider::supportsNaturalObtainData() const
{
    return true;
}

std::shared_ptr<SkBitmap> OAGpxAdditionalIconsProvider::getSplitIconForValue(const QPair<QString, int>& labelData)
{
    const auto& text = labelData.first;
    int colorValue = labelData.second;
    UIColor *col = UIColorFromARGB(colorValue);
    CGFloat r, g, b, a;
    [col getRed:&r green:&g blue:&b alpha:&a];
    ColorARGB backgroundColor(colorValue);
    ColorARGB textColor;
    if ([OAUtilities isColorBright:col])
        textColor = ColorARGB(0xFF000000);
    else
        textColor = ColorARGB(0xFFFFFFFF);
    
    _captionStyle.setColor(textColor);
    
    const auto textBmp = _textRasterizer->rasterize(text, _captionStyle);
    if (textBmp)
    {
        const auto bitmap = std::make_shared<SkBitmap>();
        CGFloat bitmapWidth = textBmp->width() + (20 * UIScreen.mainScreen.scale);
        CGFloat bitmapHeight = textBmp->height() + (20 * UIScreen.mainScreen.scale);
        CGFloat strokeWidth = 2.5 * UIScreen.mainScreen.scale;
        if (bitmap->isNull())
        {
            if (!bitmap->tryAllocPixels(SkImageInfo::MakeN32Premul(bitmapWidth, bitmapHeight)))
            {
                LogPrintf(OsmAnd::LogSeverityLevel::Error,
                          "Failed to allocate bitmap of size %dx%d",
                          bitmapWidth,
                          bitmapHeight);
                return nullptr;
            }
            
            bitmap->eraseColor(SK_ColorTRANSPARENT);
        }

        SkBitmapDevice target(*bitmap.get());
        SkCanvas canvas(&target);
        SkPaint paint;
        paint.setStyle(SkPaint::Style::kStroke_Style);
        paint.setColor(SkColorSetARGBInline(255, r * 255, g * 255, b * 255));
        paint.setStrokeWidth(strokeWidth);
        SkRect rect;
        rect.setXYWH(strokeWidth, strokeWidth, bitmapWidth - (strokeWidth * 2), bitmapHeight - (strokeWidth * 2));
        canvas.drawRoundRect(rect, 20, 20, paint);
        
        paint.reset();
        paint.setStyle(SkPaint::Style::kFill_Style);
        paint.setColor(SkColorSetARGBInline(200, r * 255, g * 255, b * 255));
        rect.setXYWH(strokeWidth * 1.5, strokeWidth * 1.5, rect.width() - strokeWidth, rect.height() - strokeWidth);
        canvas.drawRoundRect(rect, 16, 16, paint);
        
        canvas.drawBitmap(*textBmp,
                          (bitmapWidth - textBmp->width()) / 2.0f,
                          (bitmapHeight - textBmp->height()) / 2.0f,
                          nullptr);
        
        canvas.flush();
        
        return bitmap;
    }
    
    return textBmp;
}

void OAGpxAdditionalIconsProvider::buildSplitIntervalsSymbolsGroup(const OsmAnd::AreaI &bbox31, double metersPerPixel, QList<QPair<PointI, QPair<QString, int>>> visibleLabels, QList<std::shared_ptr<MapSymbolsGroup>>& mapSymbolsGroups) {
    const auto mapSymbolsGroup = std::make_shared<OsmAnd::MapSymbolsGroup>();
    
    for (auto it = visibleLabels.begin(); it != visibleLabels.end(); ++it)
    {
        const auto pos31 = (*it).first;
        const auto textInfo = (*it).second;
        
        if (!bbox31.contains(pos31))
        {
            continue;
        }
        
        const auto bitmap = getSplitIconForValue(textInfo);
        if (bitmap)
        {
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = -120000;
            mapSymbol->bitmap = bitmap;
            mapSymbol->size = OsmAnd::PointI(bitmap->width(), bitmap->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = pos31;
            mapSymbolsGroup->symbols.push_back(mapSymbol);
        }
    }
    mapSymbolsGroups.push_back(mapSymbolsGroup);
}

void OAGpxAdditionalIconsProvider::buildStartFinishSymbolsGroup(const OsmAnd::AreaI &bbox31, double metersPerPixel, QList<std::shared_ptr<MapSymbolsGroup>>& mapSymbolsGroups) {
    const auto mapSymbolsGroup = std::make_shared<OsmAnd::MapSymbolsGroup>();
    
    for (const auto& pair : _startFinishLocations)
    {
        const auto startPos31 = pair.first;
        const auto finishPos31 = pair.second;
        
        bool containsStart = bbox31.contains(startPos31);
        bool containsFinish = bbox31.contains(finishPos31);
        if (containsStart && containsFinish)
        {
            double distance = ((_startIcon->width() - (kIconShadowInset * 2)) * metersPerPixel) / 2;
            const auto startIconArea = Utilities::boundingBox31FromAreaInMeters(distance, startPos31);
            const auto finishIconArea = Utilities::boundingBox31FromAreaInMeters(distance, finishPos31);
            
            if (startIconArea.intersects(finishIconArea))
            {
                const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
                mapSymbol->order = -120000;
                mapSymbol->bitmap = _startFinishIcon;
                mapSymbol->size = PointI(_startFinishIcon->width(), _startFinishIcon->height());
                mapSymbol->languageId = LanguageId::Invariant;
                mapSymbol->position31 = startPos31;
                mapSymbolsGroup->symbols.push_back(mapSymbol);
                continue;
            }
        }
        
        if (containsStart)
        {
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = -120000;
            mapSymbol->bitmap = _startIcon;
            mapSymbol->size = OsmAnd::PointI(_startIcon->width(), _startIcon->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = startPos31;
            mapSymbolsGroup->symbols.push_back(mapSymbol);
        }
        
        if (containsFinish)
        {
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = -120000;
            mapSymbol->bitmap = _finishIcon;
            mapSymbol->size = OsmAnd::PointI(_finishIcon->width(), _finishIcon->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = finishPos31;
            mapSymbolsGroup->symbols.push_back(mapSymbol);
        }
    }
    mapSymbolsGroups.push_back(mapSymbolsGroup);
}

void OAGpxAdditionalIconsProvider::buildVisibleSplits(const double metersPerPixel, QList<QPair<PointI, QPair<QString, int>>>& visibleSplits)
{
    NSDictionary *attrs = @{NSFontAttributeName: textFont};
    for (auto it = _labelsAndCoordinates.begin(); it != _labelsAndCoordinates.end(); ++it)
    {
        const auto pos31 = (*it).first;
        NSString *title = (*it).second.first.toNSString();
        
        CGSize titleSize = [title sizeWithAttributes:attrs];
        double distance = ((fmax(titleSize.width, titleSize.height) + 20) * UIScreen.mainScreen.scale * metersPerPixel) / 2;
        const auto currentIconArea = Utilities::boundingBox31FromAreaInMeters(distance, pos31);
        auto posIterator = it == _labelsAndCoordinates.end() ? it : it + 1;
        visibleSplits.append(*it);
        
        while (posIterator != _labelsAndCoordinates.end())
        {
            const auto nextPos31 = (*posIterator).first;
            NSString *nextTitle = (*posIterator).second.first.toNSString();
            CGSize size = [nextTitle sizeWithAttributes:attrs];
            double nextDistance = ((fmax(size.width, size.height) + 40) * UIScreen.mainScreen.scale * metersPerPixel) / 2;
            const auto nextIconArea = Utilities::boundingBox31FromAreaInMeters(nextDistance, nextPos31);
            if (!currentIconArea.intersects(nextIconArea))
            {
                it = posIterator - 1 != it ? posIterator - 1 : it;
                break;
            }
            posIterator++;
        }
    }
}

QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> OAGpxAdditionalIconsProvider::buildMapSymbolsGroups(const OsmAnd::AreaI &bbox31, const double metersPerPixel)
{
    QReadLocker scopedLocker(&_lock);

    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> mapSymbolsGroups;
    buildStartFinishSymbolsGroup(bbox31, metersPerPixel, mapSymbolsGroups);
    buildSplitIntervalsSymbolsGroup(bbox31, metersPerPixel, _visibleSplitLabels, mapSymbolsGroups);
    return mapSymbolsGroups;
}

bool OAGpxAdditionalIconsProvider::obtainData(const IMapDataProvider::Request& request,
                                            std::shared_ptr<IMapDataProvider::Data>& outData,
                                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric /*= nullptr*/)
{
    const auto& req = OsmAnd::MapDataProviderHelpers::castRequest<OAGpxAdditionalIconsProvider::Request>(request);
    if (pOutMetric)
        pOutMetric->reset();
    
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
    {
        outData.reset();
        return true;
    }
    
    if (req.mapState.zoomLevel != _cachedZoomLevel)
    {
        _cachedZoomLevel = req.mapState.zoomLevel;
        _visibleSplitLabels.clear();
        buildVisibleSplits(req.mapState.metersPerPixel, _visibleSplitLabels);
    }
    
    
    const auto tileId = req.tileId;
    const auto zoom = req.zoom;
    const auto tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(tileId, zoom);
    const auto mapSymbolsGroups = buildMapSymbolsGroups(tileBBox31, req.mapState.metersPerPixel);
    outData.reset(new Data(tileId, zoom, mapSymbolsGroups));
    
    return true;
}

bool OAGpxAdditionalIconsProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAGpxAdditionalIconsProvider::obtainDataAsync(const IMapDataProvider::Request& request,
                                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                 const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

OAGpxAdditionalIconsProvider::Data::Data(const OsmAnd::TileId tileId_,
                                       const OsmAnd::ZoomLevel zoom_,
                                       const QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> >& symbolsGroups_,
                                       const RetainableCacheMetadata* const pRetainableCacheMetadata_ /*= nullptr*/)
: IMapTiledSymbolsProvider::Data(tileId_, zoom_, symbolsGroups_, pRetainableCacheMetadata_)
{
}

OAGpxAdditionalIconsProvider::Data::~Data()
{
    release();
}
