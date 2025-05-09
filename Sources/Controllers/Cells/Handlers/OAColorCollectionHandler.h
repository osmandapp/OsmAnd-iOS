//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"
#import "OASuperViewController.h"

@class OAColorItem, OACollectionSingleLineTableViewCell;

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath;
- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath;
- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler <OAColorsCollectionCellDelegate>

@property (nonatomic, weak) id<OACollectionCellDelegate> delegate;
@property (weak, nonatomic) OASuperViewController *hostVC;
@property (weak, nonatomic) OACollectionSingleLineTableViewCell *hostCell;
@property (weak, nonatomic) UIView *hostVCOpenColorPickerButton;

@property (nonatomic) BOOL isOpenedFromAllColorsScreen;
@property (weak, nonatomic) OAColorCollectionHandler *hostColorHandler NS_SWIFT_NAME(hostColorHandler);


- (void)addColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)replaceOldColor:(NSIndexPath *)indexPath;
- (void)removeColor:(NSIndexPath *)indexPath;

- (NSMutableArray<NSMutableArray<OAColorItem *> *> *) getData;
- (OAColorItem *)getSelectedItem;
- (void)setSelectionItem:(OAColorItem *)item;

- (void)openColorPickerWithColor:(OAColorItem *)colorItem sourceView:(UIView *)sourceView newColorAdding:(BOOL)newColorAdding;
- (void)openAllColorsScreen;

@end
