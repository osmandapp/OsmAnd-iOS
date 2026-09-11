//
//  OAGPXUIHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXUIHelper.h"
#import "OARouteCalculationResult.h"
#import "OARoutingHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OACity.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAOsmAndFormatter.h"
#import "OASaveTrackViewController.h"
#import "OASelectedGPXHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OASavingTrackHelper.h"
#import "OANetworkRouteDrawable.h"
#import "OARouteKey.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAppVersion.h"
#import "OAResourcesInstaller.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QuadTree.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/Data/ObfAddressSectionInfo.h>
#include <exception>


#define SECOND_IN_MILLIS 1000L

static NSLock *OAGPXNearestCitySearchLock()
{
    static NSLock *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [NSLock new];
    });
    return lock;
}

static NSCache<NSString *, NSArray<OAPOI *> *> *OAGPXNearestCityCandidatesCache()
{
    static NSCache<NSString *, NSArray<OAPOI *> *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.countLimit = 64;


        [[NSNotificationCenter defaultCenter] addObserverForName:OAResourceInstalledNotification
                                                         object:nil
                                                          queue:nil
                                                     usingBlock:^(NSNotification * _Nonnull note) {
            [cache removeAllObjects];
        }];
    });
    return cache;
}

static const double kNearestCityCellDeg = 0.5;
static const int kNearestCityRegionRadiusMeters = 120 * 1000;
static const int kNearestCityQueryRadiusMeters = 50 * 1000;

static NSString *OAGPXNearestCityCellKey(CLLocationCoordinate2D latLon)
{
    return [NSString stringWithFormat:@"%ld_%ld",
            (long) floor(latLon.latitude / kNearestCityCellDeg),
            (long) floor(latLon.longitude / kNearestCityCellDeg)];
}

static CLLocationCoordinate2D OAGPXNearestCityCellCenter(CLLocationCoordinate2D latLon)
{
    return CLLocationCoordinate2DMake(
        (floor(latLon.latitude / kNearestCityCellDeg) + 0.5) * kNearestCityCellDeg,
        (floor(latLon.longitude / kNearestCityCellDeg) + 0.5) * kNearestCityCellDeg);
}

static NSArray<NSString *> *OAGPXNearestCitySubTypes()
{
    static NSArray<NSString *> *types;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = @[
            [OACity getTypeStr:CITY_TYPE_CITY],
            [OACity getTypeStr:CITY_TYPE_TOWN],
            [OACity getTypeStr:CITY_TYPE_VILLAGE],
            [OACity getTypeStr:CITY_TYPE_HAMLET],
            [OACity getTypeStr:CITY_TYPE_SUBURB],
            [OACity getTypeStr:CITY_TYPE_BOUNDARY],
            [OACity getTypeStr:CITY_TYPE_POSTCODE],
            [OACity getTypeStr:CITY_TYPE_BOROUGH],
            [OACity getTypeStr:CITY_TYPE_DISTRICT],
            [OACity getTypeStr:CITY_TYPE_NEIGHBOURHOOD],
            [OACity getTypeStr:CITY_TYPE_CENSUS]
        ];
    });
    return types;
}

@implementation OAGpxFileInfo

- (instancetype) initWithFileName:(NSString *)fileName lastModified:(long)lastModified fileSize:(long)fileSize
{
    self = [super init];
    if (self) {
        _fileName = fileName;
        _lastModified = lastModified;
        _fileSize = fileSize;
    }
    return self;
}

@end


@interface OAGPXUIHelper() <UIDocumentInteractionControllerDelegate, OASaveTrackViewControllerDelegate>

+ (NSArray<OAPOI *> *)findCityCandidatesAroundLat:(double)lat lon:(double)lon radiusMeters:(int)radiusMeters;
+ (NSArray<OAPOI *> *)filterCityCandidates:(NSArray<OAPOI *> *)candidates radiusMeters:(int)radiusMeters ofLat:(double)lat lon:(double)lon;
+ (NSString *)nearestCityNameFromAddressIndex:(CLLocationCoordinate2D)latLon;
+ (NSArray<OAPOI *> *)cityCandidatesForCellAt:(CLLocationCoordinate2D)latLon;

@end

@implementation OAGPXUIHelper
{
    NSString *_exportFileName;
    NSString *_exportFilePath;
    OASGpxDataItem *_exportingGpx;
    OASGpxFile *_exportingGpxFile;
    BOOL _isExportingCurrentTrack;
    UIDocumentInteractionController *_exportController;
    UIViewController __weak *_exportingHostVC;
    id<OATrackSavingHelperUpdatableDelegate> _exportingHostVCDelegate;
}

+ (OASGpxFile *)makeGpxFromRoute:(OARouteCalculationResult *)route
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    
    NSArray<CLLocation *> *locations = [route getRouteLocations];
    OASTrack *track = [[OASTrack alloc] init];
    OASTrkSegment *seg = [[OASTrkSegment alloc] init];
    NSMutableArray<OASWptPt *> *pts = [NSMutableArray new];
    if (locations)
    {
        for (CLLocation *l in locations)
        {
            OASWptPt *point = [[OASWptPt alloc] init];
            point.lat = l.coordinate.latitude;
            point.lon = l.coordinate.longitude;
            if (!isnan(l.altitude) && l.altitude != 0)
            {
                if (gpx)
                    gpx.hasAltitude = YES;
                point.ele = l.altitude;
            }
            if (pts.count == 0)
            {
                point.time = (long) ([[NSDate date] timeIntervalSince1970] * 1000.0);
            }
            else
            {
                OASWptPt *prevPoint = pts[pts.count - 1];
                if (l.speed != 0)
                {
                    point.speed = l.speed;
                    double dist = getDistance(prevPoint.position.latitude,
                            prevPoint.position.longitude,
                            point.position.latitude,
                            point.position.longitude);
                    point.time = prevPoint.time + (long) (dist / point.speed) * SECOND_IN_MILLIS;
                } else {
                    point.time = prevPoint.time;
                }
            }
            [pts addObject:point];
        }
    }
    [OAGPXUIHelper interpolateEmptyElevationWpts:pts];
    seg.points = pts;
    track.segments = [@[seg] mutableCopy];
    gpx.tracks = [@[track] mutableCopy];
    return gpx;
}

+ (void)interpolateEmptyElevationWpts:(NSMutableArray<OASWptPt *> *)pts
{
    for (int i = 0; i < pts.count; )
    {
        int processedPoints = 0;
        OASWptPt *currentPt = pts[i];
        if (isnan(currentPt.ele))
        {
            int startIndex = i, prevValidIndex = -1, nextValidIndex = -1;
            double prevValidElevation = NAN, nextValidElevation = NAN;

            for (int j = startIndex - 1; j >= 0; j--)
            {
                OASWptPt *prevPt = pts[j];
                if (!isnan(prevPt.ele))
                {
                    prevValidElevation = prevPt.ele;
                    prevValidIndex = j;
                    break;
                }
            }

            for (int j = startIndex + 1; j < pts.count; j++)
            {
                OASWptPt *nextPt = pts[j];
                if (!isnan(nextPt.ele))
                {
                    nextValidElevation = nextPt.ele;
                    nextValidIndex = j;
                    break;
                }
            }

            if (prevValidIndex == -1 && nextValidIndex == -1)
            {
                return; // no elevation at all
            }

            if (prevValidIndex == -1 || nextValidIndex == -1)
            {
                // outermost section without interpolation
                for (int j = startIndex; j < pts.count; j++)
                {
                    OASWptPt *pt = pts[j];
                    if (isnan(pt.ele))
                    {
                        pt.ele = startIndex == 0 ? nextValidElevation : prevValidElevation;
                        processedPoints++;
                    } else
                    {
                        break;
                    }
                }
            } else
            {
                // inner section
                double totalDistance = 0;
                NSMutableArray<NSNumber *> *distanceArray = [NSMutableArray arrayWithCapacity:(nextValidIndex - prevValidIndex)];
                for (int j = prevValidIndex; j < nextValidIndex; j++)
                {
                    OASWptPt *thisPt = pts[j];
                    OASWptPt *nextPt = pts[j + 1];
                    double distance = getDistance(thisPt.position.latitude, thisPt.position.longitude,
                                                  nextPt.position.latitude, nextPt.position.longitude);
                    [distanceArray addObject:@(distance)];
                    totalDistance += distance;
                }
                double deltaElevation = pts[nextValidIndex].ele - pts[prevValidIndex].ele;
                for (int j = startIndex; totalDistance > 0 && j < nextValidIndex; j++)
                {
                    double currentDistance = [distanceArray[j - startIndex] doubleValue];
                    double increaseElevation = deltaElevation * (currentDistance / totalDistance);
                    pts[j].ele = pts[j - 1].ele + increaseElevation;
                    processedPoints++;
                }
            }
        }
        i += processedPoints > 0 ? processedPoints : 1;
    }
}

+ (NSString *) getDescription:(OASGpxDataItem *)gpx
{
    NSString *dist = [OAOsmAndFormatter getFormattedDistance:gpx.totalDistance];
    NSString *wpts = [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"shared_string_waypoints"), gpx.wptPoints];
    return [NSString stringWithFormat:@"%@ • %@", dist, wpts];
}

+ (long)getSegmentTime:(OASTrkSegment *)segment
{
    long startTime = LONG_MAX;
    long endTime = LONG_MIN;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OASWptPt *point = segment.points[i];
        long time = point.time;
        if (time != 0) {
            startTime = MIN(startTime, time);
            endTime = MAX(endTime, time);
        }
    }
    return endTime - startTime;
}

+ (double) getSegmentDistance:(OASTrkSegment *)segment
{
    double distance = 0;
    OASWptPt *prevPoint = nil;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OASWptPt *point = segment.points[i];
        if (prevPoint != nil)
            distance += getDistance(prevPoint.getLatitude, prevPoint.getLongitude, point.getLatitude, point.getLongitude);
        prevPoint = point;
    }
    return distance;
}

+ (NSArray<OASGpxDataItem *> *)sortedGPXDataItems
{
    NSMutableArray<OASGpxDataItem *> *list = [[OAGPXDatabase.sharedDb getDataItems] mutableCopy];
    
    [list sortUsingComparator:^NSComparisonResult(OASGpxDataItem *i1, OASGpxDataItem *i2) {
        NSString *name1 = i1.gpxFileName;
        NSString *name2 = i2.gpxFileName;
        NSInteger d1 = [self depth:name1];
        NSInteger d2 = [self depth:name2];
        
        if (d1 < d2)
            return NSOrderedAscending;
        if (d1 > d2)
            return NSOrderedDescending;
        
        NSInteger lastSame = 0;
        for (NSInteger i = 0; i < name1.length && i < name2.length; i++)
        {
            if ([name1 characterAtIndex:i] != [name2 characterAtIndex:i])
                break;
            
            if ([name1 characterAtIndex:i] == '/')
                lastSame = i + 1;
        }
        
        BOOL isDigitStarts1 = [self isLastSameStartsWithDigit:name1 lastSame:lastSame];
        BOOL isDigitStarts2 = [self isLastSameStartsWithDigit:name2 lastSame:lastSame];
        NSComparisonResult res = (NSComparisonResult) (isDigitStarts1 == isDigitStarts2 ? 0 : isDigitStarts1 ? -1 : 1);
        if (res != NSOrderedSame)
            return res;

        if (isDigitStarts1)
            return (NSComparisonResult) -([name1 caseInsensitiveCompare:name2]);
        
        return [name1 caseInsensitiveCompare:name2];
    }];
    
    return list;
}

+ (void) readGpxDirectory:(NSString *)dir
                     list:(NSMutableArray<OAGpxFileInfo *> *)list
                   parent:(NSString *)parent
             absolutePath:(BOOL)absolutePath
{
    if (dir)
    {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:dir error:nil];
        if (files)
        {
            for (NSString *f in files)
            {
                NSString *fullPath = [dir stringByAppendingPathComponent:f];
                if ([f.pathExtension.lowerCase isEqualToString:@"gpx"])
                {
                    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
                    [list addObject:[[OAGpxFileInfo alloc] initWithFileName:absolutePath ? fullPath : [parent stringByAppendingPathComponent:f] lastModified:[attributes fileModificationDate].timeIntervalSince1970 * 1000 fileSize:[attributes fileSize]]];
                }
                BOOL isDir = NO;
                [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
                if (isDir)
                    [self readGpxDirectory:fullPath list:list parent:[parent stringByAppendingPathComponent:f] absolutePath:absolutePath];
            }
        }
    }
}

+ (NSInteger) depth:(NSString *)name
{
    return name.pathComponents.count;
}

+ (BOOL) isLastSameStartsWithDigit:(NSString *)name lastSame:(NSInteger)lastSame
{
    if (name.length > lastSame)
    {
        return isdigit([name characterAtIndex:lastSame]);
    }
    
    return NO;
}

+ (void) addAppearanceToGpx:(OASGpxFile *)gpxFile gpxItem:(OASGpxDataItem *)gpxItem
{
    [gpxFile setShowArrowsShowArrows:gpxItem.showArrows];
    [gpxFile setShowStartFinishShowStartFinish:gpxItem.showStartFinish];
    [gpxFile setJoinSegmentIsJoinSegment:gpxItem.joinSegments];
    if (gpxItem.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone)
    {
        [gpxFile setAdditionalExaggerationAdditionalExaggeration:gpxItem.verticalExaggerationScale];
        [gpxFile setElevationMetersElevation:gpxItem.elevationMeters];
        
        [gpxFile set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationByTypeNameForType:(EOAGPX3DLineVisualizationByType)gpxItem.visualization3dByType]];
        [gpxFile set3DWallColoringTypeTrackWallColoringType:[OAGPXDatabase lineVisualizationWallColorTypeNameForType:(EOAGPX3DLineVisualizationWallColorType)gpxItem.visualization3dWallColorType]];
        [gpxFile set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationPositionTypeNameForType:(EOAGPX3DLineVisualizationPositionType)gpxItem.visualization3dPositionType]];
    }
    
    [gpxFile setSplitIntervalSplitInterval:gpxItem.splitInterval];
    [gpxFile setSplitTypeGpxSplitType:[OAGPXDatabase splitTypeNameByValue:gpxItem.splitType]];
    if (gpxItem.color != 0)
    {
        OASInt *color = [[OASInt alloc] initWithInt:(int)gpxItem.color];
        [gpxFile setColorColor:color];
    }
    
    if (gpxItem.width && gpxItem.width.length > 0)
        [gpxFile setWidthWidth:gpxItem.width];
    
    if (gpxItem.coloringType && gpxItem.coloringType.length > 0)
        [gpxFile setColoringTypeColoringType:gpxItem.coloringType];

    if (gpxItem.gradientPaletteName && gpxItem.gradientPaletteName.length > 0)
        [gpxFile setGradientColorPaletteGradientColorPaletteName:gpxItem.gradientPaletteName];
}

// Settlements are read out of the address section once per map and kept in a quadtree for the
// session, so every later lookup is an in-memory box query.

static const int kNearestCityAddressRadiusMeters = 50 * 1000;

typedef OsmAnd::QuadTree<std::shared_ptr<const OsmAnd::StreetGroup>, OsmAnd::AreaI::CoordType> OAGPXCityQuadTreeType;

static NSLock *OAGPXNearestCityAddressLock()
{
    static NSLock *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [NSLock new];
    });
    return lock;
}

static std::shared_ptr<OAGPXCityQuadTreeType> &OAGPXCityQuadTree()
{
    static std::shared_ptr<OAGPXCityQuadTreeType> tree =
        std::make_shared<OAGPXCityQuadTreeType>(OsmAnd::AreaI::largestPositive(), 12u);
    return tree;
}

static NSMutableSet<NSString *> *OAGPXLoadedCityResourceIds()
{
    static NSMutableSet<NSString *> *loaded;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loaded = [NSMutableSet set];
        [[NSNotificationCenter defaultCenter] addObserverForName:OAResourceInstalledNotification
                                                         object:nil
                                                          queue:nil
                                                     usingBlock:^(NSNotification * _Nonnull note) {
            NSLock *lock = OAGPXNearestCityAddressLock();
            [lock lock];
            [loaded removeAllObjects];
            OAGPXCityQuadTree() = std::make_shared<OAGPXCityQuadTreeType>(OsmAnd::AreaI::largestPositive(), 12u);
            [lock unlock];
        }];
    });
    return loaded;
}

+ (NSString *)searchNearestCityName:(CLLocationCoordinate2D)latLon
{
    NSString *fromAddress = [self nearestCityNameFromAddressIndex:latLon];
    if (fromAddress)
        return fromAddress;

    OAPOI *poi = [self searchNearestCity:latLon];
    return poi.name ?: @"";
}

/// nil = no map here carries address data, caller falls back to POI. @"" = read, nothing in range.
+ (NSString *)nearestCityNameFromAddressIndex:(CLLocationCoordinate2D)latLon
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.latitude, latLon.longitude));
    const OsmAnd::AreaI bbox31 = (OsmAnd::AreaI) OsmAnd::Utilities::boundingBox31FromAreaInMeters(
        kNearestCityAddressRadiusMeters, point31);

    QList<std::shared_ptr<const OsmAnd::StreetGroup>> cities;
    BOOL covered = NO;

    NSLock *lock = OAGPXNearestCityAddressLock();
    [lock lock];
    @try
    {
        try
        {
            NSMutableSet<NSString *> *loaded = OAGPXLoadedCityResourceIds();
            const auto &obfsCollection = app.resourcesManager->obfsCollection;
            for (const auto &resource : app.resourcesManager->getLocalResources())
            {
                // Other resource kinds carry a different Metadata subclass; casting those
                // statically yields a bogus pointer that crashes on dereference.
                if (resource->type != OsmAnd::ResourcesManager::ResourceType::MapRegion
                    && resource->type != OsmAnd::ResourcesManager::ResourceType::RoadMapRegion)
                    continue;

                const auto obfMetadata = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(resource->metadata);
                if (!obfMetadata || !obfMetadata->obfFile || !obfMetadata->obfFile->obfInfo)
                    continue;

                OsmAnd::AreaI queryBbox31 = bbox31;
                // As in OASearchPhrase.getOfflineIndexes: the address flag is not set on every
                // map, so coverage is probed with the POI mask.
                if (!obfMetadata->obfFile->obfInfo->containsDataFor(&queryBbox31,
                                                                   OsmAnd::MinZoomLevel,
                                                                   OsmAnd::MaxZoomLevel,
                                                                   OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI)))
                    continue;

                covered = YES;
                NSString *resourceId = resource->id.toNSString();
                if ([loaded containsObject:resourceId])
                    continue;

                [loaded addObject:resourceId];
                const auto dataInterface = obfsCollection->obtainDataInterface({resource});
                QList<std::shared_ptr<const OsmAnd::StreetGroup>> groups;
                dataInterface->loadStreetGroups(&groups, nullptr,
                    OsmAnd::ObfAddressStreetGroupTypesMask().set(OsmAnd::ObfAddressStreetGroupType::CityOrTown));

                for (const auto &group : groups)
                {
                    // bbox31 is optional on a street group.
                    OsmAnd::AreaI area(group->position31.y, group->position31.x, group->position31.y, group->position31.x);
                    if (group->bbox31.size() >= 4)
                    {
                        // bbox31[left,top,right,bottom] => AreaI(top,left,bottom,right)
                        area = OsmAnd::AreaI(group->bbox31.at(1), group->bbox31.at(0), group->bbox31.at(3), group->bbox31.at(2));
                    }
                    OAGPXCityQuadTree()->insert(group, area);
                }
            }

            if (covered)
            {
                OsmAnd::AreaI queryBbox31 = bbox31;
                OAGPXCityQuadTree()->query(queryBbox31, cities);
            }
        }
        catch (const std::exception &ex)
        {
            NSLog(@"[ERROR] -> OAGPXUIHelper -> nearestCityNameFromAddressIndex failed: %s", ex.what());
        }
        catch (...)
        {
            NSLog(@"[ERROR] -> OAGPXUIHelper -> nearestCityNameFromAddressIndex failed: unknown C++ exception");
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"[ERROR] -> OAGPXUIHelper -> nearestCityNameFromAddressIndex failed: %@ %@", exception.name, exception.reason);
    }
    @finally
    {
        [lock unlock];
    }

    if (!covered)
        return nil;
    if (cities.isEmpty())
        return @"";

    // Distance weighted by the settlement's own radius.
    std::shared_ptr<const OsmAnd::StreetGroup> nearest;
    double nearestWeight = 0;
    for (const auto &city : cities)
    {
        OsmAnd::LatLon cityLatLon = OsmAnd::Utilities::convert31ToLatLon(city->position31);
        CGFloat radius = [OACity getRadius:[OACity getTypeStr:(EOACityType) city->type]];
        if (radius <= 0)
            radius = 1000.;
        double weight = OsmAnd::Utilities::distance(cityLatLon.longitude, cityLatLon.latitude,
                                                    latLon.longitude, latLon.latitude) / radius;
        if (!nearest || weight < nearestWeight)
        {
            nearest = city;
            nearestWeight = weight;
        }
    }
    return nearest ? nearest->nativeName.toNSString() : @"";
}

+ (OAPOI *)searchNearestCity:(CLLocationCoordinate2D)latLon
{
    // Only the OBF lookup needs serialising. Filtering and sorting are pure computation over
    // an immutable array, so they run unlocked.
    NSArray<OAPOI *> *regionCandidates = [self cityCandidatesForCellAt:latLon];
    if (regionCandidates.count == 0)
        return nil;

    NSArray<OAPOI *> *inRange = [self filterCityCandidates:regionCandidates
                                             radiusMeters:kNearestCityQueryRadiusMeters
                                                    ofLat:latLon.latitude
                                                      lon:latLon.longitude];
    if (inRange.count == 0)
        return nil;

    return [self sortAmenities:inRange cityTypes:OAGPXNearestCitySubTypes() latLon:latLon].firstObject;
}

+ (NSArray<OAPOI *> *)cityCandidatesForCellAt:(CLLocationCoordinate2D)latLon
{
    NSCache<NSString *, NSArray<OAPOI *> *> *cache = OAGPXNearestCityCandidatesCache();
    NSString *cellKey = OAGPXNearestCityCellKey(latLon);

    // NSCache is thread-safe, so a warm cell never takes the lock.
    NSArray<OAPOI *> *candidates = [cache objectForKey:cellKey];
    if (candidates)
        return candidates;

    NSLock *lock = OAGPXNearestCitySearchLock();
    [lock lock];
    @try
    {
        // Another thread may have filled the cell while we waited.
        candidates = [cache objectForKey:cellKey];
        if (!candidates)
        {
            try
            {
                CLLocationCoordinate2D cellCenter = OAGPXNearestCityCellCenter(latLon);
                candidates = [self findCityCandidatesAroundLat:cellCenter.latitude
                                                          lon:cellCenter.longitude
                                                 radiusMeters:kNearestCityRegionRadiusMeters];
                // Only on a normal return, so a failed lookup is retried instead of cached.
                [cache setObject:candidates forKey:cellKey];
            }
            catch (const std::exception &ex)
            {
                NSLog(@"[ERROR] -> OAGPXUIHelper -> searchNearestCity failed: %s", ex.what());
            }
            catch (...)
            {
                NSLog(@"[ERROR] -> OAGPXUIHelper -> searchNearestCity failed: unknown C++ exception");
            }
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"[ERROR] -> OAGPXUIHelper -> searchNearestCity failed: %@ %@", exception.name, exception.reason);
    }
    @finally
    {
        [lock unlock];
    }
    return candidates ?: @[];
}

+ (NSArray<OAPOI *> *)findCityCandidatesAroundLat:(double)lat lon:(double)lon radiusMeters:(int)radiusMeters
{
    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto rect = OsmAnd::Utilities::boundingBox31FromAreaInMeters(radiusMeters, pointI);
    const auto top = OsmAnd::Utilities::get31LatitudeY(rect.top());
    const auto left = OsmAnd::Utilities::get31LongitudeX(rect.left());
    const auto bottom = OsmAnd::Utilities::get31LatitudeY(rect.bottom());
    const auto right = OsmAnd::Utilities::get31LongitudeX(rect.right());

    NSArray<NSString *> *cityTypes = OAGPXNearestCitySubTypes();

    // City subtypes live in the "administrative" category; declaring it lets the core skip the
    // rest at the OBF index. Subcategories stay empty so the accept block still decides.
    OASearchPoiTypeFilter *filter = [[OASearchPoiTypeFilter alloc] initWithAcceptFunc:^BOOL(OAPOICategory *type, NSString *subcategory) {
        return [cityTypes containsObject:subcategory];
    } emptyFunction:^BOOL{
        return NO;
    } getTypesFunction:^NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *{
        OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
        OAPOICategory *administrative = [poiHelper getPoiCategoryByName:@"administrative"];
        // getPoiCategoryByName: falls back to "other" rather than nil, which would silently
        // narrow the search to the wrong category.
        if (!administrative || administrative == poiHelper.otherPoiCategory)
            return nil;

        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [NSMapTable strongToStrongObjectsMapTable];
        [types setObject:[NSMutableSet set] forKey:administrative];
        return types;
    }];

    NSArray<OAPOI *> *amenities = [OAAmenitySearcher findPOIsByFilter:filter topLatitude:top leftLongitude:left bottomLatitude:bottom rightLongitude:right matcher:nil];
    return amenities ?: @[];
}

+ (NSArray<OAPOI *> *)filterCityCandidates:(NSArray<OAPOI *> *)candidates radiusMeters:(int)radiusMeters ofLat:(double)lat lon:(double)lon
{
    if (candidates.count == 0)
        return candidates;

    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto rect = OsmAnd::Utilities::boundingBox31FromAreaInMeters(radiusMeters, pointI);
    const double top = OsmAnd::Utilities::get31LatitudeY(rect.top());
    const double left = OsmAnd::Utilities::get31LongitudeX(rect.left());
    const double bottom = OsmAnd::Utilities::get31LatitudeY(rect.bottom());
    const double right = OsmAnd::Utilities::get31LongitudeX(rect.right());

    NSMutableArray<OAPOI *> *result = [NSMutableArray arrayWithCapacity:candidates.count];
    for (OAPOI *poi in candidates)
    {
        if (poi.latitude <= top && poi.latitude >= bottom && poi.longitude >= left && poi.longitude <= right)
            [result addObject:poi];
    }
    return result;
}

+ (NSArray<OAPOI *> *)sortAmenities:(NSArray<OAPOI *> *)amenities cityTypes:(NSArray<NSString *> *)cityTypes latLon:(CLLocationCoordinate2D)latLon
{
    return [amenities sortedArrayUsingComparator:^NSComparisonResult(OAPOI * _Nonnull amenity1, OAPOI * _Nonnull amenity2) {
        CGFloat rad1 = 1000.;
        CGFloat rad2 = 1000.;
        if ([cityTypes containsObject:amenity1.subType])
            rad1 = [OACity getRadius:amenity1.subType];
        if ([cityTypes containsObject:amenity2.subType])
            rad2 = [OACity getRadius:amenity2.subType];
        double distance1 = OsmAnd::Utilities::distance(amenity1.longitude, amenity1.latitude, latLon.longitude, latLon.latitude) / rad1;
        double distance2 = OsmAnd::Utilities::distance(amenity2.longitude, amenity2.latitude, latLon.longitude, latLon.latitude) / rad2;
        if (distance1 == distance2)
            return NSOrderedSame;
        else
            return distance1 < distance2 ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void)openExportForTrack:(OASGpxDataItem *)trackItem
                    gpxDoc:(id)gpxDoc
            isCurrentTrack:(BOOL)isCurrentTrack
          inViewController:(UIViewController *)hostViewController
hostViewControllerDelegate:(id)hostViewControllerDelegate
            touchPointArea:(CGRect)touchPointArea
{
    _isExportingCurrentTrack = isCurrentTrack;
    _exportingHostVC = hostViewController;
    _exportingHostVCDelegate = hostViewControllerDelegate;
    _exportingGpx = trackItem;
    _exportingGpxFile = gpxDoc;
    if (isCurrentTrack)
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];

        NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
        [simpleFormat setDateFormat:@"HH-mm_EEE"];

        _exportFileName = [NSString stringWithFormat:@"%@_%@",
                                                     [fmt stringFromDate:[NSDate date]],
                                                     [simpleFormat stringFromDate:[NSDate date]]];
        _exportFilePath = [NSString stringWithFormat:@"%@/%@.gpx",
                                                     NSTemporaryDirectory(),
                                                     _exportFileName];

        [OASavingTrackHelper.sharedInstance saveCurrentTrack:_exportFilePath];
        _exportingGpxFile = OASavingTrackHelper.sharedInstance.currentTrack;
    }
    else
    {
        _exportFileName = trackItem.gpxFileName;
        _exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:trackItem.gpxFileName];
        if (!_exportingGpxFile || ![_exportingGpxFile isKindOfClass:OASGpxFile.class])
        {
            NSString *absoluteGpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:_exportFileName];
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:absoluteGpxFilepath];
            _exportingGpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
        }
        else
        {
            _exportingGpxFile = gpxDoc;
        }
        
        if ([_exportingGpx hasAppearanceData])
        {
            [OAGPXUIHelper addAppearanceToGpx:_exportingGpxFile gpxItem:_exportingGpx];
            OASKFile *file = [[OASKFile alloc] initWithFilePath:_exportFilePath];
            [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:_exportingGpxFile];
        }
        else
        {
            _exportFilePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:trackItem.gpxFilePath];
        }
    }

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_exportFilePath]];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:touchPointArea inView:_exportingHostVC.view animated:YES];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                 trackItem:(OASTrackItem *)trackItem
{
    NSString *gpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:trackItem.gpxFilePath];

    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFilepath];
    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
    if (gpxFile)
        [self copyGPXToNewFolder:newFolderName
                 renameToNewName:newFileName
              deleteOriginalFile:deleteOriginalFile
                       openTrack:openTrack
                       trackItem:trackItem
                         gpxFile:gpxFile
         updatedTrackItemСallback:nil];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                 trackItem:(OASTrackItem *)trackItem
                   gpxFile:(OASGpxFile *)gpxFile
  updatedTrackItemСallback:(void (^_Nullable)(OASTrackItem *updatedTrackItem))updatedTrackItemСallback;
{
    NSString *oldPath = trackItem.gpxFilePath;
    NSString *sourcePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = trackItem.gpxFileName;
    
    NSString *subfolderPath = OsmAndApp.instance.gpxPath;
    for (NSString *component in [newFolder pathComponents])
    {
        subfolderPath = [subfolderPath stringByAppendingPathComponent:component];
        if (![[NSFileManager defaultManager] fileExistsAtPath:subfolderPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:subfolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }

    if (newFileName)
    {
        newName = newFileName;
        while ([[NSFileManager defaultManager]
                fileExistsAtPath:[newFolderPath stringByAppendingPathComponent:newName]])
        {
            newName = [OAUtilities createNewFileName:newName];
        }
    }

    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [SharedLibSmartFolderHelper.shared onGpxFileDeletedGpxFile:trackItem.getFile];
        NSString *newStoringFullPath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:newStoringPath];
        OASKFile *sourceFile = trackItem.getFile ?: [[OASKFile alloc] initWithFilePath:sourcePath];
        OASKFile *newFile = [[OASKFile alloc] initWithFilePath:newStoringFullPath];
        if ([sourceFile renameToToFile:newFile])
        {
            if (![gpxDatabase renameCurrentFile:sourceFile newFile:newFile])
                [[OASGpxDbHelper shared] renameCurrentFile:sourceFile newFile:newFile];
            OASTrackItem *movedItem = [[OASTrackItem alloc] initWithFile:newFile];
            movedItem.dataItem = [gpxDatabase getGPXItem:newStoringFullPath];
            [SharedLibSmartFolderHelper.shared addTrackItemToSmartFolderItem:movedItem];
            if (updatedTrackItemСallback)
            {
                updatedTrackItemСallback(movedItem);
            }
        }
        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
        [OsmAndApp.instance.updateGpxTracksOnMapObservable notifyEvent];
    }
    else
    {
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&err];
        if (err)
        {
            NSLog(@"copyItemAtPath: %@ toPath: %@ ", sourcePath, destinationPath);
            return;
        }
        
        OASGpxDataItem *gpx = [gpxDatabase getGPXItem:sourcePath];
        if (!gpx)
        {
            gpx = [gpxDatabase addGPXFileToDBIfNeeded:sourcePath];
        }
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

        if ([OAAppSettings.sharedManager isGpxVisible:oldPath])
            [OAAppSettings.sharedManager showGpx:@[newStoringPath]];
    }
    if (openTrack)
    {
        OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[newFolderName stringByAppendingPathComponent:newFileName]];
        if (gpx && _exportingHostVC)
        {
            [_exportingHostVC dismissViewControllerAnimated:YES completion:^{
                [OARootViewController.instance.mapPanel targetHideContextPinMarker];
                auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
                trackItem.dataItem = gpx;
                [OARootViewController.instance.mapPanel openTargetViewWithGPX:trackItem];
            }];
        }
    }
}

- (void)renameTrack:(OASGpxDataItem *)gpx newName:(NSString *)newName hostVC:(UIViewController*)hostVC
{
    NSString *gpxFileFullpath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFileFullpath];
    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
    [self renameTrack:gpx doc:gpxFile newName:newName hostVC:hostVC updatedTrackItemСallback:nil];
}

- (void)renameTrackItem:(OASTrackItem *)trackItem newName:(NSString *)newName hostVC:(UIViewController*)hostVC
{
    OASKFile *file = trackItem.getFile ?: [[OASKFile alloc] initWithFilePath:trackItem.path];
    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
    [self renameTrack:trackItem.dataItem doc:gpxFile newName:newName hostVC:hostVC updatedTrackItemСallback:nil];
}

- (void)renameTrack:(OASGpxDataItem *)gpx
                doc:(OASGpxFile *)doc
            newName:(NSString *)newName
             hostVC:(UIViewController*)hostVC
updatedTrackItemСallback:(void (^_Nullable)(OASTrackItem *updatedTrackItem))updatedTrackItemСallback;
{
    if ([newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0)
    {
        NSString *gpxRoot = OsmAndApp.instance.gpxPath;
        NSString *oldPath = gpx ? [gpxRoot stringByAppendingPathComponent:gpx.gpxFilePath] : doc.path;
        if (oldPath.length == 0)
        {
            [self showAlertWithText:OALocalizedString(@"empty_filename") inViewController:hostVC];
            return;
        }
        OASKFile *sourceFile = gpx ? gpx.file : [[OASKFile alloc] initWithFilePath:oldPath];
        NSString *oldFilePath = [oldPath hasPrefix:[gpxRoot stringByAppendingString:@"/"]]
            ? [oldPath substringFromIndex:gpxRoot.length + 1]
            : oldPath.lastPathComponent;
        NSString *newFileName = [[newName stringByAppendingPathExtension:@"gpx"] decomposedStringWithCanonicalMapping];
        NSString *newFilePath = [[oldFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName]; // 2023-10-22_11-34_Sun 2.gpx
        NSString *newPath = [gpxRoot stringByAppendingPathComponent:newFilePath];
        if (![NSFileManager.defaultManager fileExistsAtPath:newPath])
        {
            if (gpx)
                gpx.gpxFileName = newFileName;

            OASKFile *newFile = [[OASKFile alloc] initWithFilePath:newPath];
            BOOL renameToFileResult = [sourceFile renameToToFile:newFile];
            if (!renameToFileResult)
            {
                NSLog(@"[ERROR] -> OAGPXUIHelper -> renameToFileResult is fail");
                return;
            }

            if (![[OAGPXDatabase sharedDb] renameCurrentFile:sourceFile newFile:newFile])
                [[OASGpxDbHelper shared] renameCurrentFile:sourceFile newFile:newFile];

            OASTrackItem *trackItem = [[OASTrackItem alloc] initWithFile:newFile];
            trackItem.dataItem = [[OAGPXDatabase sharedDb] getGPXItem:newPath];
            [SharedLibSmartFolderHelper.shared onGpxFileDeletedGpxFile:[[OASKFile alloc] initWithFilePath:oldPath]];
            [SharedLibSmartFolderHelper.shared addTrackItemToSmartFolderItem:trackItem];
            if (updatedTrackItemСallback)
            {
                updatedTrackItemСallback(trackItem);
            }

            OASMetadata *metadata;
            if (doc.metadata)
            {
                metadata = doc.metadata;
            }
            else
            {
                metadata = [[OASMetadata alloc] init];
                long time = 0;
                if (doc.getPointsList.count > 0)
                    time = doc.getPointsList[0].time;
                if (doc.tracks.count > 0)
                {
                    OASTrack *track = doc.tracks[0];
                    track.name = newName;
                    if (track.segments.count > 0)
                    {
                        OASTrkSegment *seg = track.segments[0];
                        if (seg.points.count > 0)
                         {
                            OASWptPt *p = seg.points[0];
                            if (time > p.time)
                                time = p.time;
                        }
                    }
                }
                metadata.time = time == 0 ? (long) ([[NSDate date] timeIntervalSince1970] * 1000.0) : time;
            }

            if (doc.author && [doc.author containsString:@"OsmAnd"])
                metadata.name = newName;

            BOOL gpxSaved = [OARootViewController.instance.mapPanel.mapViewController updateMetadata:metadata oldPath:oldPath docPath:newPath];
            doc.path = newPath;
            doc.metadata = metadata;
            if (!gpxSaved)
            {
                OASKFile *file = [[OASKFile alloc] initWithFilePath:newPath];
                OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
                if (!exception) {
                    NSLog(@"writeGpxFileFile result is true");
                } else {
                    NSLog(@"writeGpxFileFile result is false");
                }
            }
            [OASelectedGPXHelper renameVisibleTrack:oldFilePath newPath:newFilePath];
        }
        else
        {
            [self showAlertWithText:OALocalizedString(@"gpx_already_exsists") inViewController:hostVC];
        }
    }
    else
    {
        [self showAlertWithText:OALocalizedString(@"empty_filename") inViewController:hostVC];
    }
}

- (void) onCloseShareMenu
{
    _exportFileName = nil;
    _exportFilePath = nil;
    _exportingGpx = nil;
    _exportingGpxFile = nil;
    _exportingHostVC = nil;
    _exportController = nil;
    if (_exportingHostVCDelegate)
    {
        [_exportingHostVCDelegate onNeedUpdateHostData];
        _exportingHostVCDelegate = nil;
    }
}

- (void)showAlertWithText:(NSString *)text inViewController:(UIViewController *)viewController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:text
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)saveAndOpenGpx:(NSString *)name filepath:(NSString *)filepath gpxFile:(OASGpxFile *)gpxFile selectedPoint:(nullable OASWptPt *)selectedPoint analysis:(nullable OASGpxTrackAnalysis *)analysis routeKey:(nullable OARouteKey *)routeKey
{
    [self.class saveAndOpenGpx:name filepath:filepath gpxFile:gpxFile selectedPoint:selectedPoint analysis:analysis routeKey:routeKey forceAdjustCentering:YES];
}

+ (void)saveAndOpenGpx:(NSString *)name filepath:(NSString *)filepath gpxFile:(OASGpxFile *)gpxFile selectedPoint:(nullable OASWptPt *)selectedPoint analysis:(nullable OASGpxTrackAnalysis *)analysis routeKey:(nullable OARouteKey *)routeKey forceAdjustCentering:(BOOL)forceAdjustCentering
{
    // Force hiding opened context menu. (With deleting Temp gpx folder)
    [OARootViewController.instance.mapPanel hideScrollableHudViewController];
    
    NSString *folderPath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:@"Temp"];
    filepath = [folderPath stringByAppendingPathComponent:filepath];
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager fileExistsAtPath:folderPath])
        [manager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
    gpxFile.path = filepath;
    gpxFile.metadata.name = name;
    
    OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFile.path];
    [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpxFile];
    [OARootViewController.instance.mapPanel.mapViewController showTempGpxTrackFromGpxFile:gpxFile];
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    OASGpxDataItem *gpx = [gpxDb getGPXItem:filepath];
    if (!gpx)
        gpx = [gpxDb addGPXFileToDBIfNeeded:filepath];
    
    OASTrackItem *trackItem = [[OASTrackItem alloc] initWithFile:file];
    trackItem.dataItem = gpx;
    [trackItem resetAppearanceToOriginal];
    OASGpxTrackAnalysis *trackAnalysis = analysis?: [gpx getAnalysis];
    
    OATrackMenuViewControllerState *state = [OATrackMenuViewControllerState withPinLocation:CLLocationCoordinate2DMake(selectedPoint.lat, selectedPoint.lon) openedFromMap:YES];
    state.forceAdjustCentering = forceAdjustCentering;
    
    if (!routeKey)
        routeKey = [OARouteKey fromGpxFile:gpxFile];
    
    if (routeKey)
    {
        OANetworkRouteDrawable *drawable = [[OANetworkRouteDrawable alloc] initWithRouteKey:routeKey];
        state.trackIcon = drawable.getIcon;
    }
    
    // Hide old context menu and open a new one.
    // If old context menu already closed, then "hideAndDeleteAllTempGpx()" will not run.
    
    [OARootViewController.instance.mapPanel openTargetViewWithGPX:trackItem
                              items:nil
                       routeKey:routeKey
                   trackHudMode:EOATrackMenuHudMode
                              state:state
                             analysis:trackAnalysis];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
            didEndSendingToApplication:(NSString *)application
{
    if (_isExportingCurrentTrack && _exportFilePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:_exportFilePath error:nil];
        _exportFilePath = nil;
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    if ([application isEqualToString:@"net.osmand.maps"] && _exportingHostVC)
    {
        [_exportController dismissMenuAnimated:YES];
        _exportFilePath = nil;
        _exportController = nil;

        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:_exportFileName
                        filePath:_exportFilePath
                       showOnMap:YES
                 simplifiedTrack:YES
                       duplicate:NO];

        saveTrackViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:saveTrackViewController];
        [_exportingHostVC presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [self onCloseShareMenu];
}

#pragma mark - OASaveTrackViewControllerDelegate

- (void)onSaveAsNewTrack:(NSString *)fileName
               showOnMap:(BOOL)showOnMap
         simplifiedTrack:(BOOL)simplifiedTrack
               openTrack:(BOOL)openTrack
{
    OASTrackItem *trackItem;
    if (_exportingGpx)
    {
        trackItem = [[OASTrackItem alloc] initWithFile:_exportingGpx.file];
        trackItem.dataItem = _exportingGpx;
    }
    if (trackItem)
    {
        [self copyGPXToNewFolder:fileName.stringByDeletingLastPathComponent
                 renameToNewName:[fileName.lastPathComponent stringByAppendingPathExtension:@"gpx"]
              deleteOriginalFile:NO
                       openTrack:YES
                       trackItem:trackItem
                         gpxFile:_exportingGpxFile
        updatedTrackItemСallback:nil];
    }

    [self onCloseShareMenu];
}

+ (NSString *)buildTrackSegmentName:(OASGpxFile *)gpxFile track:(OASTrack *)track segment:(OASTrkSegment *)segment
{
    NSArray<OASTrkSegment *> *segments = [gpxFile getNonEmptyTrkSegmentsRoutesOnly:NO];
    NSString *trackTitle = [self getTrackTitle:gpxFile track:track];
    NSString *segmentTitle = [self getSegmentTitle:segment segmentIdx:[segments indexOfObject:segment]];

    BOOL oneSegmentPerTrack =
            [gpxFile getNonEmptySegmentsCount] == [gpxFile getNonEmptyTracksCount];
    BOOL oneOriginalTrack = ([gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 2)
            || (![gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 1);

    if (oneSegmentPerTrack)
        return trackTitle;
    else if (oneOriginalTrack)
        return segmentTitle;
    else
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), trackTitle, segmentTitle];
}

+ (NSString *)getSegmentTitle:(OASTrkSegment *)segment segmentIdx:(NSInteger)segmentIdx
{
    NSString *segmentName = !segment.name || segment.name.length == 0
            ? [NSString stringWithFormat:@"%li", segmentIdx + 1]
            : segment.name;
    NSString *segmentString = OALocalizedString(@"gpx_selection_segment_title");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), segmentString, segmentName];
}

+ (NSString *)getTrackTitle:(OASGpxFile *)gpxFile track:(OASTrack *)track
{
    NSString *trackName;
    if (!track.name || track.name.length == 0)
    {
        NSInteger trackIdx = [gpxFile.tracks indexOfObject:track];
        NSInteger visibleTrackIdx = [gpxFile hasGeneralTrack] ? trackIdx : trackIdx + 1;
        trackName = [NSString stringWithFormat:@"%li", visibleTrackIdx];
    }
    else
    {
        trackName = track.name;
    }
    NSString *trackString = OALocalizedString(@"shared_string_gpx_track");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), trackString, trackName];
}

+ (NSString *)getGPXStatisticStringForGpxDataItem:(OASGpxDataItem *)dataItem showLastModifiedTime:(BOOL)showLastModifiedTime
{
    NSDate *lastModifiedTime = showLastModifiedTime ? dataItem.lastModifiedTime : nil;
    return [[self class] getGPXStatisticStringFor:lastModifiedTime
                                    totalDistance:dataItem.totalDistance
                                         timeSpan:dataItem.timeSpan
                                        wptPoints:dataItem.wptPoints];
}

+ (NSString *)getGPXStatisticStringFor:(nullable NSDate *)lastModifiedTime
                         totalDistance:(float)totalDistance
                              timeSpan:(NSInteger)timeSpan
                             wptPoints:(int)wptPoints
{
    NSMutableString *result = [NSMutableString string];
    if (lastModifiedTime) {
        NSString *lastModified = [[[self class] gpxDateFormatter] stringFromDate:lastModifiedTime];
        [result appendFormat:@"%@ | ", lastModified];
        
    }

    NSString *trackDistance = [OAOsmAndFormatter getFormattedDistance:totalDistance];
    if (trackDistance) {
        [result appendFormat:@"%@ • ", trackDistance];
    }
    
    NSString *trackDuration = [OAOsmAndFormatter getFormattedTimeInterval:(NSTimeInterval)(timeSpan / 1000) shortFormat:YES];
    if (trackDuration) {
        [result appendFormat:@"%@ • ", trackDuration];
    }
    
    NSString *waypointsCount = [NSString stringWithFormat:@"%d", wptPoints];
    [result appendString:waypointsCount];
    
    return [result copy];
}

+ (NSDateFormatter *)gpxDateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return dateFormatter;
}

@end
