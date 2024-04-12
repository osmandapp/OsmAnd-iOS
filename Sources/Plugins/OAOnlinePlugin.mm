//
//  OAOnlinePlugin.m
//  OsmAnd Maps
//
//  Created by Alexey K on 31.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAOnlinePlugin.h"
#import "OANetworkUtilities.h"
#import "OAURLSessionProgress.h"
#import "OAPluginsHelper.h"
#import "OASettingsHelper.h"
#import <MBProgressHUD.h>
#import "OASettingsItem.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAOnlinePlugin()

@property (nonatomic) NSDictionary<NSString *, NSString *> *names;
@property (nonatomic) NSDictionary<NSString *, NSString *> *descriptions;
@property (nonatomic) NSDictionary<NSString *, NSString *> *iconNames;
@property (nonatomic) NSDictionary<NSString *, NSString *> *imageNames;

@end

@implementation OAOnlinePlugin
{
    MBProgressHUD *_progressHUD;
}

@synthesize names, descriptions, iconNames, imageNames;

- (instancetype) initWithJson:(NSDictionary *)json
{
    self = [super initWithJson:json];
    if (self)
    {
        _publishedDate = json[@"publishedDate"];
        _osfUrl = json[@"osfUrl"];
        [self fetchData:json force:NO];
        [self loadResources];
    }
    return self;
}

- (NSString *) getPluginDir
{
    return [[OsmAndApp.instance.cachePath stringByAppendingPathComponent:PLUGINS_DIR] stringByAppendingPathComponent:self.getId];
}

- (void) readAdditionalDataFromJson:(NSDictionary *)json
{
    NSMutableDictionary<NSString *, NSString *> *names = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *descriptions = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *iconNames = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *imageNames = [NSMutableDictionary dictionary];

    NSString *iconPath = json[@"iconPath"];
    NSString *imagePath = json[@"imagePath"];
    if (iconPath.length > 0)
        iconNames[@""] = iconPath;

    if (imagePath.length > 0)
        imageNames[@""] = imagePath;

    NSString *name = json[@"name"];
    NSString *description = json[@"description"];
    if (name.length > 0)
        names[@""] = name;

    if (description.length > 0)
        descriptions[@""] = description;

    self.names = names;
    self.descriptions = descriptions;
    self.iconNames = iconNames;
    self.imageNames = imageNames;
}

- (void) fetchData:(NSDictionary *)json force:(BOOL)force
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pluginDir = [self getPluginDir];

    NSString *iconUrl = json[@"iconUrl"];
    NSString *iconPath = json[@"iconPath"];
    if ([iconPath hasPrefix:@"@"])
        iconPath = [iconPath substringFromIndex:1];

    NSString *iconFile = [pluginDir stringByAppendingPathComponent:iconPath];
    if ((force || ![fileManager fileExistsAtPath:iconFile]) && iconUrl.length > 0) 
        [OANetworkUtilities downloadFile:iconFile url:[OSMAND_URL stringByAppendingString:iconUrl] progress:nil];

    NSString *imageUrl = json[@"imageUrl"];
    NSString *imagePath = json[@"imagePath"];
    if ([imagePath hasPrefix:@"@"])
        imagePath = [imagePath substringFromIndex:1];

    NSString *imageFile = [pluginDir stringByAppendingPathComponent:imagePath];
    if ((force || ![fileManager fileExistsAtPath:imageFile]) && imageUrl.length > 0)
        [OANetworkUtilities downloadFile:imageFile url:[OSMAND_URL stringByAppendingString:imageUrl] progress:nil];
}

- (void) install:(id<OAPluginInstallListener> _Nullable)callback
{
    if (_osfUrl.length == 0) 
    {
        NSLog(@"Cannot install online plugin. OSF url is empty for %@", self.getId);
        return;
    }

    NSURL *url = [NSURL URLWithString:[OSMAND_URL stringByAppendingString:_osfUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgress];
        });
		if (!error && location)
        {
            NSString *osfFile = [self.getPluginDir stringByAppendingPathComponent:_osfUrl.lastPathComponent];
            [[NSFileManager defaultManager] removeItemAtPath:osfFile error:nil];
            NSError *copyError = nil;
            [[NSFileManager defaultManager] copyItemAtURL:location toURL:[NSURL fileURLWithPath:osfFile isDirectory:NO] error:&copyError];
            if (!copyError)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback)
                        [callback onPluginInstall];

                    OASettingsHelper *helper = OASettingsHelper.sharedInstance;
                    [helper collectSettings:osfFile latestChanges:@"" version:1 silent:YES];
                });
            }
        }
    }];

    [self showProgress];
    [downloadTask resume];
}

- (void) showProgress
{
    if (_progressHUD)
        return;

    UIView *topView = [UIApplication sharedApplication].mainWindow;
    _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
    _progressHUD.minShowTime = .5f;
    _progressHUD.removeFromSuperViewOnHide = YES;
    [topView addSubview:_progressHUD];
    [_progressHUD show:YES];
}

- (void) hideProgress
{
    if (_progressHUD && _progressHUD.superview)
        [_progressHUD hide:YES];
}

@end
