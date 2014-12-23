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

#define METERS_IN_KILOMETER 1000
#define METERS_IN_ONE_MILE 1609.344f // 1609.344
#define YARDS_IN_ONE_METER 1.0936f
#define FOOTS_IN_ONE_METER  3.2808f


@interface OsmAndAppImpl : NSObject <OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol>

@property(readonly) OAAppData* data;

@property(nonatomic) OAAppMode appMode;
@property(nonatomic) OAMapMode mapMode;

@property(nonatomic, readonly) std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;
@property(nonatomic, readonly) std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;
@property(nonatomic) std::shared_ptr<OsmAnd::GpxDocument> gpxCollection;

@end
