//
//  OAQuickSearchEmptyResultListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchEmptyResultListItem.h"
#import "Localization.h"

@implementation OAQuickSearchEmptyResultListItem
{
    BOOL _separatorItem;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _title = OALocalizedString(@"nothing_found_empty");
        _message = OALocalizedString(@"nothing_found_descr");
    }
    return self;
}

- (instancetype)initSeparator
{
    self = [super init];
    if (self)
    {
        _separatorItem = YES;
    }
    return self;
}

- (EOAQuickSearchListItemType) getType
{
    return _separatorItem ? SEPARATOR_ITEM : EMPTY_SEARCH;
}

@end
