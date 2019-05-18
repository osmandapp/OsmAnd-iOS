//
//  OAMapillaryVectorLayer.m
//  OsmAnd
//
//  Created by Paul on 10/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryVectorLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAMapillaryVectorTilesProvider.h"
#import "OAOnlineOsmNoteWrapper.h"
#import "OAMapillaryVectorTilesProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>

@interface OAMapillaryVectorLayer ()

@end

@implementation OAMapillaryVectorLayer
{
    std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider> _mapillaryProvider;
}

- (NSString *) layerId
{
    return kMapillaryVectorLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                    Visibility:[OAAppSettings sharedManager].mapSettingShowMapillary];
    
    _mapillaryProvider.reset(new OAMapillaryVectorTilesProvider(QStringLiteral("mapillary_vect"),
                                                                QStringLiteral("https://d25uarhxywzl1j.cloudfront.net/v0.1/${osm_zoom}/${osm_x}/${osm_y}.mvt"),
                                                                OsmAnd::ZoomLevel14,
                                                                OsmAnd::ZoomLevel21,
                                                                1,
                                                                256,
                                                                self.mapViewController.displayDensityFactor));
    [self.mapView addTiledSymbolsProvider:_mapillaryProvider];
}


- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addTiledSymbolsProvider:_mapillaryProvider];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeTiledSymbolsProvider:_mapillaryProvider];
    }];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup* objSymbolGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    if (objSymbolGroup != nullptr)
    {
        
    }
}

@end
