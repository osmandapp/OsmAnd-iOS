//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"
#import "OASuperViewController.h"
#import "OAColorsPaletteCell.h"

@class OAColorItem, OACollectionSingleLineTableViewCell;

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath;
- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath;
- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath;

@end

@protocol OAColorCollectionHandlerDelegate

- (void)onColorCategorySelected:(NSString *)categoryKey with:(OAColorsPaletteCell *)cell;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler <OAColorsCollectionCellDelegate>

@property (nonatomic, weak) id<OACollectionCellDelegate> delegate;
@property (nonatomic, weak) id<OAColorCollectionHandlerDelegate> handlerDelegate;
@property (weak, nonatomic) OASuperViewController *hostVC;
@property (weak, nonatomic) OACollectionSingleLineTableViewCell *hostCell;
@property (weak, nonatomic) UIView *hostVCOpenColorPickerButton;
@property (weak, nonatomic) NSArray<UIColor *> *groupColors;

@property (nonatomic) BOOL isOpenedFromAllColorsScreen;
@property (weak, nonatomic) OAColorCollectionHandler *hostColorHandler NS_SWIFT_NAME(hostColorHandler);

- (instancetype)initWithData:(NSArray<NSArray *> *)data isFavoriteList:(BOOL)isFavoriteList;

- (void)setupDefaultCategory;
- (void)addColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)replaceOldColor:(NSIndexPath *)indexPath;
- (void)removeColor:(NSIndexPath *)indexPath;
- (void)updateHostCellIfNeeded;
- (void)updateTopButtonName;

- (NSMutableArray<NSMutableArray<OAColorItem *> *> *) getData;
- (OAColorItem *)getSelectedItem;

- (void)openColorPickerWithColor:(OAColorItem *)colorItem sourceView:(UIView *)sourceView newColorAdding:(BOOL)newColorAdding;
- (void)openAllColorsScreen;

@end
