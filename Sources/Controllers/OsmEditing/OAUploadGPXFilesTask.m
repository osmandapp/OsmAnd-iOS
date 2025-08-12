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
#import "OsmAnd_Maps-Swift.h"

@implementation OAUploadGPXFilesTask
{
    OsmAndAppInstance _app;
    OAOsmEditingPlugin *_plugin;
    id<OAOnUploadFileListener> _listener;
    NSArray<OASTrackItem *> *_gpxItemsToUpload;
    NSOrderedSet<NSString *> *_tags;
    NSString *_defaultActivity;
    NSString *_visibility;
    NSString *_commonDescription;
    BOOL _interruptUploading;
}

- (instancetype) initWithPlugin:(OAOsmEditingPlugin *)plugin gpxItemsToUpload:(NSArray<OASTrackItem *> *)gpxItemsToUpload tags:(NSOrderedSet<NSString *> *)tags defaultActivity:(NSString *)defaultActivity visibility:(NSString *)visibility description:(NSString *)description listener:(id<OAOnUploadFileListener>)listener
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _plugin = plugin;
        _listener = listener;
        _gpxItemsToUpload = gpxItemsToUpload;
        _tags = tags;
        _defaultActivity = defaultActivity;
        _visibility = visibility;
        _commonDescription = description;
    }
    return self;
}

- (void) uploadTracks
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL includeActivity = [self shouldIncludeActivity];
        for (OASTrackItem *track in _gpxItemsToUpload)
        {
            if (_interruptUploading)
                break;
        
            NSString *description = _commonDescription;
            if (!description || [description trim].length == 0)
                description = track.gpxFileNameWithoutExtension;
            
            NSOrderedSet<NSString *> *adjusted = [self adjustedTagsForTrack:track includeActivity:includeActivity];
            NSString *tagsText = [[adjusted array] componentsJoinedByString:@", "];

            OAOpenStreetMapRemoteUtil *editsUtil = (OAOpenStreetMapRemoteUtil *)_plugin.getPoiModificationRemoteUtil;
            [editsUtil uploadGPXFile:tagsText description:description visibility:_visibility gpxDoc:track listener:_listener];
        }
    });
}

- (void) setInterrupted:(BOOL)interrupted
{
    _interruptUploading = interrupted;
}

- (BOOL) shouldIncludeActivity
{
    return _defaultActivity.length > 0 && [_tags containsObject:_defaultActivity];
}

- (NSOrderedSet<NSString *> *) adjustedTagsForTrack:(OASTrackItem *)track includeActivity:(BOOL)include
{
    if (!include)
        return _tags;
    
    NSMutableOrderedSet<NSString *> *updatedTags = [_tags mutableCopy];
    NSString *activity = [self gpxActivityForTrack:track];
    if (activity.length > 0)
    {
        if ([updatedTags containsObject:_defaultActivity])
        {
            NSUInteger idx = [updatedTags indexOfObject:_defaultActivity];
            [updatedTags replaceObjectAtIndex:idx withObject:activity];
        }
    }
    else
    {
        [updatedTags removeObject:_defaultActivity];
    }
    
    return [updatedTags copy];
}

- (nullable NSString *) gpxActivityForTrack:(OASTrackItem *)track
{
    OASGpxDataItem *item = [[OASGpxDbHelper shared] getItemFile:[[OASKFile alloc] initWithFilePath:track.path]];
    return item ? [item getParameterParameter:OASGpxParameter.activityType] : nil;
}

@end

