//
//  OAMapLayersConfiguration.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

#define kFavoritesLayerId @"favorites"

@interface OAMapLayersConfiguration : NSObject <NSCoding>

- (BOOL)isLayerVisible:(NSString*)layerId;
- (void)setLayer:(NSString*)layerId Visibility:(BOOL)isVisible;
- (BOOL)toogleLayerVisibility:(NSString*)layerId;

@property(readonly) OAObservable* changeObservable;

@end
