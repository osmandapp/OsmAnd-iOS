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

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/BinaryMapObject.h>

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

//In android function with this name works differently. Just moved most part of original code here.
+ (QList<std::shared_ptr<const OsmAnd::BinaryMapObject>>) fetchSegmentsAndPoints:(NSArray<NSString *> *)readers article:(OATravelArticle *)article pointList:(NSMutableArray<OAPOI *> *)pointList gpxFileExtensions:(NSMutableDictionary<NSString *, NSString *> *)gpxFileExtensions
{
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;
    
    for (NSString *reader in readers)
    {
        if (article.file != nil && ![article.file isEqualToString: reader])
        {
            continue;
        }

        if ([article isKindOfClass:OATravelGpx.class])
        {
            OsmAnd::AreaI emptyArea;
            
            if (article.routeRadius >= 0)
            {
                OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(article.lat, article.lon));
                emptyArea = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(article.routeRadius, locI);
            }
            
            segmentList = [self.class searchGpxMapObject:(OATravelGpx *)article bbox31:emptyArea reader:reader];
           
            for (const auto& segment : segmentList)
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
        
        //publish function
        BOOL (^publish)(OAPOI *amenity) = ^BOOL(OAPOI *amenity) {
            if ([amenity.getRouteId isEqualToString:article.routeId])
            {
                if ([[article getPointFilterString] isEqualToString:@"route_track_point"])
                {
                    [pointList addObject:amenity];
                }
                else
                {
                    NSString *amenityLang = [amenity getTagSuffix:@"lang_yes:"];
                    if ([article.lang isEqualToString:amenityLang])
                    {
                        [pointList addObject:amenity];
                    }
                }
            }
            return NO;
        };
        
        OsmAnd::PointI location = OsmAnd::PointI(0, 0);
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
        
        if (article.routeRadius >= 0)
        {
            OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(article.lat, article.lon));
            bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(article.routeRadius, locI);
        }
        
        if (article.title && article.title.length > 0)
        {
            [OAAmenitySearcher.sharedInstance findTravelGuidesByKeyword:article.title categoryNames:@[[article getPointFilterString]] poiTypeName:nil currentLocation:location bbox31:bbox31 reader:reader publish:publish];
        }
        else
        {
            [OAAmenitySearcher findTravelGuides:@[[article getPointFilterString]] currentLocation:location bbox31:bbox31 reader:reader publish:publish];
        }
        
        if (segmentList.size() > 0)
        {
            break;
        }
    }
    
    return segmentList;
}

+ (OAGPXDocumentAdapter *) buildGpxFile:(NSArray<NSString *> *)readers article:(OATravelArticle *)article
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
            for (const auto& point : segment->points31)
            {
                const auto latLon = OsmAnd::Utilities::convert31ToLatLon(point);
                OASWptPt *wptPt = [[OASWptPt alloc] init];
                wptPt.position = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
                [trkSegment.points addObject:wptPt];
            }
            
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
            
            if (!eleGraphValue.isEmpty())
            {
                hasAltitude = YES;
                auto heightRes = [OAMapAlgorithms decodeIntHeightArrayGraph:eleGraphValue repeatBits:3];
                double startEle = startEleValue.toDouble();
                
                trkSegment = [OAMapAlgorithms augmentTrkSegmentWithAltitudes:trkSegment decodedSteps:heightRes startEle:startEle];
            }
            [track.segments addObject:trkSegment];
        }
        
        gpxFile.tracks = [NSMutableArray new];
        [gpxFile.tracks addObject:track];
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
    
    if (NSArrayIsEmpty(pointList))
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

+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >) searchGpxMapObject:(OATravelGpx *)travelGpx bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader useAllObfFiles:(BOOL)useAllObfFiles
{
    OsmAndAppInstance app = OsmAndApp.instance;
    QList< std::shared_ptr<const OsmAnd::ObfFile> > files = app.resourcesManager->obfsCollection->getObfFiles();
    std::shared_ptr<const OsmAnd::ObfFile> res;
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > result;
    
    NSArray<NSString *> *travelObfNames = useAllObfFiles ? [self.class getAllObfList] : [self.class getTravelGuidesObfList];
    
    NSString *filename = travelGpx.file;
        if (!NSStringIsEmpty(filename) || !NSStringIsEmpty(reader))
    {
        for (const auto& file : files)
        {
            NSString *path = [file->filePath.toNSString() lowercaseString];
            if ((filename && [path  hasSuffix:[filename lowercaseString]]) ||
                (reader && [path hasSuffix:[reader lowercaseString]]))
            {
                const auto found = [self.class searchGpxMapObject:travelGpx res:file bbox31:bbox31];
                result.append(found);
            }
        }
    }
    else
    {
        for (const auto& file : files)
        {
            NSString *path = [file->filePath.toNSString() lowercaseString];
            for (NSString *travelObfName in travelObfNames)
            {
                if ([path hasSuffix:travelObfName])
                {
                    const auto found =  [self.class searchGpxMapObject:travelGpx res:file bbox31:bbox31];
                    if (found.size() > 0)
                    {
                        result.append(found);
                        return found;
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
    auto tileSurfaceType = OsmAnd::MapSurfaceType::Undefined;
    
    obfsDataInterface->loadMapObjects(&loadedBinaryMapObjects, &loadedRoads, &tileSurfaceType, nullptr, OsmAnd::ZoomLevel15, &bbox31);
    
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;
    
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
            segmentList.append(binaryMapObject);
        }
    }
    return segmentList;
}

+ (OATravelGpx *)searchTravelGpx:(CLLocation *)location routeId:(NSString *)routeId
{
    if (NSStringIsEmpty(routeId))
        return nil;
    
    OATravelObfHelper *helper = OATravelObfHelper.shared;
    NSArray<NSString *> *readers = [helper getReaders];
    CLLocation *currentLocation = OsmAndApp.instance.locationServices.lastKnownLocation;
    const auto currentLocationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude));
    
    NSMutableArray<OAFoundAmenity *> *foundAmenities = [NSMutableArray new];
    NSInteger searchRadius = helper.TRAVEL_GPX_SEARCH_RADIUS;
    OATravelGpx *travelGpx;
    
    while (!travelGpx && searchRadius < helper.MAX_SEARCH_RADIUS)
    {
        for (NSString *reader in readers)
        {
            int previousFoundSize = foundAmenities.count;
            BOOL firstSearchCycle = searchRadius == helper.TRAVEL_GPX_SEARCH_RADIUS;
            if (firstSearchCycle)
            {
                [self searchTravelGpxAmenityByRouteId:foundAmenities repo:reader routeId:routeId location:location searchRadius:searchRadius currentLocationI:currentLocationI];
            }
            
            BOOL nothingFound = previousFoundSize == foundAmenities.count;
            if (nothingFound)
            {
                // fallback to non-indexed route_id (compatibility with old files)
                [self searchAmenity:location.coordinate.latitude lon:location.coordinate.longitude reader:reader radius:searchRadius searchFilters:@[ROUTE_TRACK] publish:^BOOL(OAPOI *poi) {
                    
                    OAFoundAmenity *foundAmenity = [[OAFoundAmenity alloc] initWithFile:reader amenity:poi];
                    [foundAmenities addObject:foundAmenity];
                    return YES;
                }];
            }
        }
        
        for (OAFoundAmenity *foundAmenity in foundAmenities)
        {
            NSString *aRouteId = [foundAmenity.amenity getRouteId];
            NSString *lcRouteId = aRouteId ? [aRouteId lowercaseString] : nil;
            if ([[routeId lowercaseString] isEqualToString:lcRouteId])
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

+ (void)searchTravelGpxAmenityByRouteId:(NSMutableArray<OAFoundAmenity *> *)amenitiesList repo:(NSString *)repo routeId:(NSString *)routeId location:(CLLocation *)location searchRadius:(NSInteger)searchRadius currentLocationI:(OsmAnd::PointI)currentLocationI
{
    
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(searchRadius, OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude)));
    
    [OAAmenitySearcher findTravelGuides:@[ROUTE_TRACK] currentLocation:currentLocationI bbox31:bbox31 reader:repo publish:^BOOL(OAPOI * _Nonnull poi) {
        
        if ([poi.subType hasPrefix:ROUTES_PREFIX] || [poi.subType isEqualToString:ROUTE_TRACK])
        {
            if ([poi.values[@"route_id"] isEqualToString:routeId])
            {
                OAFoundAmenity *foundAmenity = [[OAFoundAmenity alloc] initWithFile:repo amenity:poi];
                [amenitiesList addObject:foundAmenity];
                return YES;
            }
        }
        return NO;
    }];
}

@end
