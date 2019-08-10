//
//  OASwitchableAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASwitchableAction.h"

@implementation OASwitchableAction

-(instancetype) initWithType:(NSInteger)type
{
    return [super initWithType:type];
}

- (instancetype)initWithAction:(OAQuickAction *)action
{
    return [super initWithAction:action];
}

- (NSArray *)loadListFromParams
{
    return nil;
}

- (void)executeWithParams:(NSString *)params
{
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    return nil;
}

- (NSString *)getTitle:(NSArray *)filters
{
    return nil;
}

- (void)saveListToParams:(NSArray *)list
{
}

- (NSString *)getItemName:(id)item
{
    return nil;
}

- (NSString *)getAddBtnText
{
    return nil;
}

- (NSString *)getDescrHint
{
    return nil;
}

- (NSString *) getDescrTitle
{
    return nil;
}

- (NSString *)getListKey
{
    return nil;
}

@end
