//
//  OAColorCollectionViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAColorItem;

@protocol OAColorCollectionDelegate

- (void)selectColorItem:(OAColorItem *)colorItem;
- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color;
- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color;
- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem;
- (void)deleteColorItem:(OAColorItem *)colorItem;

@end

@interface OAColorCollectionViewController : OABaseNavbarViewController

- (instancetype)initWithColorItems:(NSArray<OAColorItem *> *)colorItems selectedColorItem:(OAColorItem *)selectedColorItem;

@property(nonatomic, weak) id<OAColorCollectionDelegate>delegate;

@end
