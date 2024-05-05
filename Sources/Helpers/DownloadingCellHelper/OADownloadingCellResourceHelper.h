//
//  OADownloadingCellResourceHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

// Usign for cells with round downloading indicator.
// For all resouces cells like from Maps&Reources screen.
// Exept CountourLines. Use for it OADownloadingCellMultipleResourceHelper

#import "OADownloadingCellBaseHelper.h"

@class OARightIconTableViewCell, OAResourceItem, OAResourceSwiftItem;

@protocol OADownloadingCellResourceHelperDelegate <NSObject>
@optional
- (void) onDownldedResourceInstalled;
@end


@interface OADownloadingCellResourceHelper : OADownloadingCellBaseHelper

@property (weak, nonatomic) id<OADownloadingCellResourceHelperDelegate> delegate;
@property (weak, nonatomic) UIViewController *hostViewController;

@property (nonatomic) BOOL stopWithAlertMessage;

- (OARightIconTableViewCell *) getOrCreateCellForResourceId:(NSString *)resourceId resourceItem:(OAResourceItem *)resourceItem;
- (OARightIconTableViewCell *) getOrCreateSwiftCellForResourceId:(NSString *)resourceId swiftResourceItem:(OAResourceSwiftItem *)swiftResourceItem;

@end
