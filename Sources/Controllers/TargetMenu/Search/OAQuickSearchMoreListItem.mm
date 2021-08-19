//
//  OAQuickSearchMoreListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchMoreListItem.h"

@implementation OAQuickSearchMoreListItem
{
    NSString *_name;
}

- (instancetype)initWithName:(NSString *)name onClickFunction:(OAQuickSearchMoreListItemOnClick)onClickFunction
{
    self = [super init];
    if (self)
    {
        _name = name;
        _onClickFunction = onClickFunction;
    }
    return self;
}

- (EOAQuickSearchListItemType) getType
{
    return SEARCH_MORE;
}

-(NSString *)getName
{
    return _name;
}

@end
