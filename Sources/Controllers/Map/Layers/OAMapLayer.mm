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

+ (NSString *) getLayerId
{
    return nil;
}

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

- (NSString *) layerId
{
    return [self.class getLayerId];
}

- (void) initLayer
{
}

- (void) deinitLayer
{
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
