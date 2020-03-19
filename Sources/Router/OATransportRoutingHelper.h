//
//  OATransportRoutingHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OATransportRouteCalculationProgressCallback <NSObject>

@required

- (void) start;
- (void) updateProgress:(int)progress;
- (void) finish;

@end

@interface OATransportRoutingHelper : NSObject

+ (OATransportRoutingHelper *) sharedInstance;

@end

