//
//  OAWikiLinkBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAResourcesBaseViewController.h"

@interface OAWikiLinkBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@interface OAWikiLinkBottomSheetViewController : OABottomSheetTwoButtonsViewController

- (instancetype) initWithUrl:(NSString *)url localItem:(OARepositoryResourceItem *)localItem;

@property (nonatomic, readonly) OARepositoryResourceItem *localItem;

@end

