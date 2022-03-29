//
//  OAAlertBottomSheetViewController.h
//  OsmAnd
//
//  Created by nnngrach on 11.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

typedef void(^OAAlertBottomSheetDoneCompletionBlock)();
typedef void(^OAAlertBottomSheetSelectCompletionBlock)(NSInteger selectedIndex);

@interface OAAlertBottomSheetViewController : OABaseBottomSheetViewController

+ (void) showAlertWithMessage:(NSString *)message cancelTitle:(NSString *)cancelTitle;
+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle doneTitle:(NSString *)doneTitle  doneColpletition:(OAAlertBottomSheetDoneCompletionBlock)doneColpletition;
+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon cancelTitle:(NSString *)cancelTitle selectableItemsTitles:(NSArray<NSString *> *)selectableItemsTitles selectableItemsImages:(NSArray<NSString *> *)selectableItemsImages  selectColpletition:(OAAlertBottomSheetSelectCompletionBlock)selectColpletition;
+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle doneTitle:(NSString *)doneTitle  selectableItemsTitles:(NSArray<NSString *> *)selectableItemsTitles selectableItemsImages:(NSArray<NSString *> *)selectableItemsImages doneColpletition:(OAAlertBottomSheetDoneCompletionBlock)doneColpletition selectColpletition:(OAAlertBottomSheetSelectCompletionBlock)selectColpletition;

@end
