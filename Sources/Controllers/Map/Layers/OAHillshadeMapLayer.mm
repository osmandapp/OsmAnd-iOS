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

#define kHillshadeOpacity 0.7f

@implementation OAHillshadeMapLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _hillshadeMapProvider;
    OAAutoObserverProxy* _hillshadeChangeObserver;
}

+ (NSString *) getLayerId
{
    return kHillshadeMapLayerId;
}

- (void) initLayer
{
    _hillshadeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onHillshadeLayerChanged)
                                                          andObserve:self.app.data.hillshadeChangeObservable];
}

- (void) deinitLayer
{
    if (_hillshadeChangeObserver)
    {
        [_hillshadeChangeObserver detach];
        _hillshadeChangeObserver = nil;
    }
}

- (void) resetLayer
{
    _hillshadeMapProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    if (self.app.data.hillshade && [[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_Srtm])
    {
        _hillshadeMapProvider = std::make_shared<OAHillshadeMapLayerProvider>();
        [self.mapView setProvider:_hillshadeMapProvider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(kHillshadeOpacity);
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

@end
