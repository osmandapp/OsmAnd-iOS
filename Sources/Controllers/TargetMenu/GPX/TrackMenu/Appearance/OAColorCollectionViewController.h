//
//  OAColorCollectionViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum
{
    EOAColorCollectionTypeColorItems,
    EOAColorCollectionTypePaletteItems,
    EOAColorCollectionTypeIconItems, 
} EOAColorCollectionType;

@class OAColorItem, PaletteColor;

@protocol OAColorCollectionDelegate

- (void)selectColorItem:(OAColorItem *)colorItem;
- (void)selectPaletteItem:(PaletteColor *)paletteItem;
- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color;
- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color;
- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem;
- (void)deleteColorItem:(OAColorItem *)colorItem;


@end

@protocol OAIconCollectionDelegate

- (void)selectIconItem:(NSString *)iconItem;

@end

@interface OAColorCollectionViewController : OABaseNavbarViewController


@property(nonatomic, weak, nullable) id<OAColorCollectionDelegate>delegate;
@property(nonatomic, weak, nullable) id<OAIconCollectionDelegate>iconsDelegate;
@property(nonatomic, readonly) EOAColorCollectionType collectionType;

@property(nonatomic) UIColor *selectedIconColor;
@property(nonatomic) UIColor *regularIconColor;

- (instancetype)initWithCollectionType:(EOAColorCollectionType)type items:(id)items selectedItem:(id)selectedItem;

@end

NS_ASSUME_NONNULL_END
