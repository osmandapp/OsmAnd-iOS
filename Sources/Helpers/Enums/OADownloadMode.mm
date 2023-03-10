//
//  OADownloadMode.m
//  OsmAnd
//
//  Created by Skalii on 08.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OADownloadMode.h"
#import "Localization.h"
#import "OAColoringType.h"

static OADownloadMode * NONE;
static OADownloadMode * WIFI_ONLY;
static OADownloadMode * ANY_NETWORK;

static NSArray<OADownloadMode *> * DOWNLOAD_MODES = @[OADownloadMode.NONE, OADownloadMode.WIFI_ONLY, OADownloadMode.ANY_NETWORK];

@implementation OADownloadMode

- (instancetype)initWithName:(NSString *)name title:(NSString *)title iconName:(NSString *)iconName
{
    self = [super init];
    if (self)
    {
        _name = name;
        _title = title;
        _iconName = iconName;
    }
    return self;
}

+ (OADownloadMode *) NONE
{
    if (!NONE)
    {
        NONE = [[OADownloadMode alloc] initWithName:@"none" title:OALocalizedString(@"dont_download") iconName:@"ic_navbar_image_disabled_outlined"];
    }
    return NONE;
}

+ (OADownloadMode *) WIFI_ONLY
{
    if (!WIFI_ONLY)
    {
        WIFI_ONLY = [[OADownloadMode alloc] initWithName:@"wifiOnly" title:OALocalizedString(@"over_wifi_only") iconName:@"ic_navbar_image_outlined"];
    }
    return WIFI_ONLY;
}

+ (OADownloadMode *) ANY_NETWORK
{
    if (!ANY_NETWORK)
    {
        ANY_NETWORK = [[OADownloadMode alloc] initWithName:@"anyNetwork" title:OALocalizedString(@"over_any_network") iconName:@"ic_navbar_image_outlined"];
    }
    return ANY_NETWORK;
}

+ (NSArray<OADownloadMode *> *) getDownloadModes
{
    return DOWNLOAD_MODES;
}

- (BOOL)isDontDownload
{
    return self == self.class.NONE;
}

- (BOOL)isDownloadOnlyViaWifi
{
    return self == self.class.WIFI_ONLY;
}

- (BOOL)isDownloadViaAnyNetwork
{
    return self == self.class.ANY_NETWORK;
}

@end
