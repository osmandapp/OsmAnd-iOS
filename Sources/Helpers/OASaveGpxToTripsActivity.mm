//
//  OASaveGpxToTripsActivity.m
//  OsmAnd
//
//  Created by Paul on 30.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASaveGpxToTripsActivity.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OASaveTrackViewController.h"

#define kImportFolderName @"import"
#define kGpxFileExtension @"gpx"

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
    return nil;
}

- (void)performActivity
{
    if (_pathToTmpGpx)
    {
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
        
        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc] initWithFileName:fileName filePath:shortPath tmpPath:_pathToTmpGpx];
        [OARootViewController.instance presentViewController:saveTrackViewController animated:YES completion:nil];
    }
    
    [self activityDidFinish:YES];
}

@end
