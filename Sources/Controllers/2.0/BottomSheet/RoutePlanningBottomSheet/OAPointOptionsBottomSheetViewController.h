//
//  OAPointOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OAGpxTrkPt;

@interface OAPointOptionsBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype) initWithPoint:(OAGpxTrkPt *)point index:(NSInteger)pointIndex;

@end
