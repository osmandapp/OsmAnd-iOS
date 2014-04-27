//
//  OsmAndAppProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "CommonTypes.h"
#import "OAObservable.h"
#import "OAAppData.h"
#import "OALocationServices.h"
#import "OAWorldRegion.h"

@protocol OsmAndAppProtocol <NSObject>

@property(readonly) OAAppData* data;
@property(readonly) OAWorldRegion* worldRegion;

@property(readonly) OALocationServices* locationServices;

@property(nonatomic) OAMapMode mapMode;
@property(readonly) OAObservable* mapModeObservable;

- (void)saveState;

@end
