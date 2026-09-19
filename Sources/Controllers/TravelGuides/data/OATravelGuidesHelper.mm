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

@implementation OATravelGuidesHelper

+ (void) showContextMenuWithLatitude:(double)latitude longitude:(double)longitude
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.contextMenuLayer getUnknownTargetPoint:latitude longitude:longitude];
    targetPoint.centerMap = YES;
    [mapPanel showContextMenu:targetPoint];
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

@end
