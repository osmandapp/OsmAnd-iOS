//
//  OABaseCarPlayListController.h
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(12.0))
@interface OABaseCarPlayListController : OABaseCarPlayInterfaceController

@property (nonatomic, readonly) NSString *screenTitle;

- (void) updateSections:(NSArray<CPListSection *> *)sections;

@end

NS_ASSUME_NONNULL_END
