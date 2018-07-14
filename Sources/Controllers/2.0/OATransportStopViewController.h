//
//  OATransportStopViewController.h
//  OsmAnd
//
//  Created by Alexey on 13/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OATransportStop;

@interface OATransportStopViewController : OATargetInfoViewController

@property (nonatomic, readonly) OATransportStop *transportStop;

- (id) initWithTransportStop:(OATransportStop *)transportStop;

@end
