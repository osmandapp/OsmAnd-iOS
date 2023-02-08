//
//  OAUploadGPXFilesTask.m
//  OsmAnd Maps
//
//  Created by nnngrach on 06.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAUploadGPXFilesTask.h"
#import "OAOsmEditingPlugin.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OsmAndApp.h"

@implementation OAUploadGPXFilesTask
{
    OsmAndAppInstance _app;
    OAOsmEditingPlugin *_plugin;
    id<OAOnUploadFileListener> _listener;
    NSArray<OAGPX *> *_uploadingGpxItems;
    NSString *_tags;
    NSString *_visibility;
    NSString *_commonDescription;
    BOOL _interruptUploading;
}

- (id) initWithPlugin:(OAOsmEditingPlugin *)plugin uploadingGpxItems:(NSArray<OAGPX *> *)uploadingGpxItems tags:(NSString *)tags visibility:(NSString *)visibility description:(NSString *)description listener:(id<OAOnUploadFileListener>)listener
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _plugin = plugin;
        _listener = listener;
        _uploadingGpxItems = uploadingGpxItems;
        _tags = tags;
        _visibility = visibility;
        _commonDescription = description;
    }
    return self;
}

- (void) uploadTracks
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i = 0; i < _uploadingGpxItems.count; i++)
        {
            if (_interruptUploading)
                break;
            
            OAGPX *track = _uploadingGpxItems[i];
            NSString *description = _commonDescription;
            if (!description || [description trim].length == 0)
                description = [track.gpxFileName stringByDeletingPathExtension];

            OAOpenStreetMapRemoteUtil *editsUtil = (OAOpenStreetMapRemoteUtil *)_plugin.getPoiModificationRemoteUtil;
            [editsUtil uploadGPXFile:_tags description:description visibility:_visibility gpxDoc:track listener:_listener];
        }
    });
}

- (void) setInterrupted:(BOOL)interrupted
{
    _interruptUploading = interrupted;
}

@end

