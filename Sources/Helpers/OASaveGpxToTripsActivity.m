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
        OARootViewController *rootVC = [OARootViewController instance];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"trip_name") preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSString *dateString = [formatter stringFromDate:[NSDate date]];
            textField.placeholder = OALocalizedString(@"trip_hint");
            textField.text = [NSString stringWithFormat:@"_%@_", dateString];
        }];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_save") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *finalPath = _pathToTmpGpx;
            NSString *currentName = alert.textFields.firstObject.text;
            if (currentName.length > 0 && ![currentName isEqualToString:[_pathToTmpGpx.lastPathComponent stringByDeletingPathExtension]])
            {
                finalPath = [[_pathToTmpGpx stringByDeletingLastPathComponent] stringByAppendingPathComponent:alert.textFields.firstObject.text];
                [[NSFileManager defaultManager] moveItemAtPath:_pathToTmpGpx toPath:finalPath error:nil];
            }
            [rootVC importAsGPX:[NSURL fileURLWithPath:finalPath] showAlerts:YES openGpxView:NO];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [rootVC presentViewController:alert animated:YES completion:nil];
    }
    
    [self activityDidFinish:YES];
}

@end
