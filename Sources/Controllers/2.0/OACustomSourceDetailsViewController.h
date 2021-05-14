//
//  OACustomSourceDetailsViewController.h
//  OsmAnd Maps
//
//  Created by Paul on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OACustomResourceItem, OACustomRegion;

@interface OACustomSourceDetailsViewController : OACompoundViewController

- (instancetype) initWithCustomItem:(OACustomResourceItem *)item region:(OACustomRegion *)region;

@end

NS_ASSUME_NONNULL_END
