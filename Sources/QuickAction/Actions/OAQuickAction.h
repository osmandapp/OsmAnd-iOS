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

#define kSectionNoName @"no_name"

@class OrderedDictionary;
@class OAQuickActionType;

@interface OAQuickAction : NSObject

@property (nonatomic, readonly) OAQuickActionType *actionType;
@property (nonatomic) long identifier;

- (instancetype) initWithActionType:(OAQuickActionType *)type;
- (instancetype) initWithAction:(OAQuickAction *)action;

-(NSString *) getIconResName;
-(NSString *) getSecondaryIconName;
-(BOOL) hasSecondaryIcon;

-(long) getId;
-(NSInteger) getType;
-(BOOL) isActionEditable;
-(BOOL) isActionEnabled;
-(NSString *) getRawName;
-(NSString *) getDefaultName;
-(NSString *) getName;
-(BOOL) hasCustomName;
-(NSString *) getActionTypeId;

-(NSDictionary *) getParams;
-(void) setName:(NSString *) name;
-(void) setParams:(NSDictionary<NSString *, NSString *> *) params;
-(BOOL) isActionWithSlash;
-(NSString *) getActionText;
-(NSString *) getActionStateName;

-(void) execute;
-(void) drawUI;
-(OrderedDictionary *)getUIModel;
-(BOOL) fillParams:(NSDictionary *)model;

-(BOOL) hasInstanceInList:(NSArray<OAQuickAction *> *)active;
-(NSString *)getTitle:(NSArray *)filters;
-(NSString *) getListKey;

+ (OAQuickActionType *) TYPE;

@end
