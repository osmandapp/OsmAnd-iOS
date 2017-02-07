//
//  OADiscountHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADiscountHelper.h"
#import <Reachability.h>
#import "OAAppSettings.h"
#import "OADiscountToolbarViewController.h"
#import "OARootViewController.h"
#import "OAUtilities.h"

const static NSString *URL = @"http://osmand.net/api/motd";

@interface OADiscountHelper () <OADiscountToolbarViewControllerProtocol>

@end

@implementation OADiscountHelper
{
    NSTimeInterval _lastCheckTime;
    NSString *_title;
    NSString *_description;
    NSString *_icon;
    NSString *_url;
    BOOL _bannerVisible;
    
    OADiscountToolbarViewController *_discountToolbar;
}

+ (OADiscountHelper *)instance
{
    static dispatch_once_t once;
    static OADiscountHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void) checkAndDisplay
{
    if (_bannerVisible)
        [self showDiscountBanner:_title description:_description icon:_icon url:_url];
    
    //dispatch_async(dispatch_get_main_queue(), ^{ [self showDiscountBanner:_title description:_description icon:_icon url:_url]; });

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - _lastCheckTime < 60 * 60 * 24 || [Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
    {
        return;
    }
    _lastCheckTime = currentTime;
    
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    int execCount = (int)[settings integerForKey:kAppExecCounter];
    double appInstalledTime = [settings doubleForKey:kAppInstalledDate];
    int appInstalledDays = (int)((currentTime - appInstalledTime) / (24 * 60 * 60));
    
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?version=ios_%@&nd=%d&ns=%d", URL, ver, appInstalledDays, execCount]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (response)
        {
            @try
            {
                [self processDiscountResponse:data];
            }
            @catch (NSException *e)
            {
                // ignore
            }
        }
    }];
    
    [downloadTask resume];
}

- (void) processDiscountResponse:(NSData *)data
{
    NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    if (map)
    {
        int execCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kAppExecCounter];

        NSString *message = [map objectForKey:@"message"];
        NSString *description = [map objectForKey:@"description"];
        NSString *icon = [map objectForKey:@"icon"];
        NSString *url = [map objectForKey:@"url"];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"dd-MM-yyyy HH:mm"];

        //[map setObject:@"25-01-2017 13:00" forKey:@"start"];
        //[map setObject:@"01-03-2017 23:59" forKey:@"end"];
        
        NSDate *start = [df dateFromString:[map objectForKey:@"start"]];
        NSDate *end = [df dateFromString:[map objectForKey:@"end"]];
        int showStartFrequency = [[map objectForKey:@"show_start_frequency"] intValue];
        double showDayFrequency = [[map objectForKey:@"show_day_frequency"] doubleValue];
        int maxTotalShow = [[map objectForKey:@"max_total_show"] intValue];

        NSDate *date = [NSDate date];
        if ([date timeIntervalSinceDate:start] > 0 && [date timeIntervalSinceDate:end] < 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                OAAppSettings *settings = [OAAppSettings sharedManager];
                int discountId = [self getDiscountId:message description:description start:start end:end];
                BOOL discountChanged = settings.discountId != discountId;
                if (discountChanged)
                    settings.discountTotalShow = 0;
                
                if (discountChanged
                    || execCount - settings.discountShowNumberOfStarts >= showStartFrequency
                    || [date timeIntervalSince1970] - settings.discountShowDatetime > 60 * 60 * 24 * showDayFrequency)
                {
                    if (settings.discountTotalShow < maxTotalShow)
                    {
                        settings.discountId = discountId;
                        settings.discountTotalShow = settings.discountTotalShow + 1;
                        settings.discountShowNumberOfStarts = execCount;
                        settings.discountShowDatetime = [date timeIntervalSince1970];
                        [self showDiscountBanner:message description:description icon:icon url:url];
                    }
                }
            });
        }
    }
}

- (int) getDiscountId:(NSString *)message description:(NSString *)description start:(NSDate *)start end:(NSDate *)end
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + (!message ? 0 : [message hash]);
    result = prime * result + (!start ? 0 : [start hash]);
    return (int)result;
}

- (void) showDiscountBanner:(NSString *)title description:(NSString *)description icon:(NSString *)icon url:(NSString *)url
{
    if (!_discountToolbar)
    {
        _discountToolbar = [[OADiscountToolbarViewController alloc] initWithNibName:@"OADiscountToolbarViewController" bundle:nil];
        _discountToolbar.discountDelegate = self;
    }
    [_discountToolbar setTitle:title description:description icon:[OAUtilities getTintableImageNamed:icon]];
    
    _title = title;
    _description = description;
    _icon = icon;
    _url = url;
    _bannerVisible = YES;
    
    [[OARootViewController instance].mapPanel showToolbar:_discountToolbar];
}

- (void) openUrl:(NSString *)url
{
    if (url.length > 0)
        [OAUtilities callUrl:url];
}

#pragma mark - OADiscountToolbarViewControllerProtocol

-(void)discountToolbarPress
{
    _bannerVisible = NO;
    [self openUrl:_url];
    [[OARootViewController instance].mapPanel hideToolbar:_discountToolbar];
}

-(void)discountToolbarClose
{
    _bannerVisible = NO;
    [[OARootViewController instance].mapPanel hideToolbar:_discountToolbar];
}


@end
