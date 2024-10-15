//
//  OASaveGpxRouteAsyncTask.m
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASaveGpxRouteAsyncTask.h"
#import "OARoutePlanningHudViewController.h"
#import "OAMeasurementToolLayer.h"
#import "OAMapLayers.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMeasurementEditingContext.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAGPXDatabase.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAppVersion.h"

@implementation OASaveGpxRouteAsyncTask
{
    OARoutePlanningHudViewController * __weak _hudRef;
    OAMeasurementToolLayer *_measurementLayer;
    OAMeasurementEditingContext *_editingCtx;
//    private ProgressDialog progressDialog;
    
    NSString *_outFile;
    NSString *_backupFile;
    OASGpxFile *_gpxFile;
    OASGpxFile *_savedGpxFile;
    BOOL _simplified;
    BOOL _addToTrack;
    BOOL _showOnMap;
}

- (instancetype) initWithHudController:(OARoutePlanningHudViewController * __weak)hudRef
                               outFile:(NSString *)outFile
                               gpxFile:(OASGpxFile *)gpx
                            simplified:(BOOL)simplified
                            addToTrack:(BOOL)addToTrack
                             showOnMap:(BOOL)showOnMap
{
    self = [super init];
    if (self) {
        _hudRef = hudRef;
        _outFile = outFile;
        _gpxFile = gpx;
        _simplified = simplified;
        _addToTrack = addToTrack;
        _showOnMap = showOnMap;
        _measurementLayer = OARootViewController.instance.mapPanel.mapViewController.mapLayers.routePlanningLayer;
        _editingCtx = _measurementLayer.editingCtx;
    }
    return self;
}

- (void)execute:(void(^)(OASGpxFile *, NSString *))onComplete
{
    [self onPreExecute];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:onComplete];
        });
    });
}

- (void) onPreExecute
{
    if (_hudRef)
        [_hudRef cancelModes];
}

- (BOOL) doInBackground
{
    if (_hudRef == nil)
        return NO;
    BOOL success = YES;
    if (_gpxFile == nil)
    {
        NSString *fileName = _outFile.lastPathComponent;
        NSString *trackName = [fileName stringByDeletingPathExtension];
        
        OASGpxFile *gpx = [self generateGpxFile:trackName gpx:[[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]]];
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_outFile];
        OASKException *exception = [[OASGpxUtilities shared] writeGpxFileFile:file gpxFile:gpx];
        
        success = !exception;
        gpx.path = _outFile;
        _savedGpxFile = gpx;
        //            if (showOnMap) {
        //                MeasurementToolFragment.showGpxOnMap(app, gpx, true);
        //            }
    }
    else
    {
//        backupFile = FileUtils.backupFile(app, outFile);
        NSString *trackName = [_outFile.lastPathComponent stringByDeletingPathExtension];
        OASGpxFile *gpx = [self generateGpxFile:trackName gpx:(OASGpxFile *)_gpxFile];
        if (gpx.metadata != nil)
        {
            gpx.metadata = [[OASMetadata alloc] init];
            gpx.metadata.extensions = _gpxFile.metadata.extensions;
        }
//        if (!gpx.showCurrentTrack) {
//            res = GPXUtilities.writeGpxFile(outFile, gpx);
//        }
        _savedGpxFile = gpx;
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_outFile];
        OASKException *exception = [[OASGpxUtilities shared] writeGpxFileFile:file gpxFile:_savedGpxFile];
        success = !exception;
//        if (showOnMap) {
//            MeasurementToolFragment.showGpxOnMap(app, gpx, false);
//        }
    }
    if (success)
        [self saveGpxToDatabase];
    return success;
}

- (void)saveGpxToDatabase
{
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    NSString *gpxFilePath = [OAUtilities getGpxShortPath:_outFile];
    OASGpxDataItem *oldGpx = [gpxDb getNewGPXItem:_outFile];
    
    OASGpxDataItem *gpx = [gpxDb getNewGPXItem:gpxFilePath];
    if (!gpx)
    {
        gpx = [gpxDb addGPXFileToDBIfNeeded:gpxFilePath];
        OASGpxTrackAnalysis *analysis = [gpx getAnalysis];
        
        NSString *nearestCity;
        if (analysis.locationStart)
        {
            OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
            gpx.nearestCity = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
        }
    }

    if (oldGpx)
    {
        gpx.showArrows = oldGpx.showArrows;
        gpx.showStartFinish = oldGpx.showStartFinish;
        gpx.verticalExaggerationScale = oldGpx.verticalExaggerationScale;
        gpx.elevationMeters = oldGpx.elevationMeters;
        gpx.visualization3dByType = oldGpx.visualization3dByType;
        gpx.visualization3dWallColorType = oldGpx.visualization3dWallColorType;
        gpx.visualization3dPositionType = oldGpx.visualization3dPositionType;
        gpx.color = oldGpx.color;
        gpx.coloringType = oldGpx.coloringType;
        gpx.width = oldGpx.width;
        gpx.splitType = oldGpx.splitType;
        gpx.splitInterval = oldGpx.splitInterval;
        gpx.creationDate = oldGpx.creationDate;
    }
    [gpxDb updateDataItem:gpx];
}

- (OASGpxFile *) generateGpxFile:(NSString *)trackName gpx:(OASGpxFile *)gpx
{
    if (_measurementLayer != nil)
    {
        NSArray<OASTrkSegment *> *before = _editingCtx.getBeforeTrkSegmentLine;
        NSArray<OASTrkSegment *> *after = _editingCtx.getAfterTrkSegmentLine;
        if (_simplified)
        {
            OASTrack *track = [[OASTrack alloc] init];
            track.name = trackName;
            [gpx.tracks addObject:track];

            for (OASTrkSegment *s in before)
            {
                OASTrkSegment *segment = [[OASTrkSegment alloc] init];
                segment.points = s.points;
                [track.segments addObject:segment];
                //[gpx addTrackSegment:segment track:track];
            }
            for (OASTrkSegment *s in after)
            {
                OASTrkSegment *segment = [[OASTrkSegment alloc] init];
                segment.points = s.points;
                [track.segments addObject:segment];
               // [gpx addTrackSegment:segment track:track];
            }
        }
        else
        {
            OASGpxFile *newGpx = [_editingCtx exportGpx:trackName];
            if (newGpx)
            {
                NSArray<OASTrack *> *gpxTracks = gpx.tracks;
                NSArray<OASWptPt *> *gpxPoints = gpx.getPointsList;
                NSArray<OASRoute *> *gpxRoutes = gpx.routes;
                gpx = newGpx;
                NSArray<NSArray<OASWptPt *> *> *routePoints = [_editingCtx getRoutePoints];
                for (NSArray<OASWptPt *> *points in routePoints)
                {
                    [gpx addRoutePointsPoints:points addRoute:YES];
                }
                if (gpxPoints.count > 0) {
                    for (OASWptPt *point in gpxPoints) {
                        [gpx addPointPoint:point];
                    }
                }
                    
                if (_addToTrack)
                {
                    [gpx.tracks addObjectsFromArray:gpxTracks];
                    [gpx.routes addObjectsFromArray:gpxRoutes];
                }
            }
        }
    }
    return gpx;
}

- (void) onPostExecute:(void(^)(OASGpxFile *, NSString *))onComplete
{
//    if (!success)
//    {
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"gpx_export_failed") preferredStyle:UIAlertControllerStyleAlert];
//        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
//        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
//    }
    if (onComplete)
        onComplete(_savedGpxFile, _outFile);
}


@end
