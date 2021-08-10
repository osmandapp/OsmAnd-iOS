//
//  OAMapDownloadController.h
//  OsmAnd
//
//  Created by Paul on 07.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATargetInfoViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OADownloadMapObject;

@interface OAMapDownloadController : OATargetInfoViewController

- (instancetype) initWithMapObject:(OADownloadMapObject *)downloadMapObject;

@end

NS_ASSUME_NONNULL_END
