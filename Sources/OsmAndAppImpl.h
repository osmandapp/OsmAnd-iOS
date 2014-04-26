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

@interface OsmAndAppImpl : NSObject <OsmAndAppProtocol, OsmAndAppCppProtocol>

@property(readonly) OAAppData* data;

@property(nonatomic, setter = setMapMode:) OAMapMode mapMode;
@property(readonly) OAObservable* mapModeObservable;

@property(nonatomic, readonly) std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;

@end
