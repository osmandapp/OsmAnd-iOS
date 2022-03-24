//
//  OAMapRendererEnvironment.mm
//  OsmAnd Maps
//
//  Created by Alexey on 16.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAMapRendererEnvironment.h"

@implementation OAMapRendererEnvironment

- (instancetype) initWithObjects:(const std::shared_ptr<OsmAnd::ObfMapObjectsProvider>&) obfMapObjectsProvider
      mapPresentationEnvironment:(const std::shared_ptr<OsmAnd::MapPresentationEnvironment>&)mapPresentationEnvironment
                 mapPrimitiviser:(const std::shared_ptr<OsmAnd::MapPrimitiviser>&)mapPrimitiviser
           mapPrimitivesProvider:(const std::shared_ptr<OsmAnd::MapPrimitivesProvider>&)mapPrimitivesProvider
       mapObjectsSymbolsProvider:(const std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider>&)mapObjectsSymbolsProvider
               obfsDataInterface:(const std::shared_ptr<OsmAnd::ObfDataInterface>&)obfsDataInterface
{
    self = [super init];
    if (self) {
        _obfMapObjectsProvider = obfMapObjectsProvider;
        _mapPresentationEnvironment = mapPresentationEnvironment;
        _mapPrimitiviser = mapPrimitiviser;
        _mapPrimitivesProvider = mapPrimitivesProvider;
        _mapObjectsSymbolsProvider = mapObjectsSymbolsProvider;
        _obfsDataInterface = obfsDataInterface;
    }
    return self;
}

@end
