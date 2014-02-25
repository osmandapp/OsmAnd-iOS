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
#import "OALocationServices.h"

@protocol OsmAndAppProtocol <NSObject>

@property(readonly) OALocationServices* locationServices;

@property(nonatomic) OAMapMode mapMode;
@property(readonly) OAObservable* mapModeObservable;

@end
