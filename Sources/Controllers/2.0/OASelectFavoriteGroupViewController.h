//
//  OASelectFavoriteGroupViewController.h
//  OsmAnd
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@protocol OASelectFavoriteGroupDelegate <NSObject>

- (void) onGroupSelected:(NSString *)selectedGroupName;
- (void) onNewGroupAdded:(NSString *)selectedGroupName color:(UIColor *)color;

@end

@interface OASelectFavoriteGroupViewController : OABaseTableViewController

@property (nonatomic, weak) id<OASelectFavoriteGroupDelegate> delegate;

- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName;

@end
