//
//  OARouteColorizationHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 24.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>

#import "OAColorizationType.h"

#include <OsmAndCore/Color.h>

NS_ASSUME_NONNULL_BEGIN

@class OAGPXDocument, OAGPXTrackAnalysis;

@interface OARouteColorizationHelper : NSObject

- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile analysis:(OAGPXTrackAnalysis *)analysis type:(EOAColorizationType)type maxProfileSpeed:(float)maxProfileSpeed;

- (QList<OsmAnd::FColorARGB>) getResult;

@end

NS_ASSUME_NONNULL_END
