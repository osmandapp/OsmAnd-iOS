//
//  OASaveGpxRouteAsyncTask.m
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASaveGpxRouteAsyncTask.h"
#import "OARoutePlanningHudViewController.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OAMeasurementToolLayer.h"
#import "OAMapLayers.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMeasurementEditingContext.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAGPXDatabase.h"

@implementation OASaveGpxRouteAsyncTask
{
    OARoutePlanningHudViewController * __weak _hudRef;
    OAMeasurementToolLayer *_measurementLayer;
    OAMeasurementEditingContext *_editingCtx;
//    private ProgressDialog progressDialog;
    
    NSString *_outFile;
    NSString *_backupFile;
    OAGPXDocument *_gpxFile;
    OAGPXDocument *_savedGpxFile;
    BOOL _simplified;
    BOOL _addToTrack;
    BOOL _showOnMap;
}

- (instancetype) initWithHudController:(OARoutePlanningHudViewController * __weak)hudRef outFile:(NSString *)outFile gpxFile:(OAGPXDocument *)gpx simplified:(BOOL)simplified addToTrack:(BOOL)addToTrack showOnMap:(BOOL)showOnMap
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

- (void) execute:(void(^)(OAGPXDocument *, NSString *))onComplete
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
        OAGPXDocument *gpx = [self generateGpxFile:trackName gpx:[[OAGPXMutableDocument alloc] init]];
        success = [gpx saveTo:_outFile];
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
        OAGPXDocument *gpx = [self generateGpxFile:trackName gpx:(OAGPXMutableDocument *)_gpxFile];
        if (gpx.metadata != nil)
        {
            gpx.metadata = [[OAMetadata alloc] init];
            gpx.metadata.extensions = _gpxFile.metadata.extensions;
        }
//        if (!gpx.showCurrentTrack) {
//            res = GPXUtilities.writeGpxFile(outFile, gpx);
//        }
        _savedGpxFile = gpx;
        success = [_savedGpxFile saveTo:_outFile];
//        if (showOnMap) {
//            MeasurementToolFragment.showGpxOnMap(app, gpx, false);
//        }
    }
    if (success)
        [self saveGpxToDatabase];
    return success;
}

- (void) saveGpxToDatabase
{
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    NSString *gpxFilePath = [OAUtilities getGpxShortPath:_outFile];
    OAGPX *oldGpx = [gpxDb getGPXItem:gpxFilePath];
    OAGPX *gpx = [gpxDb buildGpxItem:gpxFilePath title:_savedGpxFile.metadata.name desc:_savedGpxFile.metadata.desc bounds:_savedGpxFile.bounds document:_savedGpxFile];
    if (oldGpx)
    {
        gpx.showArrows = oldGpx.showArrows;
        gpx.showStartFinish = oldGpx.showStartFinish;
        gpx.color = oldGpx.color;
        gpx.coloringType = oldGpx.coloringType;
        gpx.width = oldGpx.width;
        gpx.splitType = oldGpx.splitType;
        gpx.splitInterval = oldGpx.splitInterval;
    }
    [gpxDb replaceGpxItem:gpx];
    [gpxDb save];
}

- (OAGPXDocument *) generateGpxFile:(NSString *)trackName gpx:(OAGPXMutableDocument *)gpx
{
    if (_measurementLayer != nil)
    {
        NSArray<OATrkSegment *> *before = _editingCtx.getBeforeTrkSegmentLine;
        NSArray<OATrkSegment *> *after = _editingCtx.getAfterTrkSegmentLine;
        if (_simplified)
        {
            OATrack *track = [[OATrack alloc] init];
            track.name = trackName;
            [gpx addTrack:track];
            for (OATrkSegment *s in before)
            {
                OATrkSegment *segment = [[OATrkSegment alloc] init];
                segment.points = s.points;
                [gpx addTrackSegment:segment track:track];
            }
            for (OATrkSegment *s in after)
            {
                OATrkSegment *segment = [[OATrkSegment alloc] init];
                segment.points = s.points;
                [gpx addTrackSegment:segment track:track];
            }
        }
        else
        {
            OAGPXMutableDocument *newGpx = [_editingCtx exportGpx:trackName];
            if (newGpx)
            {
                NSArray<OATrack *> *gpxTracks = gpx.tracks;
                NSArray<OAWptPt *> *gpxPoints = gpx.points;
                NSArray<OARoute *> *gpxRoutes = gpx.routes;
                gpx = newGpx;
                NSArray<NSArray<OAWptPt *> *> *routePoints = [_editingCtx getRoutePoints];
                for (NSArray<OAWptPt *> *points in routePoints)
                {
                    [gpx addRoutePoints:points addRoute:YES];
                }
                if (gpxPoints.count > 0)
                    [gpx addWpts:gpxPoints];
        
                if (_addToTrack)
                {
                    [gpx addTracks:gpxTracks];
                    [gpx addRoutes:gpxRoutes];
                }
            }
        }
    }
    return gpx;
}

- (void) onPostExecute:(void(^)(OAGPXDocument *, NSString *))onComplete
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
