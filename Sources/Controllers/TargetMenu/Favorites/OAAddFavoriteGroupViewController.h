
//
//  OAAddFavoriteGroupViewController.h
//  OsmAnd
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAAddFavoriteGroupDelegate <NSObject>

- (void)onFavoriteGroupAdded:(NSString *)groupName color:(UIColor *)color;
- (void)onFavoriteGroupColorsRefresh;

@end

@interface OAAddFavoriteGroupViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OAAddFavoriteGroupDelegate> delegate;

@end

