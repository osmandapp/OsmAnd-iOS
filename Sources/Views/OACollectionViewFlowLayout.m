//
//  OASlider.h
//  OsmAnd
//
//  Created by Skalii on 18.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACollectionViewFlowLayout.h"

@implementation OACollectionViewFlowLayout

- (BOOL)flipsHorizontallyInOppositeLayoutDirection
{
    return UIApplication.sharedApplication.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

@end
