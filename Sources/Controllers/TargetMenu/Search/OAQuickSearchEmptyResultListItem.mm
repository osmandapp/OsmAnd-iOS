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

- (EOAQuickSearchListItemType) getType
{
    return EMPTY_SEARCH;
}

@end
