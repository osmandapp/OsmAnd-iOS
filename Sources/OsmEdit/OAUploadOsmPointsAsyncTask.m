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
#import "OAObservable.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOsmBugResult.h"
#import "OARootViewController.h"

@implementation OAUploadOsmPointsAsyncTask
{
    OAOsmEditingPlugin *_plugin;
    OsmAndAppInstance _app;
    
    NSArray<OAOsmPoint *> *_points;
    
    NSString *_comment;
    
    BOOL _interruptUploading;
    BOOL _closeChangeSet;
    BOOL _loadAnonymous;
}

- (id) initWithPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray<OAOsmPoint *> *)points closeChangeset:(BOOL)closeChangeset anonymous:(BOOL)anonymous comment:(NSString *)comment
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _plugin = plugin;
        _closeChangeSet = closeChangeset;
        _loadAnonymous = anonymous;
        _points = points;
        _comment = comment;
    }
    return self;
}

- (void) uploadPoints
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
                if ([self.delegate respondsToSelector:@selector(uploadDidProgress:)])
                {
                    float progress = (float)(i + 1) / (float)_points.count;
                    [self.delegate uploadDidProgress:progress];
                }
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(uploadDidCompleteWithSuccess:)])
            {
                [self.delegate uploadDidCompleteWithSuccess:failedUploads.count == 0];
            }
            if (!_interruptUploading)
            {
                if ([self.delegate respondsToSelector:@selector(uploadDidFinishWithFailedPoints:successfulUploads:)])
                    [self.delegate uploadDidFinishWithFailedPoints:failedUploads successfulUploads:_points.count - failedUploads.count];
            }
        });
    });
}

- (void) setInterrupted:(BOOL)interrupted
{
    _interruptUploading = interrupted;
}

- (void)retryUpload
{
    [self uploadPoints];
}

@end
