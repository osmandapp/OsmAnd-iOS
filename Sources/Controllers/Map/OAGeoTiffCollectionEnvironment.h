//
//  OAGeoTiffCollectionEnvironment.h
//  OsmAnd
//
//  Created by Skalii on 02.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/IGeoTiffCollection.h>

@interface OAGeoTiffCollectionEnvironment : NSObject

@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::IGeoTiffCollection> geoTiffCollection;

- (instancetype)initWithGeoTiffCollection:(const std::shared_ptr<OsmAnd::IGeoTiffCollection>&)geoTiffCollection;

@end
