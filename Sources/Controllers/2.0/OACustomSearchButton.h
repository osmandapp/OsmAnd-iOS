//
//  OACustomSearchButton.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchListItem.h"

typedef void(^OACustomSearchButtonOnClick)(id sender);

@interface OACustomSearchButton : OAQuickSearchListItem

@property (nonatomic) OACustomSearchButtonOnClick onClickFunction;

- (instancetype)initWithClickFunction:(OACustomSearchButtonOnClick)onClickFunction;

@end
