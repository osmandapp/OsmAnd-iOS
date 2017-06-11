//
//  OARasterMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARasterMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

@implementation OARasterMapLayer

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex
{
    self = [super initWithMapViewController:mapViewController];
    if (self)
    {
        _layerIndex = layerIndex;
    }
    return self;
}

- (void) resetLayer
{
}

- (BOOL) updateLayer
{
}

@end
