//
//  OAOsmEditActionsViewController.h
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmEditingViewController.h"

@class OAOsmPoint;
@class OAOsmEditingPlugin;
@class OAOsmEditActionsViewController;

@interface OAOsmEditActionsViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) OAOsmPoint *osmPoint;
@property (nonatomic) id<OAOsmEditingBottomSheetDelegate> delegate;

- (id) initWithPoint:(OAOsmPoint *)point;

@end

@interface OAOsmEditActionsBottomSheetScreen : NSObject<OABottomSheetScreen>

@property (nonatomic) OAOsmEditActionsViewController *vwController;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmEditActionsViewController *)viewController
               param:(id)param;

@end
