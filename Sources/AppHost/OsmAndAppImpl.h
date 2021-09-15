//
//  OsmAndAppImpl.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OsmAndAppProtocol.h"
#import "OsmAndAppCppProtocol.h"
#import "OsmAndAppPrivateProtocol.h"
#import "OAAppSettings.h"
#import "OsmAndCore/GpxDocument.h"

@interface OsmAndAppImpl : NSObject <OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol>

@property(readonly) OAAppData* data;

@property(nonatomic) OAMapMode mapMode;
@property(nonatomic) OAMapMode prevMapMode;

@property(nonatomic, readonly) std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;
@property(nonatomic, readonly) std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;

@end
