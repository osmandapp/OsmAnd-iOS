//
//  OAMapButtonsHelper.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/quickaction/QuickActionRegistry.java
//  git revision 8dedb3908aabe6e4fdd59751914516461f09e6d9

#import <Foundation/Foundation.h>

@class OAObservable, OAApplicationMode, OAQuickAction, OAQuickActionType, OAQuickActionButtonState, OAMapButtonState, OAMap3DButtonState, OACompassButtonState;

@interface OAMapButtonsHelper : NSObject

@property (readonly) OAObservable * _Nonnull quickActionListChangedObservable;

+ (OAMapButtonsHelper * _Nonnull)sharedInstance;

+ (OAQuickActionType * _Nonnull)TYPE_ADD_ITEMS;
+ (OAQuickActionType * _Nonnull)TYPE_CONFIGURE_MAP;
+ (OAQuickActionType * _Nonnull)TYPE_NAVIGATION;
+ (OAQuickActionType * _Nonnull)TYPE_CONFIGURE_SCREEN;
+ (OAQuickActionType * _Nonnull)TYPE_SETTINGS;
+ (OAQuickActionType * _Nonnull)TYPE_OPEN;

- (OAMap3DButtonState * _Nonnull)getMap3DButtonState;
- (OACompassButtonState * _Nonnull)getCompassButtonState;
- (NSArray<OAQuickActionButtonState *> * _Nonnull)getButtonsStates;
- (NSArray<OAQuickActionButtonState *> * _Nonnull)getEnabledButtonsStates;

- (void)addQuickAction:(OAQuickActionButtonState * _Nonnull)buttonState action:(OAQuickAction * _Nonnull)action;
- (void)deleteQuickAction:(OAQuickActionButtonState * _Nonnull)buttonState action:(OAQuickAction * _Nonnull)action;
- (void)updateQuickAction:(OAQuickActionButtonState * _Nonnull)buttonState action:(OAQuickAction * _Nonnull)action;
- (void)updateQuickActions:(OAQuickActionButtonState * _Nonnull)buttonState actions:(NSArray<OAQuickAction *> * _Nonnull)actions;

- (BOOL)isActionNameUnique:(NSArray<OAQuickAction *> * _Nonnull)actions quickAction:(OAQuickAction * _Nonnull)quickAction;
- (OAQuickAction * _Nonnull)generateUniqueActionName:(NSArray<OAQuickAction *> * _Nonnull)actions action:(OAQuickAction * _Nonnull)action;
- (NSString * _Nonnull)generateUniqueButtonName:(NSString * _Nonnull)name;

- (void)updateActionTypes;
- (void)updateActiveActions;
- (void)resetQuickActionsForMode:(OAApplicationMode * _Nonnull)appMode;
- (void)copyQuickActionsFromMode:(OAApplicationMode * _Nonnull)toAppMode fromAppMode:(OAApplicationMode * _Nonnull)fromAppMode;
- (NSArray<OAQuickActionType *> * _Nonnull)produceTypeActionsListWithHeaders:(OAQuickActionButtonState * _Nonnull)buttonState;
- (OAQuickAction * _Nullable)newActionByStringType:(NSString * _Nonnull)actionType;
- (OAQuickAction * _Nullable)newActionByType:(NSInteger)type;

- (BOOL)isActionButtonNameUnique:(NSString * _Nonnull)name;
- (OAQuickActionButtonState * _Nullable)getButtonStateByName:(NSString * _Nonnull)name;
- (OAQuickActionButtonState * _Nullable)getButtonStateById:(NSString * _Nonnull)id;
- (OAQuickActionButtonState * _Nonnull)createNewButtonState;
- (void)addQuickActionButtonState:(OAQuickActionButtonState * _Nonnull)buttonState;
- (void)removeQuickActionButtonState:(OAQuickActionButtonState * _Nonnull)buttonState;

+ (OAQuickAction * _Nonnull)produceAction:(OAQuickAction * _Nonnull)action;

@end
