//
//  OsmAndApp.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/22/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Data/ObfsCollection.h>
#include <OsmAndCore/Map/MapStyles.h>

@interface OsmAndApp : NSObject

+ (OsmAndApp*)instance;

@property (nonatomic, readonly) std::shared_ptr<OsmAnd::ObfsCollection> obfsCollection;
@property (nonatomic, readonly) std::shared_ptr<OsmAnd::MapStyles> mapStyles;

@end
