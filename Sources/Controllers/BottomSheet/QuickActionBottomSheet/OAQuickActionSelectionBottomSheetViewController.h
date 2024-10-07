//
//  OAQuickActionSelectionBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"

typedef NS_ENUM(NSInteger, EOAQASelectionType)
{
    EOAQASelectionTypeStyle = 0,
    EOAQASelectionTypeSource,
    EOAQASelectionTypeOverlay,
    EOAQASelectionTypeUnderlay,
    EOAQASelectionTypeTerrainScheme
};

@class OASwitchableAction;
@class OAQuickActionSelectionBottomSheetViewController;

@interface OAQuickActionSelectionBottomSheetScreen : NSObject<OABottomSheetScreen>

- (instancetype) initWithTable:(UITableView *)tableView viewController:(OAQuickActionSelectionBottomSheetViewController *)viewController
                         param:(id)param;

@end

@interface OAQuickActionSelectionBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) EOAQASelectionType type;

- (id) initWithAction:(OASwitchableAction *)action type:(EOAQASelectionType)type;

@end

