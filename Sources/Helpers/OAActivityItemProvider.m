//
//  OAActivityItemProvider.m
//  OsmAnd
//
//  Created by Feschenko Fedor on 8/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAActivityItemProvider.h"
#include "Localization.h"

// Max length is 140 characters (for twitter)
#define SHARE_TEXT @"I'm here"
// Not specified yet - added to show the sample
#define AT_GOOGLE_PLUS @"com.captech.googlePlusSharing"

@implementation OAActivityItemProvider
{
    NSString *_shareString;
}

- (instancetype)initWithShareString:(NSString *)shareString
{
    self = [super init];
    if (self){
        _shareString = shareString;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self){
        _shareString = OALocalizedString(SHARE_TEXT);
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return OALocalizedString(SHARE_TEXT);
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    //TODO: Customize specific messages for different apps
    if ([activityType isEqualToString:UIActivityTypePostToFacebook])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypePostToTwitter])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypePostToWeibo])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeMessage])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeMail])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypePrint])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeAssignToContact])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeSaveToCameraRoll])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeAddToReadingList])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypePostToFlickr])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypePostToVimeo])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypePostToTencentWeibo])
        return _shareString;
    if ([activityType isEqualToString:UIActivityTypeAirDrop])
        return _shareString;
    if ([activityType isEqualToString:AT_GOOGLE_PLUS])
        return _shareString;
    
    return _shareString;
}

@end
