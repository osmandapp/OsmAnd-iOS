//
//  OAQuickAction.m
//  OsmAnd
//
//  Created by Paul on 8/6/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"
#import "OAMapButtonsHelper.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

static NSInteger SEQ = 0;

@interface OAQuickAction()

@property (nonatomic) NSString *name;
@property (nonatomic) NSDictionary<NSString *, NSString *> *params;

@end

@implementation OAQuickAction

- (instancetype)init
{
    return [self initWithActionType:OAMapButtonsHelper.TYPE_CREATE_CATEGORY];
}

- (instancetype)initWithActionType:(QuickActionType *)type
{
    self = [super init];
    if (self)
    {
        _id = [[NSDate date] timeIntervalSince1970] * 1000 + (SEQ++);
        _actionType = type;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithAction:(OAQuickAction *)action
{
    self = [super init];
    if (self)
    {
        _id = action.id;
        _name = action.getRawName;
        _actionType = action.actionType;
        _params = action.getParams;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
}

- (NSString *)getIconResName
{
    return _actionType ? _actionType.iconName : nil;
}

- (UIImage *)getActionIcon
{
    NSString *iconResName = [self getIconResName];
    if (iconResName)
    {
        if ([iconResName hasPrefix:@"mx_"])
            return [[OAUtilities getMxIcon:iconResName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        else
            return [UIImage templateImageNamed:iconResName];
    }
    return nil;
}

- (NSString *)getSecondaryIconName
{
    return _actionType ? _actionType.secondaryIconName : nil;
}

- (BOOL)hasSecondaryIcon
{
    return self.getSecondaryIconName != nil;
}

- (void)setId:(long)id
{
    _id = id;
}

-(NSInteger) getType
{
    return _actionType ? _actionType.id : 0;
}

-(BOOL) isActionEditable
{
    return _actionType != nil && _actionType.actionEditable;
}

-(NSString *) getRawName
{
    return _name;
}

-(NSString *) getDefaultName
{
    return _actionType ? _actionType.name : @"";
}


-(NSString *) getActionName
{
    return _actionType ? _actionType.nameAction : @"";
}

- (NSString *)getName
{
    NSString *name;
    if (_name.length == 0 || !self.isActionEditable)
        name = [self getDefaultName];
    else
        name = _name;
    
    NSString *actionName = [self getActionName];
    if (actionName)
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), actionName, name];
    return name;
}

- (BOOL) hasCustomName
{
    return ![[self getName] isEqualToString:[self getDefaultName]];
}

- (NSString *) getActionTypeId
{
    return _actionType ? _actionType.stringId : nil;
}

- (NSDictionary<NSString *, NSString *> *)getParams
{
    if (!_params)
        _params = [NSDictionary new];

    return _params;
}

-(void) setName:(NSString *) name
{
    _name = name;
}

-(void) setParams:(NSDictionary<NSString *, NSString *> *) params
{
    _params = params;
}

-(BOOL) isActionWithSlash
{
    return NO;
}

- (BOOL)isActionEnabled
{
    return YES;
}

-(NSString *) getActionText
{
    return [self getName];
}

-(NSString *) getActionStateName
{
    return [self getName];
}

- (CLLocation *)getMapLocation
{
    return [[OAMapViewTrackingUtilities instance] getMapLocation];
}

- (void)execute
{
}

- (void)drawUI
{
}

-(OrderedDictionary *)getUIModel
{
    return [[OrderedDictionary alloc] init];
}

- (BOOL)fillParams:(NSDictionary *)model
{
    return YES;
}

-(BOOL) hasInstanceInList:(NSArray<OAQuickAction *> *) active
{
    for (OAQuickAction *action in active)
    {
        if (action.getType == self.getType)
            return YES;
    }

    return NO;
}

- (NSString *)getTitle:(NSArray *)filters
{
    return nil;
}

- (NSString *)getListKey
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OAQuickAction *action = (OAQuickAction *) object;
        if (self.getType != action.getType)
            return NO;
        if (_id != action.id)
            return NO;
        return YES;
    }
    else
    {
        return NO;
    }
}

- (NSUInteger)hash
{
    NSInteger result = self.getType;
    result = 31 * result + (NSInteger) (_id ^ (_id >> 32));
    result = 31 * result + (_name != nil ? [_name hash] : 0);
    return result;
}

+ (QuickActionType *) TYPE
{
    return nil;
}

@end
