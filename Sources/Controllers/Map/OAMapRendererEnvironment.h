//
//  OAMapRendererEnvironment.h
//  OsmAnd Maps
//
//  Created by Alexey on 16.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Map/ObfMapObjectsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapRendererEnvironment : NSObject

@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::ObfMapObjectsProvider> obfMapObjectsProvider;
@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::MapPresentationEnvironment> mapPresentationEnvironment;
@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::MapPrimitiviser> mapPrimitiviser;
@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::MapPrimitivesProvider> mapPrimitivesProvider;
@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> mapObjectsSymbolsProvider;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::ObfDataInterface> obfsDataInterface;

- (instancetype) initWithObjects:(const std::shared_ptr<OsmAnd::ObfMapObjectsProvider>&) obfMapObjectsProvider
      mapPresentationEnvironment:(const std::shared_ptr<OsmAnd::MapPresentationEnvironment>&)mapPresentationEnvironment
                 mapPrimitiviser:(const std::shared_ptr<OsmAnd::MapPrimitiviser>&)mapPrimitiviser
           mapPrimitivesProvider:(const std::shared_ptr<OsmAnd::MapPrimitivesProvider>&)mapPrimitivesProvider
       mapObjectsSymbolsProvider:(const std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider>&)mapObjectsSymbolsProvider
               obfsDataInterface:(const std::shared_ptr<OsmAnd::ObfDataInterface>&)obfsDataInterface;

@end

NS_ASSUME_NONNULL_END
