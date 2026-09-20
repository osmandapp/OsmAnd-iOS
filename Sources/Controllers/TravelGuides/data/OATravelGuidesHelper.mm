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
#import "OAAppSettings.h"
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

@implementation OATravelGuidesHelper

+ (void) showContextMenuWithLatitude:(double)latitude longitude:(double)longitude
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.contextMenuLayer getUnknownTargetPoint:latitude longitude:longitude];
    targetPoint.centerMap = YES;
    [mapPanel showContextMenu:targetPoint];
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

+ (void)showGpx:(NSString *)path documentAdapter:(OAGPXDocumentAdapter *)documentAdapter
{
    if (path.length == 0 || !documentAdapter.object)
        return;

    [OASelectedGPXHelper.instance addGpxFile:documentAdapter.object for:path];
    [OAAppSettings.sharedManager showGpx:@[[OAUtilities getGpxShortPath:path]] update:NO];
    [OsmAndApp.instance.updateGpxTracksOnMapObservable notifyEvent];
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

@end
