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

@protocol OsmAndAppCppProtocol <NSObject>

@property(nonatomic, readonly) QDir dataPath;
@property(nonatomic, readonly) QDir documentsPath;
@property(nonatomic, readonly) QDir cachePath;

@property(nonatomic, readonly) std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;
@property(nonatomic, readonly) std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;

@end
