//
//  OABaseEditorViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarSubviewViewController.h"

@class OAGPXAppearanceCollection, OATextInputFloatingCell, OAColorItem;

@protocol OAEditorDelegate <NSObject>

- (void)addNewItemWithName:(NSString *)name
                  iconName:(NSString *)iconName
                     color:(UIColor *)color
        backgroundIconName:(NSString *)backgroundIconName;

- (void)onEditorUpdated;

- (void)selectColorItem:(OAColorItem *)colorItem;
- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color;
- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color;
- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem;
- (void)deleteColorItem:(OAColorItem *)colorItem;

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

@end
