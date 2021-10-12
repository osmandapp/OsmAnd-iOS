//
//  OATabBar.mm
//  OsmAnd
//
//  Created by Skalii on 13.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATabBar.h"

@implementation OATabBar

- (UITraitCollection *)traitCollection
{
    UITraitCollection *curr = [super traitCollection];
    UITraitCollection *compact = [UITraitCollection  traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];

    return [UITraitCollection traitCollectionWithTraitsFromCollections:@[curr, compact]];
}

@end
