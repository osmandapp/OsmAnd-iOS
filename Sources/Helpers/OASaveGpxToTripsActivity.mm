//
//  OASaveGpxToTripsActivity.m
//  OsmAnd
//
//  Created by Paul on 30.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASaveGpxToTripsActivity.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OASaveTrackViewController.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OAAppSettings.h"

#define kImportFolderName @"import"
#define kGpxFileExtension @"gpx"

@interface OASaveGpxToTripsActivity () <OASaveTrackViewControllerDelegate>

@end

@implementation OASaveGpxToTripsActivity
{
    NSString *_pathToTmpGpx;
}

- (NSString *)activityType
{
    return @"net.osmand.maps.saveTrip";
}

- (NSString *)activityTitle
{
    return OALocalizedString(@"displayed_route_save");
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"ic_share_folder_trips"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    for (id item in activityItems)
    {
        if ([item isKindOfClass:NSURL.class])
        {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id item in activityItems)
    {
        if ([item isKindOfClass:NSURL.class])
        {
            NSURL *url = (NSURL *) item;
            _pathToTmpGpx = url.path;
        }
    }
}

- (UIViewController *)activityViewController
{
    if (!_pathToTmpGpx)
        return nil;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSString *name = [NSString stringWithFormat:@"_%@_", dateString];
    NSString *fileName = [NSString stringWithString:name];
    
    NSString *folderName = @"";
    if ([NSFileManager.defaultManager fileExistsAtPath:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:kImportFolderName]])
        folderName = kImportFolderName;
    NSString *shortPath = [folderName stringByAppendingPathComponent:fileName];
    NSString *fullFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:folderName];
    
    NSInteger index = 1;
    while ([NSFileManager.defaultManager fileExistsAtPath:[[fullFolderPath stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:kGpxFileExtension]]) {
        fileName = [NSString stringWithFormat:@"%@(%ld)", name, index];
        index++;
    }
    
    OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc] initWithFileName:fileName filePath:shortPath showOnMap:YES simplifiedTrack:NO duplicate:NO];
    saveTrackViewController.delegate = self;
    return saveTrackViewController;
}

- (void)onSaveAsNewTrack:(NSString *)fileName showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack openTrack:(BOOL)openTrack
{
    if (_pathToTmpGpx) {
        OsmAndAppInstance app = OsmAndApp.instance;
        NSString *shortPath = [fileName stringByAppendingPathExtension:kGpxFileExtension];
        NSString *trackName = [fileName lastPathComponent];
        NSString *gpxPath = [app.gpxPath stringByAppendingPathComponent:shortPath];
        
        BOOL success = [NSFileManager.defaultManager moveItemAtPath:_pathToTmpGpx toPath:gpxPath error:nil];
        
        if (success)
        {
            OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
            OAGPXDocument *gpxDoc = [[OAGPXDocument alloc] initWithGpxFile:gpxPath];
            [gpxDatabase addGpxItem:shortPath
                              title:trackName
                               desc:gpxDoc.metadata.desc
                             bounds:gpxDoc.bounds
                           document:gpxDoc];
            [gpxDatabase save];
            
            if (showOnMap)
                [OAAppSettings.sharedManager showGpx:@[shortPath]];
        }
    }
    
    [self activityDidFinish:YES];
}

- (void)onSaveTrackCancelled
{
    if (_pathToTmpGpx)
        [NSFileManager.defaultManager removeItemAtPath:_pathToTmpGpx error:nil];
    [self activityDidFinish:YES];
}

@end
