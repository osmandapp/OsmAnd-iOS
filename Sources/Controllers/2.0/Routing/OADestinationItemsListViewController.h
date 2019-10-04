//
//  OADestinationItemsListViewController.h
//  OsmAnd
//
//  Created by Paul on 10/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAFavoriteItem;
@class OADestination;

typedef NS_ENUM (NSInteger, EOADestinationPointType)
{
    EOADestinationPointTypeFavorite = 0,
    EOADestinationPointTypeMarker
};

@protocol OADestinationPointListDelegate <NSObject>

@required
- (void) onFavoriteSelected:(OAFavoriteItem *)item;
- (void) onDestinationSelected:(OADestination *)destination;

@end

@interface OADestinationItemsListViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *sortButton;

@property (nonatomic, weak) id<OADestinationPointListDelegate> delegate;

- (instancetype) initWithDestinationType:(EOADestinationPointType)type;

@end
