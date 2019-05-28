//
//  OAMapillaryImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryImageCard.h"
#import "OAMapPanelViewController.h"
#import "OATargetPoint.h"
#import "OAMapillaryImage.h"
#import "OAMapLayers.h"

@implementation OAMapillaryImageCard

- (void) onCardPressed:(OAMapPanelViewController *) mapPanel
{
    OAMapillaryImage *img = [[OAMapillaryImage alloc] initWithDictionary:@{@"lat" : @(self.latitude),
                                                                           @"lon" : @(self.longitude),
                                                                           @"key" : self.key,
                                                                           @"ca" : @(self.ca)
                                                                           }];
    OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.mapillaryLayer getTargetPoint:img];
    newTarget.centerMap = YES;
    [mapPanel hideContextMenu];
    [mapPanel showContextMenu:newTarget];
}

@end
