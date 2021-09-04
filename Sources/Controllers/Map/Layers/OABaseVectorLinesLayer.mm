//
//  OABaseVectorLinesLayer.m
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseVectorLinesLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAUtilities.h"
#import "OAAutoObserverProxy.h"
#import "OAVectorLinesSymbolsProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>

#define kMaxZoom 11


@implementation OABaseVectorLinesLayer
{
    OAAutoObserverProxy* _mapZoomObserver;
}

- (NSString *) layerId
{
    return nil; //override
}

- (void) initLayer
{
    [super initLayer];
    
    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:self.mapViewController.zoomObservable];
    _symbolsProvider.reset(new OAVectorLinesSymbolsProvider());
}

- (void)resetLayer
{
    // override
}

- (BOOL)updateLayer
{
    return YES; //override
}


- (BOOL) isVisible
{
    return YES; //override
}

- (void) setVectorLineProvider:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection
{
    _symbolsProvider->vectorLineCollection = collection;
    [self refreshSymbolsProvider];
}

- (void) resetSymbols
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeTiledSymbolsProvider:_symbolsProvider];
        _symbolsProvider.reset(new OAVectorLinesSymbolsProvider());
    }];
}

- (void)refreshSymbolsProvider
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeTiledSymbolsProvider:_symbolsProvider];
        _symbolsProvider->generateMapSymbolsByLine();
        [self.mapView addTiledSymbolsProvider:_symbolsProvider];
    }];
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    [self refreshSymbolsProvider];
}

@end
