//
//  OADirectionsGridController.h
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseCarPlayInterfaceController.h"

NS_ASSUME_NONNULL_BEGIN

@class CPInterfaceController;

API_AVAILABLE(ios(12.0))
@interface OADirectionsGridController : OABaseCarPlayInterfaceController

- (void)openSearch;

@end

NS_ASSUME_NONNULL_END
