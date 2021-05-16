//
//  OsmAndAppCppProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAMapViewState.h"

#include <OsmAndCore/QtExtensions.h>
#include <QDir>

#include <OsmAndCore.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/FavoriteLocationsGpxCollection.h>
#include <OsmAndCore/GpxDocument.h>

#include <routingConfiguration.h>

@protocol OsmAndAppCppProtocol <NSObject>
@required

@property(nonatomic, readonly) QDir dataDir;
@property(nonatomic, readonly) QDir documentsDir;

@property(nonatomic, readonly) std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;
@property(nonatomic, readonly) std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;

@property(nonatomic, readonly) std::shared_ptr<RoutingConfigurationBuilder> defaultRoutingConfig;

- (std::shared_ptr<RoutingConfigurationBuilder>) getRoutingConfigForMode:(OAApplicationMode *)mode;

- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am;
- (std::shared_ptr<GeneralRouter>) getRouter:(std::shared_ptr<RoutingConfigurationBuilder> &)builder mode:(OAApplicationMode *)am;
- (std::vector<std::shared_ptr<RoutingConfigurationBuilder>>) getAllRoutingConfigs;

@end
