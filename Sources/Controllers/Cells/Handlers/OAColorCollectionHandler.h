//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"
#import "OsmAndSharedWrapper.h"

@class OACollectionSingleLineTableViewCell;

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath;
- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath;
- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler

@property (nonatomic, weak) id<OACollectionCellDelegate> delegate;
@property (weak, nonatomic) UIViewController *hostVC;
@property (weak, nonatomic) OACollectionSingleLineTableViewCell *hostCell;
@property (weak, nonatomic) UIView *hostVCOpenColorPickerButton;
@property (strong, nonatomic) NSArray<UIColor *> *groupColors;

@property (nonatomic) BOOL isOpenedFromAllColorsScreen;
@property (weak, nonatomic) OAColorCollectionHandler *hostColorHandler NS_SWIFT_NAME(hostColorHandler);

- (instancetype)initWithData:(NSArray<NSArray<OASPaletteItemSolid *> *> *)data isFavoriteList:(BOOL)isFavoriteList;

- (void)setupDefaultCategory;
- (void)addColor:(NSIndexPath *)indexPath newItem:(OASPaletteItemSolid *)newItem;
- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OASPaletteItemSolid *)newItem;
- (void)removeColor:(NSIndexPath *)indexPath;
- (void)updateHostCellIfNeeded;

- (NSMutableArray<NSMutableArray<OASPaletteItemSolid *> *> *)getData;
- (OASPaletteItemSolid *)getSelectedItem;
- (void)setSelectionItem:(OASPaletteItemSolid *)item;

- (void)openColorPickerWithColor:(OASPaletteItemSolid *)colorItem sourceView:(UIView *)sourceView newColorAdding:(BOOL)newColorAdding;
- (void)openAllColorsScreen;

@end
