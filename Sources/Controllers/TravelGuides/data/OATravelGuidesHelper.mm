//
//  OATravelGuidesHelper.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATravelGuidesHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OAAmenitySearcher.h"
#import "OAAmenitySearcher+cpp.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAPOI.h"
#import "OAUtilities.h"
#import "OAQuickSearchHelper.h"
#import "OASearchUICore.h"
#import "OASearchSettings.h"
#import "OASearchPhrase.h"
#import "OANameStringMatcher.h"
#import "OAResourcesUIHelper.h"
#import "OAWikiArticleHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAMapAlgorithms.h"
#import "OAMapLayers.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAppVersion.h"

#include <cmath>
#include <exception>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfFile.h>
#include <OsmAndCore/Data/ObfInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/BinaryMapObject.h>

static const int kTravelGpxGroupedPointSearchRadiusMeters = 50;

static NSString *OATravelGuidesCrashContext(NSArray<NSString *> *readers, OATravelArticle *article)
{
    return [NSString stringWithFormat:@"title='%@', routeId='%@', file='%@', readers=%lu",
            article.title ?: @"",
            article.routeId ?: @"",
            article.file ?: @"",
            (unsigned long)readers.count];
}

static BOOL OATravelGuidesIsFiniteCoordinate(double lat, double lon)
{
    return std::isfinite(lat) && std::isfinite(lon);
}

static BOOL OATravelGuidesIsWorldMap(NSString *fileNameOrPath)
{
    NSString *lowerName = [[fileNameOrPath lowercaseString] lastPathComponent];
    return [lowerName hasPrefix:@"world_"] || [lowerName containsString:@"basemap"];
}

static BOOL OATravelGuidesIsOsmRouteId(NSString *routeId)
{
    if (NSStringIsEmpty(routeId))
        return NO;

    return [routeId hasPrefix:OATravelGpx.ROUTE_ID_OSM_PREFIX_LEGACY] ||
           [routeId hasPrefix:OATravelGpx.ROUTE_ID_OSM_PREFIX];
}

static BOOL OATravelGuidesLocationIntersectsReader(CLLocation *location, NSString *reader)
{
    if (!location || !OATravelGuidesIsFiniteCoordinate(location.coordinate.latitude, location.coordinate.longitude) ||
        NSStringIsEmpty(reader))
    {
        return YES;
    }

    OsmAndAppInstance app = OsmAndApp.instance;
    const auto& localResource = app.resourcesManager->getLocalResource(QString::fromNSString(reader));
    if (!localResource)
        return YES;

    const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
    if (!obfMetadata || !obfMetadata->obfFile || !obfMetadata->obfFile->obfInfo)
        return YES;

    const auto location31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude));
    const auto bbox31 = OsmAnd::AreaI(location31, location31);
    const auto desiredDataTypes = OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI);
    return obfMetadata->obfFile->obfInfo->containsDataFor(&bbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, desiredDataTypes);
}

static OsmAnd::AreaI OATravelGuidesFullArea31()
{
    return OsmAnd::AreaI(OsmAnd::PointI(0, 0), OsmAnd::PointI(INT_MAX, INT_MAX));
}

static OsmAnd::AreaI OATravelGuidesSearchArea31(OATravelArticle *article, BOOL *constrained)
{
    if (constrained)
        *constrained = NO;

    if ([article hasBbox31] && article.bbox31)
    {
        OASKQuadRect *bbox31 = article.bbox31;
        if (std::isfinite(bbox31.left) && std::isfinite(bbox31.top) &&
            std::isfinite(bbox31.right) && std::isfinite(bbox31.bottom))
        {
            if (constrained)
                *constrained = YES;
            return OsmAnd::AreaI(OsmAnd::PointI((int)bbox31.left, (int)bbox31.top),
                                 OsmAnd::PointI((int)bbox31.right, (int)bbox31.bottom));
        }
    }

    if (article.routeRadius > 0 && OATravelGuidesIsFiniteCoordinate(article.lat, article.lon))
    {
        if (constrained)
            *constrained = YES;
        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(article.lat, article.lon));
        return (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(article.routeRadius, locI);
    }

    return OATravelGuidesFullArea31();
}

static QList<OsmAnd::AreaI> OATravelGuidesGroupedSearchAreas(NSArray<OAPOI *> *amenities)
{
    QList<OsmAnd::AreaI> areas;
    QHash<QString, OsmAnd::AreaI> groupedAreas;

    for (OAPOI *amenity in amenities)
    {
        if (!amenity || ![amenity isRouteTrack] ||
            !OATravelGuidesIsFiniteCoordinate(amenity.latitude, amenity.longitude))
        {
            continue;
        }

        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(amenity.latitude, amenity.longitude));
        OsmAnd::AreaI pointArea = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(kTravelGpxGroupedPointSearchRadiusMeters, locI);
        NSString *groupId = [amenity getAdditionalInfo:OATravelGpx.ROUTE_SEGMENT_INDEX];
        if (NSStringIsEmpty(groupId))
        {
            areas.append(pointArea);
        }
        else
        {
            QString qGroupId = QString::fromNSString(groupId);
            if (groupedAreas.contains(qGroupId))
            {
                OsmAnd::AreaI groupedArea = groupedAreas[qGroupId];
                groupedArea.enlargeToInclude(pointArea);
                groupedAreas[qGroupId] = groupedArea;
            }
            else
            {
                groupedAreas.insert(qGroupId, pointArea);
            }
        }
    }

    const auto groupedValues = groupedAreas.values();
    for (const auto& groupedArea : groupedValues)
        areas.append(groupedArea);

    return areas;
}

static void OATravelGuidesAppendUniqueSegments(QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> &target,
                                               const QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> &source)
{
    for (const auto& candidate : source)
    {
        if (!candidate)
            continue;

        bool duplicate = false;
        OsmAnd::MapObject::SharingKey candidateKey = 0;
        bool hasCandidateKey = candidate->obtainSharingKey(candidateKey);
        for (const auto& existing : target)
        {
            if (existing == candidate)
            {
                duplicate = true;
                break;
            }

            OsmAnd::MapObject::SharingKey existingKey = 0;
            if (hasCandidateKey && existing && existing->obtainSharingKey(existingKey) && candidateKey == existingKey)
            {
                duplicate = true;
                break;
            }
        }

        if (!duplicate)
            target.append(candidate);
    }
}

static BOOL OATravelGuidesSegmentMatchesRouteType(const std::shared_ptr<const OsmAnd::BinaryMapObject> &segment,
                                                  OATravelGpx *travelGpx)
{
    NSString *routeType = [travelGpx getRouteType];
    if (NSStringIsEmpty(routeType))
        return YES;

    QString qRouteType = QString::fromNSString(routeType);
    QHash<QString, QString> tags = segment->getResolvedAttributes();
    if (tags.value(QStringLiteral("route_type")) == qRouteType ||
        tags.value(QStringLiteral("route")) == QStringLiteral("segment"))
    {
        return YES;
    }

    for (const auto& captionAttributeId : OsmAnd::constOf(segment->captionsOrder))
    {
        QString tag = segment->attributeMapping->decodeMap[captionAttributeId].tag;
        const auto& value = OsmAnd::constOf(segment->captions)[captionAttributeId];
        if ((tag == QStringLiteral("route_type") && value == qRouteType) ||
            (tag == QStringLiteral("route") && value == QStringLiteral("segment")))
        {
            return YES;
        }
    }

    return NO;
}

@interface OATravelGuidesHelper ()

+ (QList<std::shared_ptr<const OsmAnd::BinaryMapObject>>)searchGpxMapObject:(OATravelGpx *)travelGpx bbox31List:(const QList<OsmAnd::AreaI> &)bbox31List reader:(NSString *)reader;
+ (void)collectGpxFileExtensionsFromSegments:(const QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> &)segments gpxFileExtensions:(NSMutableDictionary<NSString *, NSString *> *)gpxFileExtensions;
+ (void)collectPointsAndRouteAmenities:(NSString *)reader article:(OATravelArticle *)article searchArea:(OsmAnd::AreaI)searchArea searchAreaConstrained:(BOOL)searchAreaConstrained pointList:(NSMutableArray<OAPOI *> *)pointList routeAmenityList:(NSMutableArray<OAPOI *> *)routeAmenityList;
+ (NSArray<NSString *> *)pointSearchFiltersForArticle:(OATravelArticle *)article;
+ (BOOL)shouldSkipReader:(NSString *)reader article:(OATravelArticle *)article;
+ (OAGPXDocumentAdapter *)buildGpxFileUnsafe:(NSArray<NSString *> *)readers article:(OATravelArticle *)article;
+ (void)searchTravelGpxAmenityByRouteId:(NSMutableArray<OAFoundAmenity *> *)amenitiesList repo:(NSString *)repo routeId:(NSString *)routeId location:(CLLocation *)location searchRadius:(NSInteger)searchRadius;

@end

@implementation OAFoundAmenity

- (instancetype) initWithFile:(NSString *)file amenity:(OAPOI *)amenity
{
    self = [super init];
    if (self)
    {
        self.file = file;
        self.amenity = amenity;
    }
    return self;
}

@end


@implementation OATravelGuidesHelper

static const NSArray<NSString *> *wikivoyageOSMTags = @[@"wikidata", @"wikipedia", @"opening_hours", @"address", @"email", @"fax", @"directions", @"price", @"phone"];

+ (void) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilters:(NSArray<NSString *> *)searchFilters publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAnd::AreaI bbox31;
    OsmAnd::PointI locI;
    if (radius != -1)
    {
        locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
        bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, locI);
    }
    else
    {
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    }
    [OAAmenitySearcher findTravelGuides:searchFilters currentLocation:locI bbox31:bbox31 reader:reader publish:publish];
}

+ (void) searchAmenity:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom  reader:(NSString *)reader searchFilters:(NSArray<NSString *> *)searchFilters publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAnd::PointI location = OsmAnd::PointI(x, y);
    OsmAnd::PointI topLeft = OsmAnd::PointI(left, top);
    OsmAnd::PointI bottomRight = OsmAnd::PointI(right, bottom);
    OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    [OAAmenitySearcher findTravelGuides:searchFilters currentLocation:location bbox31:bbox31 reader:reader publish:publish];
}

+ (void) searchAmenity:(NSString *)searchQuery x:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom reader:(NSString *)reader searchFilters:(NSArray<NSString *> *)searchFilters publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAnd::PointI location = OsmAnd::PointI(x, y);
    OsmAnd::PointI topLeft = OsmAnd::PointI(left, top);
    OsmAnd::PointI bottomRight = OsmAnd::PointI(right, bottom);
    OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(0, 0));
    [OAAmenitySearcher.sharedInstance findTravelGuidesByKeyword:searchQuery categoryNames:searchFilters poiTypeName:nil currentLocation:locI bbox31:bbox31 reader:reader publish:publish];
}

+ (void) searchAmenity:(NSString *)searchQuery categoryNames:(NSArray<NSString *> *)categoryNames radius:(int)radius lat:(double)lat lon:(double)lon reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAnd::AreaI bbox31;
    OsmAnd::PointI locI;
    if (radius != -1)
    {
        locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
        bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, locI);
    }
    else
    {
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
        if (lat != -1 && lon != -1)
            locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    }
    [OAAmenitySearcher.sharedInstance findTravelGuidesByKeyword:searchQuery categoryNames:categoryNames poiTypeName:nil currentLocation:locI bbox31:bbox31 reader:reader publish:publish];
}

+ (void) showContextMenuWithLatitude:(double)latitude longitude:(double)longitude
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.contextMenuLayer getUnknownTargetPoint:latitude longitude:longitude];
    targetPoint.centerMap = YES;
    [mapPanel showContextMenu:targetPoint];
}

+ (OASWptPt *) createWptPt:(OAPOI *)amenity lang:(NSString *)lang
{
    OASWptPt *wptPt = [[OASWptPt alloc] init];
    wptPt.name = amenity.name;
    wptPt.position = CLLocationCoordinate2DMake(amenity.latitude, amenity.longitude);
    wptPt.desc = amenity.desc;
    
    if ([amenity getSite])
    {
        wptPt.link = [[OASLink alloc] initWithHref:[amenity getSite]];
    }
    
    NSString *color = [amenity getColor];
    OAGPXColor *gpxColor = [OAGPXColor getColorFromName:color];
    if (gpxColor) {
        OASInt *color = [[OASInt alloc] initWithInt:(int)gpxColor.color];
        [wptPt setColorColor:color];
    }
    
    if ([amenity gpxIcon])
        [wptPt setIconNameIconName:[amenity gpxIcon]];

    NSString *category = [amenity getTagSuffix:@"category_"];
    if (category)
    {
        wptPt.category = [OAUtilities capitalizeFirstLetter:category];
    }
    for (NSString *key in [amenity getAdditionalInfo].allKeys)
    {
        if (![wikivoyageOSMTags containsObject:key])
        {
            continue;
        }
        NSString *amenityValue = [amenity getAdditionalInfo][key];
        if (amenityValue)
        {
            auto extension = wptPt.getExtensionsToWrite;
            extension[key] = amenityValue;
            wptPt.extensions = extension;
        }
    }
    return wptPt;
}

+ (NSArray<NSString *> *) getAllObfList
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableArray<NSString *> *obfFilenames = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
    {
        if (resource->type == OsmAnd::ResourcesManager::ResourceType::Travel ||
            resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
        {
            [obfFilenames addObject:resource->id.toNSString()];
        }
    }
    return obfFilenames;
}

+ (NSArray<NSString *> *) getTravelGuidesObfList
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableArray<NSString *> *obfFilenames = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
    {
        if (resource->type == OsmAnd::ResourcesManager::ResourceType::Travel)
        {
            [obfFilenames addObject:resource->id.toNSString()];
        }
    }
    return obfFilenames;
}

+ (CLLocation *) getMapCenter
{
    OsmAndAppInstance app = OsmAndApp.instance;
    Point31 mapCenter = app.data.mapLastViewedState.target31;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(mapCenter.x, mapCenter.y));
    return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
}

+ (NSString *) getPatrialContent:(NSString *)content
{
    return [OAWikiArticleHelper getPartialContent:content];
}

+ (NSString *) normalizeFileUrl:(NSString *)url
{
    return [OAWikiArticleHelper normalizeFileUrl:url];
}

+ (NSString *) createGpxFile:(OATravelArticle *)article fileName:(NSString *)fileName
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL exists = [fileManager fileExistsAtPath:OsmAndApp.instance.gpxTravelPath];
    if (!exists)
        [fileManager createDirectoryAtPath:OsmAndApp.instance.gpxTravelPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    OASGpxFile *gpx = [article gpxFile].object;
    NSString *filePath = [OsmAndApp.instance.gpxTravelPath stringByAppendingPathComponent:fileName];
    
    OASKFile *filePathToSaveGPX = [[OASKFile alloc] initWithFilePath:filePath];
    // save to disk
    OASKException *exception = [[OASGpxUtilities shared] writeGpxFileFile:filePathToSaveGPX gpxFile:gpx];
    if (!exception)
    {
        // save to db
        OASGpxDataItem *dataItem = [[OAGPXDatabase sharedDb] addGPXFileToDBIfNeeded:filePathToSaveGPX.absolutePath];
        if (dataItem)
        {
            OASGpxTrackAnalysis *analysis = [dataItem getAnalysis];
            
            if (analysis.locationStart)
            {
                OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
                NSString *nearestCityString = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
                [[OASGpxDbHelper shared] updateDataItemParameterItem:dataItem
                                                           parameter:OASGpxParameter.nearestCityName
                                                               value:nearestCityString];
            }
        }
    } else {
        NSLog(@"[ERROR] -> save gpx");
    }
    
    return filePath;
}

+ (BOOL)shouldSkipReader:(NSString *)reader article:(OATravelArticle *)article
{
    if ([article isKindOfClass:OATravelGpx.class])
    {
        if (OATravelGuidesIsWorldMap(reader))
            return YES;
    }

    if (article.file != nil && ![article hasOsmRouteId] && ![article.file isEqualToString:reader])
        return YES;

    return NO;
}

+ (NSArray<NSString *> *)pointSearchFiltersForArticle:(OATravelArticle *)article
{
    NSString *pointFilter = [article getPointFilterString];
    if ([article isKindOfClass:OATravelGpx.class])
        return @[ROUTE_TRACK, pointFilter];

    return @[pointFilter];
}

+ (void)collectPointsAndRouteAmenities:(NSString *)reader article:(OATravelArticle *)article searchArea:(OsmAnd::AreaI)searchArea searchAreaConstrained:(BOOL)searchAreaConstrained pointList:(NSMutableArray<OAPOI *> *)pointList routeAmenityList:(NSMutableArray<OAPOI *> *)routeAmenityList
{
    NSArray<NSString *> *searchFilters = [self pointSearchFiltersForArticle:article];

    BOOL (^publish)(OAPOI *amenity) = ^BOOL(OAPOI *amenity) {
        NSString *routeId = article.routeId;
        if (!amenity || NSStringIsEmpty(routeId) || ![[amenity getRouteId] isEqualToString:routeId])
            return NO;

        if ([amenity isRouteTrack])
        {
            [routeAmenityList addObject:amenity];
            return NO;
        }

        if ([[article getPointFilterString] isEqualToString:@"route_track_point"])
        {
            [pointList addObject:amenity];
        }
        else
        {
            NSString *amenityLang = [amenity getTagSuffix:@"lang_yes:"];
            if ([article.lang isEqualToString:amenityLang])
                [pointList addObject:amenity];
        }
        return NO;
    };

    OsmAnd::PointI location = OsmAnd::PointI(0, 0);
    BOOL isTravelGpx = [article isKindOfClass:OATravelGpx.class];
    if (isTravelGpx && searchAreaConstrained)
    {
        [OAAmenitySearcher findTravelGuides:searchFilters currentLocation:location bbox31:searchArea reader:reader publish:publish];

        if (routeAmenityList.count == 0 && article.title && article.title.length > 0)
            [OAAmenitySearcher.sharedInstance findTravelGuidesByKeyword:article.title categoryNames:searchFilters poiTypeName:nil currentLocation:location bbox31:searchArea reader:reader publish:publish];
    }
    else if (article.title && article.title.length > 0)
    {
        [OAAmenitySearcher.sharedInstance findTravelGuidesByKeyword:article.title categoryNames:searchFilters poiTypeName:nil currentLocation:location bbox31:searchArea reader:reader publish:publish];
    }
    else
    {
        [OAAmenitySearcher findTravelGuides:searchFilters currentLocation:location bbox31:searchArea reader:reader publish:publish];
    }
}

+ (void)collectGpxFileExtensionsFromSegments:(const QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> &)segments gpxFileExtensions:(NSMutableDictionary<NSString *, NSString *> *)gpxFileExtensions
{
    for (const auto& segment : segments)
    {
        QHash<QString, QString> tags = segment->getResolvedAttributes();

        for (const auto& captionAttributeId : OsmAnd::constOf(segment->captionsOrder))
        {
            QString tag = segment->attributeMapping->decodeMap[captionAttributeId].tag;
            const auto& value = OsmAnd::constOf(segment->captions)[captionAttributeId];
            if (!tag.isEmpty() && !value.isEmpty())
                gpxFileExtensions[tag.toNSString()] = value.toNSString();
        }

        for (QString qKey : tags.keys())
        {
            NSString *key = qKey.toNSString();
            NSString *value = tags[qKey].toNSString();
            if (!NSStringIsEmpty(key) && !NSStringIsEmpty(value))
            {
                if ([key hasPrefix:OATravelGpx.ROUTE_ACTIVITY_TYPE])
                {
                    gpxFileExtensions[OASPointAttributes.ACTIVITY_TYPE] = value;
                }
                else if ([key hasPrefix:@"shield_"] ||
                         [key hasPrefix:@"osmc_"] ||
                         [key hasPrefix:@"network"])
                {
                    gpxFileExtensions[key] = value;
                }
            }
        }
    }
}

//In android function with this name works differently. Just moved most part of original code here.
+ (QList<std::shared_ptr<const OsmAnd::BinaryMapObject>>) fetchSegmentsAndPoints:(NSArray<NSString *> *)readers article:(OATravelArticle *)article pointList:(NSMutableArray<OAPOI *> *)pointList gpxFileExtensions:(NSMutableDictionary<NSString *, NSString *> *)gpxFileExtensions
{
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;

    for (NSString *reader in readers)
    {
        if ([self.class shouldSkipReader:reader article:article])
        {
            continue;
        }

        BOOL searchAreaConstrained = NO;
        OsmAnd::AreaI searchArea = OATravelGuidesSearchArea31(article, &searchAreaConstrained);
        NSMutableArray<OAPOI *> *readerPointList = [NSMutableArray array];
        NSMutableArray<OAPOI *> *readerRouteAmenityList = [NSMutableArray array];
        [self.class collectPointsAndRouteAmenities:reader article:article searchArea:searchArea searchAreaConstrained:searchAreaConstrained pointList:readerPointList routeAmenityList:readerRouteAmenityList];
        [pointList addObjectsFromArray:readerPointList];

        if ([article isKindOfClass:OATravelGpx.class])
        {
            QList<OsmAnd::AreaI> segmentSearchAreas = OATravelGuidesGroupedSearchAreas(readerRouteAmenityList);
            if (segmentSearchAreas.isEmpty() && searchAreaConstrained)
            {
                segmentSearchAreas.append(searchArea);
            }

            if (segmentSearchAreas.isEmpty())
            {
                NSLog(@"[WARN] -> OATravelGuidesHelper -> skip unconstrained GPX geometry search (%@)", OATravelGuidesCrashContext(readers, article));
                continue;
            }

            QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > foundSegments = [self.class searchGpxMapObject:(OATravelGpx *)article bbox31List:segmentSearchAreas reader:reader];
            OATravelGuidesAppendUniqueSegments(segmentList, foundSegments);
            [self.class collectGpxFileExtensionsFromSegments:foundSegments gpxFileExtensions:gpxFileExtensions];
        }
        
        if (segmentList.size() > 0 && ![article hasOsmRouteId])
        {
            break;
        }
    }
    
    return segmentList;
}

+ (OAGPXDocumentAdapter *) buildGpxFile:(NSArray<NSString *> *)readers article:(OATravelArticle *)article
{
    @try
    {
        @autoreleasepool
        {
            try
            {
                return [self buildGpxFileUnsafe:readers article:article];
            }
            catch (const std::exception &ex)
            {
                NSLog(@"[ERROR] -> OATravelGuidesHelper -> buildGpxFile failed: %s (%@)", ex.what(), OATravelGuidesCrashContext(readers, article));
            }
            catch (...)
            {
                NSLog(@"[ERROR] -> OATravelGuidesHelper -> buildGpxFile failed: unknown C++ exception (%@)", OATravelGuidesCrashContext(readers, article));
            }
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"[ERROR] -> OATravelGuidesHelper -> buildGpxFile failed: %@ %@ (%@)", exception.name, exception.reason, OATravelGuidesCrashContext(readers, article));
    }

    return nil;
}

+ (OAGPXDocumentAdapter *)buildGpxFileUnsafe:(NSArray<NSString *> *)readers article:(OATravelArticle *)article
{
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;
    NSMutableDictionary<NSString *, NSString *> *gpxFileExtensions = [NSMutableDictionary new];
    NSMutableArray<OAPOI *> *pointList = [NSMutableArray array];

    segmentList = [self fetchSegmentsAndPoints:readers article:article pointList:pointList gpxFileExtensions:gpxFileExtensions];

    OASGpxFile *gpxFile = nil;
    BOOL isSuperRoute = NO;
    
    if ([article isKindOfClass:OATravelGpx.class])
    {
        OATravelGpx *travelGpx = (OATravelGpx *)article;
        gpxFile = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
        NSString *name = NSStringIsEmpty(article.title) ? article.routeId : article.title;
        gpxFile.metadata.name = name;
        if (!NSStringIsEmpty(article.title) && [article hasOsmRouteId]) {
            gpxFileExtensions[@"name"] = article.title;
        }
        if (!NSStringIsEmpty(article.descr)) {
            gpxFile.metadata.desc = article.descr;
        }
        isSuperRoute = travelGpx.isSuperRoute;
    }
    else
    {
        NSString *description = article.descr;
        NSString *title = [OAUtilities isValidFileName:description] ? description : article.title;
        gpxFile = [[OASGpxFile alloc] initWithTitle:title lang:article.lang description:description];
    }

    if ([article isKindOfClass:OATravelGpx.class] && segmentList.isEmpty() && !isSuperRoute)
    {
        NSLog(@"[WARN] -> OATravelGuidesHelper -> buildGpxFile produced no safe GPX geometry (%@)", OATravelGuidesCrashContext(readers, article));
        return nil;
    }
    
    if (gpxFileExtensions[OATravelObfHelper.TAG_URL] && gpxFileExtensions[OATravelObfHelper.TAG_URL_TEXT])
    {
        gpxFile.metadata.link = [[OASLink alloc] initWithHref:gpxFileExtensions[OATravelObfHelper.TAG_URL] text:gpxFileExtensions[OATravelObfHelper.TAG_URL_TEXT]];
        [gpxFileExtensions removeObjectForKey:OATravelObfHelper.TAG_URL_TEXT];
        [gpxFileExtensions removeObjectForKey:OATravelObfHelper.TAG_URL];
    }
    else if (gpxFileExtensions[OATravelObfHelper.TAG_URL])
    {
        gpxFile.metadata.link = [[OASLink alloc] initWithHref:gpxFileExtensions[OATravelObfHelper.TAG_URL]];
        [gpxFileExtensions removeObjectForKey:OATravelObfHelper.TAG_URL];
    }
    
    if (!NSStringIsEmpty(article.imageTitle))
    {
        gpxFile.metadata.link = [[OASLink alloc] initWithHref:[OATravelArticle getImageUrlWithImageTitle:article.imageTitle thumbnail:NO]];
    }
    
    if (!segmentList.isEmpty() || isSuperRoute)
    {
        BOOL hasAltitude = NO;
        OASTrack *track = [[OASTrack alloc] init];
        for (const auto& segment : segmentList)
        {
            OASTrkSegment *trkSegment = [[OASTrkSegment alloc] init];
            NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
            NSUInteger skippedInvalidPoints = 0;
            for (const auto& point : segment->points31)
            {
                const auto latLon = OsmAnd::Utilities::convert31ToLatLon(point);
                if (!OATravelGuidesIsFiniteCoordinate(latLon.latitude, latLon.longitude))
                {
                    skippedInvalidPoints++;
                    continue;
                }

                OASWptPt *wptPt = [[OASWptPt alloc] initWithLat:latLon.latitude lon:latLon.longitude];
                [points addObject:wptPt];
            }
            if (skippedInvalidPoints > 0)
            {
                NSLog(@"[WARN] -> OATravelGuidesHelper -> skipped %lu invalid GPX track points, segmentId=%llu (%@)", (unsigned long)skippedInvalidPoints, (unsigned long long)segment->id.id, OATravelGuidesCrashContext(readers, article));
            }
            if (points.count == 0)
            {
                NSLog(@"[WARN] -> OATravelGuidesHelper -> skipped empty GPX track segment, segmentId=%llu (%@)", (unsigned long long)segment->id.id, OATravelGuidesCrashContext(readers, article));
                continue;
            }
            trkSegment.points = points;
            
            QString eleGraphValue;
            QString startEleValue;
            for (const auto& captionAttributeId : OsmAnd::constOf(segment->captionsOrder))
            {
                QString tag = segment->attributeMapping->decodeMap[captionAttributeId].tag;
                const auto& value = OsmAnd::constOf(segment->captions)[captionAttributeId];
                if (tag == QString("ele_graph"))
                    eleGraphValue = value;
                if (tag == QString("start_ele"))
                    startEleValue = value;
            }
            
            if (!eleGraphValue.isEmpty() && trkSegment.points.count > 0)
            {
                hasAltitude = YES;
                auto heightRes = [OAMapAlgorithms decodeIntHeightArrayGraph:eleGraphValue repeatBits:3];
                double startEle = startEleValue.toDouble();
                
                trkSegment = [OAMapAlgorithms augmentTrkSegmentWithAltitudes:trkSegment decodedSteps:heightRes startEle:startEle];
            }
            [track.segments addObject:trkSegment];
        }
        if (track.segments.count == 0 && [article isKindOfClass:OATravelGpx.class] && !isSuperRoute)
        {
            NSLog(@"[WARN] -> OATravelGuidesHelper -> buildGpxFile produced no finite GPX track segments (%@)", OATravelGuidesCrashContext(readers, article));
            return nil;
        }
        
        gpxFile.tracks = [@[track] mutableCopy];;
        //Android also uses extra helper class here: gpxFile.getTracks().add(TravelObfGpxTrackOptimizer.mergeOverlappedSegmentsAtEdges(track));
        
        if (![article isKindOfClass:OATravelGpx.class])
            [gpxFile setRefRef:article.ref];
        
        gpxFile.hasAltitude = hasAltitude;
        
        if (gpxFileExtensions[OASPointAttributes.ACTIVITY_TYPE])
        {
            NSString *activityType = gpxFileExtensions[OASPointAttributes.ACTIVITY_TYPE];
            [gpxFile.metadata getExtensionsToWrite][OASPointAttributes.ACTIVITY_TYPE] = activityType;
            
            // cleanup type and activity tags
            [gpxFileExtensions removeObjectForKey:OATravelGpx.ROUTE_TYPE];
            [gpxFileExtensions removeObjectForKey:OATravelGpx.ROUTE_ACTIVITY_TYPE];
            [gpxFileExtensions removeObjectForKey:[NSString stringWithFormat:@"%@_%@", OATravelGpx.ROUTE_ACTIVITY_TYPE, activityType]];
            [gpxFileExtensions removeObjectForKey:OASPointAttributes.ACTIVITY_TYPE];
        }
        
        //TODO: implement if needed - android also has JSON parser here. For EXTENSIONS_EXTRA_TAGS & METADATA_EXTRA_TAGS keys.
        
        [[gpxFile getExtensionsToWrite] addEntriesFromDictionary:gpxFileExtensions];
    }
    
    //TODO: add point groups support if needed
    //reconstructPointsGroups(gpxFile, pgNames, pgIcons, pgColors, pgBackgrounds); // create groups before points
    
    if (!NSArrayIsEmpty(pointList))
    {
        for (OAPOI *wayPoint in pointList)
        {
            OASWptPt *wpt = [self.class createWptPt:wayPoint lang:article.lang];
            [gpxFile addPointPoint:wpt];
        }
    }
     
    OAGPXDocumentAdapter *gpxAdapter = [[OAGPXDocumentAdapter alloc] init];
    gpxAdapter.object = gpxFile;
    article.gpxFile = gpxAdapter;
    return gpxAdapter;
}

+ (OASGpxDataItem *) buildGpx:(NSString *)path title:(NSString *)title document:(OAGPXDocumentAdapter *)document
{
    return [self buildGpx:path title:title gpxDoc:document.object];
}

+ (OASGpxDataItem *) buildGpx:(NSString *)path title:(NSString *)title gpxDoc:(OASGpxFile *)gpxDoc
{    
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    OASGpxDataItem *gpx = [gpxDb getGPXItem:path];
    if (!gpx)
    {
        gpx = [gpxDb addGPXFileToDBIfNeeded:path];
        if (gpx)
        {
            OASGpxTrackAnalysis *analysis = [gpx getAnalysis];
            
            if (analysis.locationStart)
            {
                OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
                NSString *nearestCityString = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
                [[OASGpxDbHelper shared] updateDataItemParameterItem:gpx
                                                           parameter:OASGpxParameter.nearestCityName
                                                               value:nearestCityString];
            }
        }
    }
    return gpx;
    
}

+ (NSString *) getSelectedGPXFilePath:(NSString *)fileName
{
    return [OASelectedGPXHelper.instance getSelectedGPXFilePath:fileName];
}

+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >) searchGpxMapObject:(OATravelGpx *)travelGpx bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader
{
    return [self.class searchGpxMapObject:travelGpx bbox31:bbox31 reader:reader useAllObfFiles:NO];
}

+ (QList<std::shared_ptr<const OsmAnd::BinaryMapObject>>)searchGpxMapObject:(OATravelGpx *)travelGpx bbox31List:(const QList<OsmAnd::AreaI> &)bbox31List reader:(NSString *)reader
{
    QList<std::shared_ptr<const OsmAnd::BinaryMapObject>> result;
    for (const auto& bbox31 : bbox31List)
    {
        const auto found = [self.class searchGpxMapObject:travelGpx bbox31:bbox31 reader:reader useAllObfFiles:NO];
        OATravelGuidesAppendUniqueSegments(result, found);
    }
    return result;
}

+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >) searchGpxMapObject:(OATravelGpx *)travelGpx bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader useAllObfFiles:(BOOL)useAllObfFiles
{
    OsmAndAppInstance app = OsmAndApp.instance;
    QList< std::shared_ptr<const OsmAnd::ObfFile> > files = app.resourcesManager->obfsCollection->getObfFiles();
    std::shared_ptr<const OsmAnd::ObfFile> res;
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > result;
    
    NSArray<NSString *> *travelObfNames = useAllObfFiles ? [self.class getAllObfList] : [self.class getTravelGuidesObfList];
    
    NSString *filename = travelGpx.file;
    BOOL hasOsmRouteId = [travelGpx hasOsmRouteId];
    if ((!NSStringIsEmpty(filename) && !hasOsmRouteId) || !NSStringIsEmpty(reader))
    {
        for (const auto& file : files)
        {
            NSString *path = [file->filePath.toNSString() lowercaseString];
            if (OATravelGuidesIsWorldMap(path))
                continue;

            if ((!hasOsmRouteId && filename && [path hasSuffix:[filename lowercaseString]]) ||
                (reader && [path hasSuffix:[reader lowercaseString]]))
            {
                const auto found = [self.class searchGpxMapObject:travelGpx res:file bbox31:bbox31];
                OATravelGuidesAppendUniqueSegments(result, found);
            }
        }
    }
    else
    {
        for (const auto& file : files)
        {
            NSString *path = [file->filePath.toNSString() lowercaseString];
            if (OATravelGuidesIsWorldMap(path))
                continue;

            for (NSString *travelObfName in travelObfNames)
            {
                if ([path hasSuffix:[travelObfName lowercaseString]])
                {
                    const auto found =  [self.class searchGpxMapObject:travelGpx res:file bbox31:bbox31];
                    if (found.size() > 0)
                    {
                        OATravelGuidesAppendUniqueSegments(result, found);
                        if (!hasOsmRouteId)
                            return result;
                    }
                }
            }
        }
    }
    return result;
}

+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >) searchGpxMapObject:(OATravelGpx *)travelGpx res:(std::shared_ptr<const OsmAnd::ObfFile>)res bbox31:(OsmAnd::AreaI)bbox31
{
    if (bbox31.isEmpty())
    {
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        bbox31 = OsmAnd::AreaI(topLeft, bottomRight);
    }
    const auto& obfsDataInterface = OsmAndApp.instance.resourcesManager->obfsCollection->obtainDataInterface(res);
    
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > loadedBinaryMapObjects;
    QList< std::shared_ptr<const OsmAnd::Road> > loadedRoads;
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;
    auto tileSurfaceType = OsmAnd::MapSurfaceType::Undefined;
    
    if (!obfsDataInterface->loadMapObjects(&loadedBinaryMapObjects, &loadedRoads, &tileSurfaceType, nullptr, OsmAnd::ZoomLevel15, &bbox31))
    {
        return segmentList;
    }
    
    for (const auto& binaryMapObject : loadedBinaryMapObjects)
    {
        NSString *ref = @"";
        NSString *routeId = @"";
        NSString *name = @"";
                
        for (const auto& captionAttributeId : OsmAnd::constOf(binaryMapObject->captionsOrder))
        {
            QString tag = binaryMapObject->attributeMapping->decodeMap[captionAttributeId].tag;
            const auto& value = OsmAnd::constOf(binaryMapObject->captions)[captionAttributeId];
            NSString *stringValue = [value.toNSString() lowercaseString];
            
            if (tag == QStringLiteral("ref"))
                ref = stringValue;
            if (tag == QStringLiteral("route_id"))
                routeId = stringValue;
            if (tag == QStringLiteral("name"))
                name = stringValue;
        }
        if ((travelGpx.ref && travelGpx.routeId && [ref isEqualToString:[travelGpx.ref lowercaseString]] && [routeId isEqualToString:[travelGpx.routeId lowercaseString]]) ||
            (travelGpx.routeId && [routeId isEqualToString:[travelGpx.routeId lowercaseString]]) ||
            (travelGpx.ref && [ref isEqualToString:[travelGpx.ref lowercaseString]]) ||
            (travelGpx.title && [name isEqualToString:[travelGpx.title lowercaseString]]))
        {
            if (OATravelGuidesSegmentMatchesRouteType(binaryMapObject, travelGpx))
                segmentList.append(binaryMapObject);
        }
    }
    return segmentList;
}

+ (OATravelGpx *)searchTravelGpx:(CLLocation *)location routeId:(NSString *)routeId
{
    if (NSStringIsEmpty(routeId) || !location || !OATravelGuidesIsFiniteCoordinate(location.coordinate.latitude, location.coordinate.longitude))
        return nil;
    
    OATravelObfHelper *helper = OATravelObfHelper.shared;
    NSArray<NSString *> *readers = [helper getTravelGpxRepositories];
    BOOL userGpxCollectionSearchRequested = !OATravelGuidesIsOsmRouteId(routeId);
    NSString *lowercasedRouteId = [routeId lowercaseString];
    
    NSMutableArray<OAFoundAmenity *> *foundAmenities = [NSMutableArray new];
    NSInteger searchRadius = helper.TRAVEL_GPX_SEARCH_RADIUS;
    OATravelGpx *travelGpx;
    
    while (!travelGpx && searchRadius < helper.MAX_TRAVEL_GPX_SEARCH_RADIUS)
    {
        for (NSString *reader in readers)
        {
            if (OATravelGuidesIsWorldMap(reader))
                continue;
            if (!userGpxCollectionSearchRequested && !OATravelGuidesLocationIntersectsReader(location, reader))
                continue;

            int previousFoundSize = foundAmenities.count;
            BOOL firstSearchCycle = searchRadius == helper.TRAVEL_GPX_SEARCH_RADIUS;
            if (firstSearchCycle)
            {
                [self searchTravelGpxAmenityByRouteId:foundAmenities repo:reader routeId:routeId location:location searchRadius:searchRadius];
                if (foundAmenities.count > previousFoundSize)
                    break;
            }
            
            BOOL nothingFound = previousFoundSize == foundAmenities.count;
            if (nothingFound)
            {
                // fallback to non-indexed route_id (compatibility with old files)
                [self searchAmenity:location.coordinate.latitude lon:location.coordinate.longitude reader:reader radius:searchRadius searchFilters:@[ROUTE_TRACK] publish:^BOOL(OAPOI *poi) {
                    NSString *subType = poi.subType ?: @"";
                    BOOL matchingSubType = [subType hasPrefix:ROUTES_PREFIX] ||
                                           [subType containsString:[@";" stringByAppendingString:ROUTES_PREFIX]] ||
                                           [subType isEqualToString:ROUTE_TRACK];
                    NSString *amenityRouteId = [poi getRouteId];
                    if (matchingSubType && amenityRouteId && [lowercasedRouteId isEqualToString:[amenityRouteId lowercaseString]])
                    {
                        OAFoundAmenity *foundAmenity = [[OAFoundAmenity alloc] initWithFile:reader amenity:poi];
                        [foundAmenities addObject:foundAmenity];
                    }
                    return NO;
                }];
            }
        }
        
        for (OAFoundAmenity *foundAmenity in foundAmenities)
        {
            NSString *aRouteId = [foundAmenity.amenity getRouteId];
            NSString *lcRouteId = aRouteId ? [aRouteId lowercaseString] : nil;
            if ([lowercasedRouteId isEqualToString:lcRouteId])
            {
                travelGpx = [self getTravelGpx:foundAmenity.file amenity:foundAmenity.amenity];
                break;
            }
            
        }
        searchRadius *= 2;
    }
    
    if (!travelGpx)
    {
        NSLog(@"searchTravelGpx(%f %f, %@) failed", location.coordinate.latitude, location.coordinate.longitude, routeId);
    }
 
    return travelGpx;
}

+ (OATravelGpx *)getTravelGpx:(NSString *)file amenity:(OAPOI *)amenity
{
    OATravelGpx *travelGpx = [[OATravelGpx alloc] initWithAmenity:amenity];
    travelGpx.file = file;
    return travelGpx;
}

+ (void)searchTravelGpxAmenityByRouteId:(NSMutableArray<OAFoundAmenity *> *)amenitiesList repo:(NSString *)repo routeId:(NSString *)routeId location:(CLLocation *)location searchRadius:(NSInteger)searchRadius
{
    const auto currentLocationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude));
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(searchRadius, OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude)));
    
    [OAAmenitySearcher findTravelGuides:@[ROUTE_TRACK] currentLocation:currentLocationI bbox31:bbox31 reader:repo publish:^BOOL(OAPOI * _Nonnull poi) {
        NSString *subType = poi.subType ?: @"";
        if ([subType hasPrefix:ROUTES_PREFIX] ||
            [subType containsString:[@";" stringByAppendingString:ROUTES_PREFIX]] ||
            [subType isEqualToString:ROUTE_TRACK])
        {
            NSString *amenityRouteId = [poi getRouteId];
            if (amenityRouteId && [amenityRouteId isEqualToString:routeId])
            {
                OAFoundAmenity *foundAmenity = [[OAFoundAmenity alloc] initWithFile:repo amenity:poi];
                [amenitiesList addObject:foundAmenity];
            }
        }
        return NO;
    }];
}

@end
