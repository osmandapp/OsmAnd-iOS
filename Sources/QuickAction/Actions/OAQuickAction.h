//
//  OAQuickAction.h
//  OsmAnd
//
//  Created by Paul on 8/6/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"
#import "Localization.h"

static NSString * _Nonnull const kSectionNoName = @"no_name";
static NSString * _Nonnull const kDialog = @"dialog";

@class OrderedDictionary, QuickActionType;

@interface OAQuickAction : NSObject

@property (nonatomic, readonly) QuickActionType * _Nullable actionType;
@property (nonatomic, readonly) long id;

- (instancetype _Nonnull)initWithActionType:(QuickActionType * _Nonnull)type;
- (instancetype _Nonnull)initWithAction:(OAQuickAction * _Nonnull)action;
- (void) commonInit;

- (NSString * _Nullable)getIconResName;
- (NSString * _Nullable)getSecondaryIconName;
- (UIImage * _Nullable)getActionIcon;
- (BOOL)hasSecondaryIcon;

- (void)setId:(long)id;
- (NSInteger)getType;
- (BOOL)isActionEditable;
- (BOOL)isActionEnabled;
- (NSString *)getRawName;
- (NSString *)getDefaultName;
- (NSString *)getName;
- (BOOL)hasCustomName;
- (NSString *)getActionTypeId;

- (NSDictionary * _Nonnull)getParams;
- (void)setName:(NSString *)name;
- (void)setParams:(NSDictionary *)params;
- (BOOL)isActionWithSlash;
- (NSString *)getActionText;
- (NSString *)getActionStateName;
- (CLLocation *)getMapLocation;

- (void)execute;
- (void)drawUI;
- (OrderedDictionary *)getUIModel;
- (BOOL)fillParams:(NSDictionary * _Nonnull)model;

- (BOOL)hasInstanceInList:(NSArray<OAQuickAction *> *)active;
- (NSString *)getTitle:(NSArray *)filters;
- (NSString *)getListKey;

+ (QuickActionType *)TYPE;

@end
