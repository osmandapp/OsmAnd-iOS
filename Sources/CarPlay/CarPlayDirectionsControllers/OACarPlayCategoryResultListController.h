//
//  OACarPlayCategoryResultListController.h
//  OsmAnd Maps
//
//  Created by Paul on 18.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"

NS_ASSUME_NONNULL_BEGIN

@class OASearchResult;

API_AVAILABLE(ios(12.0))
@interface OACarPlayCategoryResultListController : OABaseCarPlayInterfaceController

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController searchResult:(OASearchResult *)sr;

@end

NS_ASSUME_NONNULL_END
