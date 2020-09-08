//
//  OADeleteProfileBottomSheetViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAApplicationMode.h"

@interface OADeleteProfileBottomSheetScreen : NSObject<OABottomSheetScreen>

- (instancetype) initWithTable:(UITableView *)tableView viewController:(OABottomSheetTwoButtonsViewController *)viewController
                         appMode:(OAApplicationMode *)am;

@end

@interface OADeleteProfileBottomSheetViewController : OABottomSheetTwoButtonsViewController

- (id) initWithMode:(OAApplicationMode *)am;

@end
