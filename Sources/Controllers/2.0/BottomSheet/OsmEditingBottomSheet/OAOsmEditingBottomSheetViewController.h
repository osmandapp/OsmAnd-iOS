//
//  OAMoreOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOpenStreetMapUtilsProtocol.h"
#import "OAOsmEditingViewController.h"

@class OAOsmEditingBottomSheetViewController;
@class OAOsmPoint;

@interface OAOsmEditingBottomSheetScreen : NSObject<OABottomSheetScreen>

@property (nonatomic) EOAAction action;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmEditingBottomSheetViewController *)viewController
                param:(id)param
                action:(EOAAction)action;

@end

@interface OAOsmEditingBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (strong, nonatomic) id<OAOsmEditingBottomSheetDelegate> delegate;
@property (nonatomic, readonly) OAOsmPoint *osmPoint;

- (id) initWithEditingUtils:(id<OAOpenStreetMapUtilsProtocol>)editingUtil point:(OAOsmPoint *)point action:(EOAAction)action;

@end

@protocol OAOsmMessageForwardingDelegate <NSObject>

@required

- (void) setMessageText:(NSString *)text;

- (void) refreshData;

@end
