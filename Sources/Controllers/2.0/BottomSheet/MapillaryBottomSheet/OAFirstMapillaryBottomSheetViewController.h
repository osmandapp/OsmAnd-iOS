//
//  OAFirstMapillaryBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 29/05/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//


#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmEditingViewController.h"

@class OAFirstMapillaryBottomSheetViewController;

@interface OAFirstMapillaryBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAFirstMapillaryBottomSheetViewController *)viewController
               param:(id)param;

@end

@interface OAFirstMapillaryBottomSheetViewController : OABottomSheetTwoButtonsViewController

@end
