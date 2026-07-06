//
//  OABaseEditorViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarSubviewViewController.h"

@class OAFavoriteGroup, OAGPXAppearanceCollection, OATextInputFloatingCell, OASPaletteItemSolid, PoiIconCollectionHandler;

@protocol OAEditorDelegate <NSObject>

- (void)addNewItemWithName:(NSString *)name
                  iconName:(NSString *)iconName
                     color:(UIColor *)color
        backgroundIconName:(NSString *)backgroundIconName;

- (void)onEditorUpdated;

- (void)selectColorItem:(OASPaletteItemSolid *)colorItem;
- (OASPaletteItemSolid *)addAndGetNewColorItem:(UIColor *)color;
- (void)changeColorItem:(OASPaletteItemSolid *)colorItem withColor:(UIColor *)color;
- (OASPaletteItemSolid *)duplicateColorItem:(OASPaletteItemSolid *)colorItem;
- (void)deleteColorItem:(OASPaletteItemSolid *)colorItem;

@end

@interface OABaseEditorViewController : OABaseNavbarSubviewViewController

@property(nonatomic, readonly) NSString *originalName;
@property(nonatomic, readonly) NSString *editName;
@property(nonatomic, readonly) UIColor *editColor;
@property(nonatomic, readonly) NSString *editIconName;
@property(nonatomic, readonly) NSString *editBackgroundIconName;
@property(nonatomic, readonly) BOOL isNewItem;
@property(nonatomic, readonly) BOOL wasChanged;
@property(nonatomic, readonly) OAGPXAppearanceCollection *appearanceCollection;
@property(nonatomic, weak) id<OAEditorDelegate> delegate;

- (instancetype)initWithNew;

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint
                                             text:(NSString *)text
                                              tag:(NSInteger)tag;
- (BOOL)isAppearanceChanged;
- (nullable OAFavoriteGroup *)existingGroupFor:(NSString *_Nullable)name;
- (BOOL)allowsExistingGroupFor:(NSString *_Nonnull)name group:(nullable OAFavoriteGroup *)group;
- (BOOL)allowsValidationForGroupName;

- (PoiIconCollectionHandler *) getPoiIconCollectionHandler;

@end
