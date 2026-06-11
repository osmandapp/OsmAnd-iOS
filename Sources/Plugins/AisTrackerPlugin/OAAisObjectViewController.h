//
//  OAAisObjectViewController.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class AisObject;

@interface OAAisObjectViewController : OATargetInfoViewController

- (instancetype)initWithAisObject:(AisObject *)object;

@end
