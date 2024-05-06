//
//  OADownloadingCellResourceHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

// Using for cells with round downloading indicator.
// For all resouces cells like from Maps&Reources screen.
// Exept CountourLines. Use for it OADownloadingCellMultipleResourceHelper

#import "OADownloadingCellBaseHelper.h"

@class OAResourceItem, OAResourceSwiftItem;

@protocol OADownloadingCellResourceHelperDelegate <NSObject>
@optional
- (void) onDownldedResourceInstalled;
@end


@interface OADownloadingCellResourceHelper : OADownloadingCellBaseHelper

@property (weak, nonatomic) id<OADownloadingCellResourceHelperDelegate> delegate;
@property (weak, nonatomic) UIViewController *hostViewController;

@property (nonatomic) BOOL stopWithAlertMessage;

- (OADownloadingCell *) getOrCreateCellForResourceId:(NSString *)resourceId resourceItem:(OAResourceItem *)resourceItem;
- (OADownloadingCell *) getOrCreateSwiftCellForResourceId:(NSString *)resourceId swiftResourceItem:(OAResourceSwiftItem *)swiftResourceItem;

- (OAResourceItem *) getResource:(NSString *)resourceId;
- (void) saveResource:(OAResourceItem *)resource resourceId:(NSString *)resourceId;
- (BOOL) isDisabled:(NSString *)resourceId;
- (NSArray<NSString *> *) getAllResourceIds;

- (void)showActivatePluginPopup:(NSString *)resourceId;

@end
