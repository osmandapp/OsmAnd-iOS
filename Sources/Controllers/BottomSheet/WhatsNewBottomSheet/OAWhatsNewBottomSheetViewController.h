//
//  OAWhatsNewBottomSheetViewController.h
//  OsmAnd
//
//  Created by Max Kojin on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//


#import "OABaseBottomSheetViewController.h"

@interface OAWhatsNewBottomSheetViewController : OABaseBottomSheetViewController

// NO when there are no release notes for this version, or the same notes were already shown
+ (BOOL) hasUnseenReleaseNotes;

@end
