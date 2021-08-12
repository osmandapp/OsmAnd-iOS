//
//  OAPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OAPOI;

@interface OAPOIViewController : OATargetInfoViewController

@property (nonatomic, readonly) OAPOI *poi;

- (id) initWithPOI:(OAPOI *)poi;

@end
