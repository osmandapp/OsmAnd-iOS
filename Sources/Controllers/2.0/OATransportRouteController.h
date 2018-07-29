//
//  OATransportRouteController.h
//  OsmAnd
//
//  Created by Alexey on 28/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OATransportStopRoute, OATargetPoint;

@interface OATransportRouteController : OATargetInfoViewController

@property (nonatomic, readonly) OATransportStopRoute *transportRoute;

@property (weak, nonatomic) IBOutlet UIButton *buttonClose;

- (instancetype) initWithTransportRoute:(OATransportStopRoute *)transportRoute;

+ (OATargetPoint *) getTargetPoint:(OATransportStopRoute *)r;
+ (NSString *) getTitle:(OATransportStopRoute *)transportRoute;

+ (void) showToolbar:(OATransportStopRoute *)transportRoute;
+ (void) hideToolbar;

@end
