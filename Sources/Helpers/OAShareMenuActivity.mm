//
//  OAShareMenuActivity.mm
//  OsmAnd
//
//  Created by Skalii on 11.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShareMenuActivity.h"
#import "Localization.h"

@implementation OAShareMenuActivity
{
    OAShareMenuActivityType _type;
}

- (instancetype)initWithType:(OAShareMenuActivityType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
    }
    return self;
}

- (NSString *)activityType
{
    switch (_type)
    {
        case OAShareMenuActivityClipboard:
            return @"net.osmand.maps.clipboard";
        case OAShareMenuActivityCopyAddress:
            return @"net.osmand.maps.copyAddress";
        case OAShareMenuActivityCopyPOIName:
            return @"net.osmand.maps.copyPOIName";
        case OAShareMenuActivityCopyCoordinates:
            return @"net.osmand.maps.copyCoordinates";
        case OAShareMenuActivityGeo:
            return @"net.osmand.maps.geo";
    }
    return nil;
}

- (NSString *)activityTitle
{
    switch (_type)
    {
        case OAShareMenuActivityClipboard:
            return OALocalizedString(@"shared_string_copy");
        case OAShareMenuActivityCopyAddress:
            return OALocalizedString(@"copy_address");
        case OAShareMenuActivityCopyPOIName:
            return OALocalizedString(@"copy_poi_name");
        case OAShareMenuActivityCopyCoordinates:
            return OALocalizedString(@"copy_coordinates");
        case OAShareMenuActivityGeo:
            return OALocalizedString(@"share_geo");
    }
    return nil;
}

- (UIImage *)activityImage
{
    switch (_type)
    {
        case OAShareMenuActivityCopyAddress:
            return [UIImage imageNamed:@"ic_share_address"];
        case OAShareMenuActivityCopyCoordinates:
        case OAShareMenuActivityGeo:
            return [UIImage imageNamed:@"ic_share_coordinates"];
        case OAShareMenuActivityClipboard:
        case OAShareMenuActivityCopyPOIName:
            return [UIImage imageNamed:@"ic_share_copy"];
    }
    return nil;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

- (void)performActivity
{
    if (self.delegate)
        [self.delegate onCopy:_type];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self activityDidFinish:YES];
    });
}

@end
