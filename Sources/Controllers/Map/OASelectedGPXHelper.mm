//
//  OASelectedGPXHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 24/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASelectedGPXHelper.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

@interface OAGpxLoader : NSObject

@property (nonatomic) QString path;
@property (nonatomic) std::shared_ptr<const OsmAnd::GeoInfoDocument> document;

@end

@implementation OAGpxLoader

@end


@implementation OASelectedGPXHelper
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
}

+ (OASelectedGPXHelper *)instance
{
    static dispatch_once_t once;
    static OASelectedGPXHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (BOOL) buildGpxList
{
    BOOL loading = NO;
    [_settings hideRemovedGpx];

    for (NSString *fileName in _settings.mapSettingVisibleGpx)
    {
        NSString __block *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
        QString qPath = QString::fromNSString(path);
        if ([[NSFileManager defaultManager] fileExistsAtPath:path] && !_activeGpx.contains(qPath))
        {
            OAGpxLoader __block *loader = [[OAGpxLoader alloc] init];
            loader.path = qPath;
    
            _activeGpx[qPath] = nullptr;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                loader.document = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path));
                dispatch_async(dispatch_get_main_queue(), ^{
                    _activeGpx[loader.path] = loader.document;
                    [[_app updateGpxTracksOnMapObservable] notifyEvent];
                });
            });
            loading = YES;
        }
    }
    for (auto it = _activeGpx.begin(); it != _activeGpx.end(); )
    {
        if (![_settings.mapSettingVisibleGpx containsObject:[it.key().toNSString() lastPathComponent]])
            it = _activeGpx.erase(it);
        else
            ++it;
    }
    return loading;
}

@end
