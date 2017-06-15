//
//  OAMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

@implementation OAMapLayer

- (instancetype)initWithMapViewController:(OAMapViewController *)mapViewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _mapViewController = mapViewController;
        _mapView = mapViewController.mapView;
    }
    return self;
}

- (void) initLayer
{
}

- (void) deinitLayer
{
}

- (void) resetLayer
{
}

- (BOOL) updateLayer
{
    return NO;
}

- (void) show
{
}

- (void) hide
{
}

- (void) onMapFrameRendered
{
}


@end
