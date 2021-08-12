//
//  OASaveTrackBottomSheetViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"
#import "OAGPXDatabase.h"

@interface OASaveTrackBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype) initWithFileName:(NSString *)fileName;

@end
