//
//  OAQuickSearchEmptyResultListItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchListItem.h"

@interface OAQuickSearchEmptyResultListItem : OAQuickSearchListItem

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;

- (instancetype)initSeparator;

@end
