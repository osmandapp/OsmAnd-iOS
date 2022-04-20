//
//  OAEditWaypointsGroupOptionsViewController.this
//  OsmAnd
//
//  Created by Skalii on 21.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

typedef NS_ENUM(NSUInteger, EOAEditWaypointsGroupScreen)
{
    EOAEditWaypointsGroupRenameScreen = 0,
    EOAEditWaypointsGroupColorScreen,
    EOAEditWaypointsGroupVisibleScreen,
    EOAEditWaypointsGroupCopyToFavoritesScreen
};

@class OAGpxWptItem;

@protocol OAEditWaypointsGroupOptionsDelegate <NSObject>

@optional

- (void)updateWaypointsGroup:(NSString *)groupName color:(UIColor *)color;
- (void)copyToFavorites:(NSString *)groupName;

- (NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *)getWaypointsData;
- (NSArray<NSString *> *)getWaypointSortedGroups;
- (NSInteger)getWaypointsGroupColor:(NSString *)groupName;
- (BOOL)isWaypointsGroupVisible:(NSString *)groupName;
- (void)setWaypointsGroupVisible:(NSString *)groupName show:(BOOL)show;
- (BOOL)isRteGroup:(NSString *)groupName;

@end

@interface OAEditWaypointsGroupOptionsViewController : OABaseTableViewController

- (instancetype)initWithScreenType:(EOAEditWaypointsGroupScreen)screenType
                         groupName:(NSString *)groupName
                        groupColor:(UIColor *)groupColor;

@property (nonatomic, weak) id<OAEditWaypointsGroupOptionsDelegate> delegate;

@end
