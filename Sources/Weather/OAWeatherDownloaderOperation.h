//
//  OAWeatherDownloaderOperation.h
//  OsmAnd Maps
//
// Created by Skalii on 18.07.2022.
// Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWeatherHelper.h"

#include <OsmAndCore/CommonTypes.h>

@class OAWorldRegion;

@interface OAWeatherDownloaderOperation : NSOperation

- (instancetype)initWithRegion:(OAWorldRegion *)region
                        tileId:(OsmAnd::TileId)tileId
                          date:(NSDate *)date
                          zoom:(OsmAnd::ZoomLevel)zoom
            calculateSizeLocal:(BOOL)calculateSizeLocal
          calculateSizeUpdates:(BOOL)calculateSizeUpdates;

@property (nonatomic, weak) id<OAWeatherDownloaderDelegate> delegate;

@end
