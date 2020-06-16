//
//  OAQuickActionType.m
//  OsmAnd
//
//  Created by Paul on 27.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAQuickActionType.h"
#import "OAQuickAction.h"

@implementation OAQuickActionType
{
    id _class;
}

- (instancetype) initWithIdentifier:(NSInteger) identifier stringId:(NSString *) stringId
{
    self = [super init];
    if (self)
    {
        _identifier = identifier;
        _stringId = stringId;
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSInteger) identifier
                           stringId:(NSString *) stringId
                              class:(id) cl
                               name:(NSString *) name
                           category:(NSInteger) category
                           iconName:(NSString *) iconName
                  secondaryIconName:(NSString *)secondaryIconName

{
    return [self initWithIdentifier:identifier stringId:stringId class:cl name:name category:category iconName:iconName secondaryIconName:secondaryIconName editable:YES];
}

- (instancetype) initWithIdentifier:(NSInteger) identifier
                           stringId:(NSString *) stringId
                              class:(id) cl
                               name:(NSString *) name
                           category:(NSInteger) category
                           iconName:(NSString *) iconName

{
    return [self initWithIdentifier:identifier stringId:stringId class:cl name:name category:category iconName:iconName secondaryIconName:nil editable:YES];
}

- (instancetype) initWithIdentifier:(NSInteger) identifier
                           stringId:(NSString *) stringId
                              class:(id) cl
                            name:(NSString *) name
                           category:(NSInteger) category
                            iconName:(NSString *) iconName
                  secondaryIconName:(NSString *)secondaryIconName
                           editable:(BOOL) editable
{
    self = [super init];
    if (self)
    {
        _identifier = identifier;
        _stringId = stringId;
        _class = cl;
        _actionEditable = cl != nil && editable;
        _name = name;
        _category = category;
        _iconName = iconName;
        _secondaryIconName = secondaryIconName;
    }
    return self;
}

- (OAQuickAction *) createNew
{
    if(_class != nil)
    {
        return [[_class alloc] init];
    }
    else
    {
        return nil;
    }
}

- (OAQuickAction *) createNew:(OAQuickAction *) q
{
    if(_class != nil && [_class respondsToSelector:@selector(initWithAction:)])
        return [[_class alloc] initWithAction:q];
    else
        return [[OAQuickAction alloc] initWithAction:q];
}

- (BOOL)hasSecondaryIcon
{
    return _secondaryIconName != nil;
}

@end
