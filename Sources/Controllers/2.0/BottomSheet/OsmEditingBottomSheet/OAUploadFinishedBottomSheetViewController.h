//
//  OAMoreOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 20/06/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOpenStreetMapUtilsProtocol.h"
#import "OAOsmEditingViewController.h"

@class OAUploadFinishedBottomSheetViewController;
@class OAOsmPoint;

@protocol OAUploadBottomSheetDelegate <NSObject>

@required

- (void) retryUpload;

@end

@interface OAUploadFinishedBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAUploadFinishedBottomSheetViewController *)viewController
               param:(id)param;

@end

@interface OAUploadFinishedBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) NSInteger successfulUploadsCount;
@property (nonatomic) id<OAUploadBottomSheetDelegate> delegate;

- (id) initWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads;

@end
