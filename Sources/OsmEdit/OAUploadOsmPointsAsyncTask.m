//
//  OAUploadOsmPointsAsyncTask.m
//  OsmAnd
//
//  Created by Paul on 6/26/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//
//  OsmAnd/src/net/osmand/plus/osmedit/UploadOpenstreetmapPointAsyncTask.java
//  git revision c288c75a48a7ddd1d2a9431ec803ed1013452e90

#import "OAUploadOsmPointsAsyncTask.h"
#import "OsmAndApp.h"
#import "OAOsmEditingPlugin.h"
#import "OAProgressUploadOsmPOINoteViewController.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOsmBugResult.h"
#import "OARootViewController.h"

@interface OAUploadOsmPointsAsyncTask() <OAUploadProgressDelegate>

@end

@implementation OAUploadOsmPointsAsyncTask
{
    BOOL _interruptUploading;
    OAOsmEditingPlugin *_plugin;
    BOOL _closeChangeSet;
    BOOL _loadAnonymous;
    NSString *_comment;
    
    id<OAOsmEditingBottomSheetDelegate> _bottomSheetDelegate;
    NSArray<OAOsmPoint *> *_points;
    OAProgressUploadOsmPOINoteViewController *_progressUpload;
    UIViewController *_controller;
    
    OsmAndAppInstance _app;
    
}

- (id) initWithPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray<OAOsmPoint *> *)points closeChangeset:(BOOL)closeChangeset anonymous:(BOOL)anonymous comment:(NSString *)comment bottomSheetDelegate:(id<OAOsmEditingBottomSheetDelegate>)bottomSheetDelegate controller:(UIViewController *)controller
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _plugin = plugin;
        _closeChangeSet = closeChangeset;
        _loadAnonymous = anonymous;
        _points = points;
        _comment = comment;
        _bottomSheetDelegate = bottomSheetDelegate;
        _controller = controller;
    }
    return self;
}

- (void) uploadPoints
{
    _progressUpload = [[OAProgressUploadOsmPOINoteViewController alloc] initWithParam:self];
    _progressUpload.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_progressUpload];
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    [OARootViewController.instance.navigationController presentViewController:navigationController animated:YES completion:nil];
    [self startUploadingPoints];
}

- (void) startUploadingPoints
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger lastIndex = _points.count - 1;
        NSMutableArray<OAOsmPoint *> *failedUploads = [NSMutableArray new];
        for (NSInteger i = 0; i < _points.count; i++)
        {
            if (_interruptUploading)
                break;
            
            OAOsmPoint *osmPoint = _points[i];
            if (osmPoint.getGroup == POI)
            {
                OAOpenStreetMapRemoteUtil *editsUtil = (OAOpenStreetMapRemoteUtil *)_plugin.getPoiModificationRemoteUtil;
                OAEntityInfo *entityInfo = nil;
                OAOpenStreetMapPoint *point  = (OAOpenStreetMapPoint *) osmPoint;
                if (point.getAction != CREATE)
                    entityInfo = [editsUtil loadEntityFromEntity:point.getEntity];
                
                OAEntity *entity = [editsUtil commitEntityImpl:point.getAction entity:point.getEntity entityInfo:entityInfo comment:_comment closeChangeSet:(i == lastIndex && _closeChangeSet) changedTags:nil];
                
                if (entity)
                {
                    [[OAOsmEditsDBHelper sharedDatabase] deletePOI:point];
                    [_app.osmEditsChangeObservable notifyEvent];
                }
                else
                    [failedUploads addObject:osmPoint];
            }
            else if (osmPoint.getGroup == BUG)
            {
                OAOsmBugsRemoteUtil *util = (OAOsmBugsRemoteUtil *) [_plugin getOsmNotesRemoteUtil];
                OAOsmNotePoint *p = (OAOsmNotePoint *) osmPoint;
                NSString *message = [util commit:p text:p.getText action:p.getAction anonymous:_loadAnonymous].warning;
                
                if (!message)
                {
                    [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:p];
                    [_app.osmEditsChangeObservable notifyEvent];
                }
                else
                    [failedUploads addObject:p];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [_progressUpload setProgress:((float)(i + 1) / (float)_points.count)];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_bottomSheetDelegate respondsToSelector:@selector(dismissEditingScreen)])
                [_bottomSheetDelegate dismissEditingScreen];
            if ([_bottomSheetDelegate respondsToSelector:@selector(uploadFinished:)])
                [_bottomSheetDelegate uploadFinished:failedUploads.count > 0];
            if (!_interruptUploading)
            {
                [_progressUpload setUploadResultWithFailedPoints:failedUploads successfulUploads:_points.count - failedUploads.count];
            }
        });
    });
}

- (void) setInterrupted:(BOOL)interrupted
{
    _interruptUploading = interrupted;
}

#pragma mark - OAUploadProgressDelegate

- (void)retryUpload
{
    [self startUploadingPoints];
}

- (void)didFinishUploading
{
    [_controller.navigationController popViewControllerAnimated:YES];
}

@end
