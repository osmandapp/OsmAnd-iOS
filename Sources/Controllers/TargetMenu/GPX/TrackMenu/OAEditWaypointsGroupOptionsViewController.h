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
};

@protocol OAEditWaypointsGroupOptionsDelegate <NSObject>

- (void)updateWaypointsGroup:(NSString *)groupName
                  groupColor:(UIColor *)groupColor;

@end

@interface OAEditWaypointsGroupOptionsViewController : OABaseTableViewController

- (instancetype)initWithScreenType:(EOAEditWaypointsGroupScreen)screenType
                         groupName:(NSString *)groupName
                        groupColor:(UIColor *)groupColor;

@property (nonatomic, weak) id<OAEditWaypointsGroupOptionsDelegate> delegate;

@end
