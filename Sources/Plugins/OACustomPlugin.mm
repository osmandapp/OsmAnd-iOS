//
//  OACustomPlugin.m
//  OsmAnd
//
//  Created by Paul on 15.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACustomPlugin.h"
#import "OAWorldRegion.h"

@implementation OACustomPlugin
{
    NSDictionary<NSString *, NSString *> *_names;
    NSDictionary<NSString *, NSString *> *_descriptions;
    NSDictionary<NSString *, NSString *> *_iconNames;
    NSDictionary<NSString *, NSString *> *_imageNames;
    
    UIImage *_icon;
    UIImage *_image;
    
    NSArray<OASuggestedDownloadItem *> *_suggestedDownloadItems;
    NSArray<OAWorldRegion *> *_customRegions;
}

@end
