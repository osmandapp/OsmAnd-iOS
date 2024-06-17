//
//  OASwitchableAction.h
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"

@interface OASwitchableAction<ObjectType> : OAQuickAction

- (void)executeWithParams:(NSArray<NSString *> *)params;

- (NSString *)getTranslatedItemName:(NSString *)item;

- (NSString *)getTitle:(NSArray<ObjectType> *)filters;
- (NSString *)getItemName:(ObjectType)item;

- (NSString *)getAddBtnText;
- (NSString *)getDescrHint;
- (NSString *)getDescrTitle;

- (NSArray<ObjectType> *)loadListFromParams;

- (NSString *)getListKey;

//protected abstract View.OnClickListener getOnAddBtnClickListener(MapActivity activity, final Adapter adapter);

@end
