//
//  OAMapillaryImageCardWrapper.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapillaryImageCardWrapper.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"

#import "OAMapLayers.h"
#import "OAMapillaryImage.h"

@implementation OAMapillaryImageCardWrapper

+ (void)onCardPressed:(OAMapPanelViewController *)mapPanel
             latitude:(CGFloat)latitude
            longitude:(CGFloat)longitude
                   ca:(CGFloat)ca
                  key:(NSString *)key
{
    OAMapillaryImage *img = [[OAMapillaryImage alloc] initWithDictionary:@{@"lat" : @(latitude),
                                                                           @"lon" : @(longitude),
                                                                           @"key" : key,
                                                                           @"ca" : @(ca)
                                                                           }];
    OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.mapillaryLayer getTargetPoint:img];
    newTarget.centerMap = YES;
    [mapPanel hideContextMenu];
    [mapPanel showContextMenu:newTarget];
}

@end
