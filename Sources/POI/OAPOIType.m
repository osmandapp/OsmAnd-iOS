//
//  OAPOI.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIType.h"

@implementation OAPOIType

- (UIImage *)icon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@", self.name]];
    if (!img)
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@_%@", self.tag, self.value]];
    if (!img)
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@", self.value]];
    
    return img;
}

@end
