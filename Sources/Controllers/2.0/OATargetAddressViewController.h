//
//  OATargetAddressViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OAAddress;

@interface OATargetAddressViewController : OATargetInfoViewController

@property (nonatomic, readonly) OAAddress *address;

- (id) initWithAddress:(OAAddress *)address;

@end
