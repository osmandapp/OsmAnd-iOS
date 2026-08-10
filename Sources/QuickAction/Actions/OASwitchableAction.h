//
//  OASwitchableAction.h
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface OASwitchableAction : OAQuickAction

- (void)executeWithParams:(NSArray<NSString *> *)params;

- (nullable NSString *)getTranslatedItemName:(NSString *)item;

- (nullable NSString *)getTitle:(NSArray *)filters;
- (nullable NSString *)getItemName:(id)item;

- (nullable NSString *)getAddBtnText;
- (nullable NSString *)getDescrHint;
- (nullable NSString *)getDescrTitle;

- (nullable NSArray *)loadListFromParams;

- (nullable NSString *)getListKey;

- (nullable NSString *)disabledItem;
- (nullable NSString *)selectedItem;
- (nullable NSString *)nextSelectedItem;

- (nullable NSString *)nextFromSource:(NSArray<NSArray<NSString *> *> *)sources defValue:(NSString *)defValue;

//protected abstract View.OnClickListener getOnAddBtnClickListener(MapActivity activity, final Adapter adapter);

@end

NS_ASSUME_NONNULL_END
