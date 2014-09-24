//
//  OAShareLocation.m
//  OsmAnd
//
//  Created by Feschenko Fedor on 8/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAShareLocation.h"
#import "OAActivityItemProvider.h"

//TODO: Modify the following define - add default OsmAnd logo image for sharing (for now using default app's image)
#define SHARE_IMAGE @"Default.png"
#define SHARE_URL @"http://osmand.net"

@implementation OAShareLocation

+ (void)shareLocation
{
    [self shareLocationWithActivityItems:nil andExcludedActivityTypes:nil];
}

+ (void)shareLocationWithMessage:(NSString *)shareText
{
    [self shareLocationWithMessage:shareText andExcludedActivityTypes:nil];
}

+ (void)shareLocationWithActivityItems:(NSArray *)activityItems
{
    [self shareLocationWithActivityItems:activityItems andExcludedActivityTypes:nil];
}

+ (void)shareLocationWithExcludedActivityTypes:(NSArray *)excludedActivityTypes
{
    [self shareLocationWithActivityItems:nil andExcludedActivityTypes:excludedActivityTypes];
}

+ (void)shareLocationWithMessage:(NSString *)shareText andExcludedActivityTypes:(NSArray *)excludedActivityTypes
{
    NSArray *activityItems = nil;
    if (shareText) {
        OAActivityItemProvider *provider = [[OAActivityItemProvider alloc] initWithShareString:shareText];
        activityItems = [NSArray  arrayWithObjects:provider, [UIImage imageNamed:SHARE_IMAGE], [NSURL URLWithString:SHARE_URL], nil];
    }
    
    [self shareLocationWithActivityItems:activityItems andExcludedActivityTypes:excludedActivityTypes];
}

+ (void)shareLocationWithActivityItems:(NSArray *)activityItems andExcludedActivityTypes:(NSArray *)excludedActivityTypes
{
    if (!activityItems) {
        OAActivityItemProvider *provider = [[OAActivityItemProvider alloc] init];
        activityItems = [NSArray  arrayWithObjects:provider, [UIImage imageNamed:SHARE_IMAGE], [NSURL URLWithString:SHARE_URL], nil];
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController completionHandler];
    
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    if (excludedActivityTypes)
        activityViewController.excludedActivityTypes = excludedActivityTypes;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:activityViewController animated:YES completion:nil];
}

@end

