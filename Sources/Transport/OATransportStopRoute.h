//
//  OATransportStopRoute.h
//  OsmAnd
//
//  Created by Alexey on 11/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATransportStopType.h"
#import "OACommonTypes.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Data/TransportRoute.h>

UIKIT_EXTERN NSArray<NSString *> *const OATransportStopRouteArrowChars;
UIKIT_EXTERN NSString *const OATransportStopRouteArrow;

@interface OATransportStopRoute : NSObject

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::TransportStop> refStop;
@property (nonatomic) OATransportStopType *type;
@property (nonatomic) NSString *desc;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::TransportRoute> route;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::TransportStop> stop;
@property (nonatomic) int distance;
@property (nonatomic) BOOL showWholeRoute;

- (NSString *) getDescription:(BOOL)useDistance;
- (OAGpxBounds) calculateBounds:(int)startPosition;
- (UIColor *) getColor:(BOOL)nightMode;
- (NSString *) getTypeStr;

- (OATransportStopRoute *) clone;

@end
