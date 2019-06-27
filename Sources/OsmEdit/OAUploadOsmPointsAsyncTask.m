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
#import "OAUploadFinishedBottomSheetViewController.h"
#import "OAOsmEditingPlugin.h"
#import "OAUploadProgressBottomSheetViewController.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOsmBugResult.h"

@interface OAUploadOsmPointsAsyncTask() <OAUploadBottomSheetDelegate>

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
    OAUploadProgressBottomSheetViewController *_progressBottomSheet;
    
    OsmAndAppInstance _app;
    
}

- (id) initWithPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray<OAOsmPoint *> *)points closeChangeset:(BOOL)closeChangeset anonymous:(BOOL)anonymous comment:(NSString *)comment bottomSheetDelegate:(id<OAOsmEditingBottomSheetDelegate>)bottomSheetDelegate
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
    }
    return self;
}

- (void) uploadPoints
{
    _progressBottomSheet = [[OAUploadProgressBottomSheetViewController alloc] initWithParam:self];
    [_progressBottomSheet show];
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
                OAOpenStreetMapRemoteUtil *editsUtil = (OAOpenStreetMapRemoteUtil *)_plugin.getOnlineModificationUtil;
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
                OAOsmBugsRemoteUtil *util = (OAOsmBugsRemoteUtil *) [_plugin getRemoteOsmNotesUtil];
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
                [_progressBottomSheet setProgress:((float)(i + 1) / (float)_points.count)];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_bottomSheetDelegate respondsToSelector:@selector(dismissEditingScreen)])
                [_bottomSheetDelegate dismissEditingScreen];
            if ([_bottomSheetDelegate respondsToSelector:@selector(uploadFinished:)])
                [_bottomSheetDelegate uploadFinished:failedUploads.count > 0];
            if (!_interruptUploading)
            {
                OAUploadFinishedBottomSheetViewController *uploadFinished = [[OAUploadFinishedBottomSheetViewController alloc] initWithFailedPoints:failedUploads successfulUploads:_points.count - failedUploads.count];
                uploadFinished.delegate = self;
                [uploadFinished show];
            }
            [_progressBottomSheet dismiss];
        });
    });
}

- (void) setInterrupted:(BOOL)interrupted
{
    _interruptUploading = interrupted;
}

#pragma mark - OAUploadBottomSheetDelegate

- (void)retryUpload
{
    [self uploadPoints];
}

@end
