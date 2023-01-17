//
//  OATransportStopViewController.h
//  OsmAnd
//
//  Created by Alexey on 13/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportStopsBaseController.h"

const static CGFloat kTransportStopPlateWidth = 32.0;
const static CGFloat kTransportStopPlateHeight = 18.0;

@class OATransportStop;

@interface OATransportStopViewController : OATransportStopsBaseController

- (id) initWithTransportStop:(OATransportStop *)transportStop;

+ (UIImage *) createStopPlate:(NSString *)text color:(UIColor *)color;
+ (NSString *) adjustRouteRef:(NSString *)ref;

@end
