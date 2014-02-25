//
//  OsmAndAppCppProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Data/ObfsCollection.h>
#include <OsmAndCore/Map/MapStyles.h>

@protocol OsmAndAppCppProtocol <NSObject>

@property (nonatomic, readonly) std::shared_ptr<OsmAnd::ObfsCollection> obfsCollection;
@property (nonatomic, readonly) std::shared_ptr<OsmAnd::MapStyles> mapStyles;

@end
