//
//  OAQuickSearchMoreListItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchListItem.h"

typedef void(^OAQuickSearchMoreListItemOnClick)(id sender);

@interface OAQuickSearchMoreListItem : OAQuickSearchListItem

@property (nonatomic) OAQuickSearchMoreListItemOnClick onClickFunction;

- (instancetype)initWithName:(NSString *)name onClickFunction:(OAQuickSearchMoreListItemOnClick)onClickFunction;

@end
