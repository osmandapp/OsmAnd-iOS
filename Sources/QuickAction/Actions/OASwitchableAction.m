//
//  OASwitchableAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASwitchableAction.h"

@implementation OASwitchableAction

- (instancetype)initWithAction:(OAQuickAction *)action
{
    return [super initWithAction:action];
}

- (void)executeWithParams:(NSArray<NSString *> *)params
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

- (NSArray *)getOfflineMapSources
{
    return nil;
}

-(NSArray *)getOnlineMapSources
{
    return nil;
}

@end
