//
//  OAAddFavoriteGroupViewController.h
//  OsmAnd
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@protocol OAAddFavoriteGroupDelegate <NSObject>

- (void) onFavoriteGroupAdded:(NSString *)groupName;

@end

@interface OAAddFavoriteGroupViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAAddFavoriteGroupDelegate> delegate;

@end

