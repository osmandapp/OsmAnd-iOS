//
//  OASelectFavoriteGroupViewController.h
//  OsmAnd
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@class OAColorItem;

@protocol OASelectFavoriteGroupDelegate <NSObject>

- (void) onGroupSelected:(NSString *)selectedGroupName;

- (void) addNewGroupWithName:(NSString *)name
                    iconName:(NSString *)iconName
                       color:(UIColor *)color
          backgroundIconName:(NSString *)backgroundIconName;

- (void)selectColorItem:(OAColorItem *)colorItem;
- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color;
- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color;
- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem;
- (void)deleteColorItem:(OAColorItem *)colorItem;

@end

@interface OASelectFavoriteGroupViewController : OABaseTableViewController

@property (nonatomic, weak) id<OASelectFavoriteGroupDelegate> delegate;

- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName;
- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName gpxWptGroups:(NSArray *)gpxWptGroups;

@end
