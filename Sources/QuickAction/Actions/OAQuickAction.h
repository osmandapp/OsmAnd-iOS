//
//  OAQuickAction.h
//  OsmAnd
//
//  Created by Paul on 8/6/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kSectionNoName = @"no_name";
static NSString * const kDialog = @"dialog";

@class OrderedDictionary, QuickActionType;

@interface OAQuickAction : NSObject

@property (nonatomic, readonly, nullable) QuickActionType *actionType;
@property (nonatomic, readonly) long id;

- (instancetype)initWithActionType:(QuickActionType *)type;
- (instancetype)initWithAction:(OAQuickAction *)action;
- (void) commonInit;

- (nullable NSString *)getIconResName;
- (nullable NSString *)getSecondaryIconName;
- (nullable UIImage *)getActionIcon;
- (BOOL)hasSecondaryIcon;

- (void)setId:(long)id;
- (NSInteger)getType;
- (BOOL)isActionEditable;
- (BOOL)isActionEnabled;
- (nullable NSString *)getRawName;
- (NSString *)getDefaultName;
- (nullable NSString *)getName;
- (BOOL)hasCustomName;
- (nullable NSString *)getActionTypeId;

- (NSDictionary *)getParams;
- (void)setName:(NSString *)name;
- (void)setParams:(NSDictionary *)params;
- (BOOL)isActionWithSlash;
- (nullable NSString *)getActionText;
- (nullable NSString *)getActionStateName;
- (CLLocation *)getMapLocation;

- (void)execute;
- (void)drawUI;
- (OrderedDictionary *)getUIModel;
- (BOOL)fillParams:(NSDictionary *)model;

- (BOOL)hasInstanceInList:(NSArray<OAQuickAction *> *)active;
- (nullable NSString *)getTitle:(NSArray *)filters;
- (nullable NSString *)getListKey;

+ (QuickActionType *)TYPE;

@end

NS_ASSUME_NONNULL_END
