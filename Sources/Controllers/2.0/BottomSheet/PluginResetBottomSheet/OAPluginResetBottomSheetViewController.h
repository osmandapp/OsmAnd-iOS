//
//  OAPluginResetBottomSheet.h
//  OsmAnd
//
//  Created by nnngrach on 14.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"

@protocol OAConfigureProfileDelegate <NSObject>

- (void) updateViewControllerWithAppMode:(OAApplicationMode *)appMode;

@end


@class OAPluginResetBottomSheetViewController;

@interface OAPluginResetBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAPluginResetBottomSheetViewController *)viewController
               param:(id)param;

@end

@interface OAPluginResetBottomSheetViewController : OABottomSheetTwoButtonsViewController

    @property (nonatomic, weak) id<OAConfigureProfileDelegate> delegate;
@end
