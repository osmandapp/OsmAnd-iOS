//
//  OAOnlineTilesEditingViewController.h
//  OsmAnd Maps
//
//  Created by igor on 23.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAResourcesBaseViewController, OALocalResourceItem;

typedef NS_ENUM(NSInteger, EOASourceFormat)
{
    EOASourceFormatSQLite = 0,
    EOASourceFormatOnline
};

@protocol OATilesEditingViewControllerDelegate <NSObject>

- (void) onTileSourceSaved:(OALocalResourceItem *)item;

@end

@interface OAOnlineTilesEditingViewController : OABaseNavbarViewController

@property (nonatomic) id<OATilesEditingViewControllerDelegate> delegate;

- (instancetype)initWithLocalItem:(OALocalResourceItem *)item baseController: (OAResourcesBaseViewController *)baseController;
- (instancetype)initWithUrlParameters:(NSDictionary<NSString *, NSString *> *)params;
- (instancetype)initWithEmptyItem;

@end
