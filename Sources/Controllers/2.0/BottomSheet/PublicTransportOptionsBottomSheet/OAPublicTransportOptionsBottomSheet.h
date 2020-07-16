//
//  OAPublicTransportOptionsBottomSheet.h
//  OsmAnd
//
//  Created by nnngrach on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"

@class OAPublicTransportOptionsBottomSheetViewController;

@interface OAPublicTransportOptionsBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController param:(id)param;

@end


@interface OAPublicTransportOptionsBottomSheetViewController : OABottomSheetTwoButtonsViewController
@end
