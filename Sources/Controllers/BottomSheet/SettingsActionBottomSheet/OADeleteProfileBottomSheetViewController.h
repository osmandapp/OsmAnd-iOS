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

@protocol OADeleteProfileBottomSheetDelegate <NSObject>

@required

- (void) onDeleteProfileDismissed;

@end

@interface OADeleteProfileBottomSheetScreen : NSObject<OABottomSheetScreen>

- (instancetype) initWithTable:(UITableView *)tableView viewController:(OABottomSheetTwoButtonsViewController *)viewController
                         appMode:(OAApplicationMode *)am;

@end

@interface OADeleteProfileBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic) id<OADeleteProfileBottomSheetDelegate> delegate;

- (id) initWithMode:(OAApplicationMode *)am;

@end
