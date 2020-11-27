//
//  OAWhatsNewBottomSheetViewController.h
//  OsmAnd
//
//  Created by Max Kojin on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"

@class OAWhatsNewBottomSheetViewController;

@interface OAWhatsNewBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OABottomSheetTwoButtonsViewController *)viewController
               param:(id)param;

@end

@interface OAWhatsNewBottomSheetViewController : OABottomSheetTwoButtonsViewController

@end
