//
//  OAFollowTrackBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OASGpxFile;

@interface OAFollowTrackBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype) initWithFile:(OASGpxFile *)gpx;
- (void)presentOpenTrackViewController:(BOOL)animated;

@end
