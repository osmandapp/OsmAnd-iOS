//
//  OAHillshadeMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAHillshadeMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAIAPHelper.h"
#import "OAMapStyleSettings.h"
#import "OAAutoObserverProxy.h"

#include "OAHillshadeMapLayerProvider.h"
#include <OsmAndCore/Utilities.h>

#define kHillshadeOpacity 0.45f ///fix

@implementation OAHillshadeMapLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _hillshadeMapProvider;
    OAAutoObserverProxy* _hillshadeChangeObserver;
    OAAutoObserverProxy* _hillshadeAlphaChangeObserver;
}

- (NSString *) layerId
{
    return kHillshadeMapLayerId;
}

- (void) initLayer
{
    _hillshadeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onHillshadeLayerChanged)
                                                          andObserve:self.app.data.hillshadeChangeObservable];
    _hillshadeAlphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onHillshadeLayerAlphaChanged)
                                                               andObserve:self.app.data.hillshadeAlphaChangeObservable];
}

- (void) deinitLayer
{
    if (_hillshadeChangeObserver)
    {
        [_hillshadeChangeObserver detach];
        _hillshadeChangeObserver = nil;
    }
    if (_hillshadeAlphaChangeObserver)
    {
        [_hillshadeAlphaChangeObserver detach];
        _hillshadeAlphaChangeObserver = nil;
    }
}

- (void) resetLayer
{
    _hillshadeMapProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    if (self.app.data.hillshade && [[OAIAPHelper sharedInstance].srtm isActive])
    {
        _hillshadeMapProvider = std::make_shared<OAHillshadeMapLayerProvider>();
        [self.mapView setProvider:_hillshadeMapProvider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(self.app.data.hillshadeAlpha);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        return YES;
    }
    return NO;
}

- (void) onHillshadeLayerChanged
{
    [self updateHillshadeLayer];
}

- (void) updateHillshadeLayer
{
    [self.mapViewController runWithRenderSync:^{
        if (![self updateLayer])
        {
            [self.mapView resetProviderFor:self.layerIndex];
            _hillshadeMapProvider.reset();
        }
    }];
}

- (void) onHillshadeLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(self.app.data.hillshadeAlpha);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
}

@end
