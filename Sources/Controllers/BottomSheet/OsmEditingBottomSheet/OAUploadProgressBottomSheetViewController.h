//
//  OAMoreOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 26/06/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOpenStreetMapUtilsProtocol.h"
#import "OAOsmEditingViewController.h"

@class OAUploadProgressBottomSheetViewController;

@interface OAUploadProgressBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAUploadProgressBottomSheetViewController *)viewController
               param:(id)param;

- (void) setProgress:(float)progress;

@end

@interface OAUploadProgressBottomSheetViewController : OABottomSheetTwoButtonsViewController

- (void) setProgress:(float)progress;

@end
