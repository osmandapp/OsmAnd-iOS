//
//  OAInstallMapillaryBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 29/05/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//


#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmEditingViewController.h"

@class OAInstallMapillaryBottomSheetViewController;

@interface OAInstallMapillaryBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAInstallMapillaryBottomSheetViewController *)viewController
               param:(id)param;

@end

@interface OAInstallMapillaryBottomSheetViewController : OABottomSheetTwoButtonsViewController

@end
