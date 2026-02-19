//
//  OASwitchableAction.h
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"

@interface OASwitchableAction : OAQuickAction

- (void)executeWithParams:(NSArray<NSString *> *)params;

- (NSString *)getTranslatedItemName:(NSString *)item;

- (NSString *)getTitle:(NSArray *)filters;
- (NSString *)getItemName:(id)item;

- (NSString *)getAddBtnText;
- (NSString *)getDescrHint;
- (NSString *)getDescrTitle;

- (NSArray *)loadListFromParams;

- (NSString *)getListKey;

- (NSString *)disabledItem;
- (NSString *)selectedItem;
- (NSString *)nextSelectedItem;

- (NSString *)nextFromSource:(NSArray<NSArray<NSString *> *> *)sources defValue:(NSString *)defValue;

//protected abstract View.OnClickListener getOnAddBtnClickListener(MapActivity activity, final Adapter adapter);

@end
