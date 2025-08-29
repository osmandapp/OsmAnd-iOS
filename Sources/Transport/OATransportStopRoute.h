//
//  OATransportStopRoute.h
//  OsmAnd
//
//  Created by Alexey on 11/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATransportStopType.h"
#import "OATransportStop.h"
#import "OACommonTypes.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Data/TransportRoute.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSArray<NSString *> *const OATransportStopRouteArrowChars;
UIKIT_EXTERN NSString *const OATransportStopRouteArrow;

@interface OATransportStopRoute : NSObject

@property (nonatomic, strong, nullable) OATransportStop *refStop;
@property (nonatomic) OATransportStopType *type;
@property (nonatomic) NSString *desc;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::TransportRoute> route;
@property (nonatomic, strong, nullable) OATransportStop *stop;
@property (nonatomic) int stopIndex;
@property (nonatomic) int distance;
@property (nonatomic) BOOL showWholeRoute;

- (NSString *) getDescription:(BOOL)useDistance;
- (OAGpxBounds) calculateBounds:(int)startPosition;
- (UIColor *) getColor:(BOOL)nightMode;
- (NSString *) getTypeStr;

- (void) initStopIndex;
- (int) getStopIndex;
- (void) setStopIndex:(int)stopIndex;

- (OATransportStopRoute *) clone;

@end

NS_ASSUME_NONNULL_END
