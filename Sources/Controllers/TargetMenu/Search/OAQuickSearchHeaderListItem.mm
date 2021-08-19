//
//  OAQuickSearchHeaderListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 26/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchHeaderListItem.h"

@implementation OAQuickSearchHeaderListItem
{
    NSString *_name;
}

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name;
    }
    return self;
}

- (EOAQuickSearchListItemType) getType
{
    return HEADER;
}

-(NSString *)getName
{
    return _name;
}

@end
