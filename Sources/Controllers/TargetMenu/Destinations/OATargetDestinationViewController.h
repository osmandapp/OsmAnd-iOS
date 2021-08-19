//
//  OATargetDestinationViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OADestination;

@interface OATargetDestinationViewController : OATargetInfoViewController

@property (nonatomic, readonly) OADestination *destination;

- (id)initWithDestination:(OADestination *)destination;

@end
