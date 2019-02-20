//
//  OAOsmEditViewController.h
//  OsmAnd
//
//  Created by Alexey on 28/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OAOsmPoint;

@interface OAOsmEditTargetViewController : OATargetInfoViewController

- (instancetype) initWithOsmPoint:(OAOsmPoint *)point icon:(UIImage *)icon;

@end

