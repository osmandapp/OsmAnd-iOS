//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"
#import "OASuperViewController.h"
#import "OAColorCollectionViewController.h"

@class OAColorItem;

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath;
- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath;
- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler <OAColorCollectionDelegate, OAColorsCollectionCellDelegate>

@property (nonatomic, weak) id<OAColorsCollectionCellDelegate> delegate;
@property (weak, nonatomic) OASuperViewController<OAColorCollectionDelegate> *hostVC;
@property (weak, nonatomic) UIView *hostVCOpenColorPickerButton;

- (void)addColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)replaceOldColor:(NSIndexPath *)indexPath;
- (void)removeColor:(NSIndexPath *)indexPath;

- (NSMutableArray<NSMutableArray<OAColorItem *> *> *) getData;
- (OAColorItem *)getSelectedItem;

- (void)openColorPickerWithSelectedColor;
- (void)openColorPickerWithColor:(OAColorItem *)colorItem sourceView:(UIView *)sourceView;
- (void)openAllColorsScreen;

@end
