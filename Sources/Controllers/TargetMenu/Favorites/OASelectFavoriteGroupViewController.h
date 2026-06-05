//
//  OASelectFavoriteGroupViewController.h
//  OsmAnd
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OASPaletteItemSolid;

@protocol OASelectFavoriteGroupDelegate <NSObject>

- (void) onGroupSelected:(NSString *)selectedGroupName;

- (void) addNewGroupWithName:(NSString *)name
                    iconName:(NSString *)iconName
                       color:(UIColor *)color
          backgroundIconName:(NSString *)backgroundIconName;

- (void)selectColorItem:(OASPaletteItemSolid *)colorItem;
- (OASPaletteItemSolid *)addAndGetNewColorItem:(UIColor *)color;
- (void)changeColorItem:(OASPaletteItemSolid *)colorItem withColor:(UIColor *)color;
- (OASPaletteItemSolid *)duplicateColorItem:(OASPaletteItemSolid *)colorItem;
- (void)deleteColorItem:(OASPaletteItemSolid *)colorItem;

@end

@interface OASelectFavoriteGroupViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OASelectFavoriteGroupDelegate> delegate;

- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName;
- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName gpxWptGroups:(NSArray *)gpxWptGroups;

@end
