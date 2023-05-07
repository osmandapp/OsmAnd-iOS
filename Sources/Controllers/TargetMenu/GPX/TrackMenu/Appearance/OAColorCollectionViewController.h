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

- (NSArray<OAColorItem *> *)generateDataForColorCollection;
- (void)onColorCollectionItemSelected:(OAColorItem *)colorItem;
- (void)onColorCollectionNewItemAdded:(UIColor *)color;
- (void)onColorCollectionItemChanged:(OAColorItem *)colorItem withColor:(UIColor *)color;
- (void)onColorCollectionItemDuplicated:(OAColorItem *)colorItem;
- (void)onColorCollectionItemDeleted:(OAColorItem *)colorItem;

@end

@interface OAColorCollectionViewController : OABaseNavbarViewController

- (instancetype)initWithColorItems:(NSArray<OAColorItem *> *)colorItems selectedColorItem:(OAColorItem *)selectedColorItem;

@property(nonatomic, weak) id<OAColorCollectionDelegate>delegate;

@end
