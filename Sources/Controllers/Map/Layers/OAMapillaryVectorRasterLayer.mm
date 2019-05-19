//
//  OAMapillaryVectorRasterLayer.m
//  OsmAnd
//
//  Created by Alexey on 19/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryVectorRasterLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAIAPHelper.h"
#import "OAMapStyleSettings.h"
#import "OAAutoObserverProxy.h"

#include "OAMapillaryVectorRasterTilesProvider.h"
#include <OsmAndCore/Utilities.h>

#define kMapillaryOpacity 1.0f

@implementation OAMapillaryVectorRasterLayer
{
    std::shared_ptr<OAMapillaryVectorRasterTilesProvider> _mapillaryMapProvider;
}

- (NSString *) layerId
{
    return kMapillaryVectorLayerId;
}

- (void) initLayer
{
}

- (void) deinitLayer
{
}

- (void) resetLayer
{
    _mapillaryMapProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    if ([OAAppSettings sharedManager].mapSettingShowMapillary)
    {
        _mapillaryMapProvider = std::make_shared<OAMapillaryVectorRasterTilesProvider>(self.mapView.displayDensityFactor);
        _mapillaryMapProvider->setLocalCachePath(QString::fromNSString(self.app.cachePath));
        [self.mapView setProvider:_mapillaryMapProvider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(kMapillaryOpacity);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        return YES;
    }
    return NO;
}

- (void) didReceiveMemoryWarning
{
    if (_mapillaryMapProvider)
        _mapillaryMapProvider->clearCache();
}

@end
