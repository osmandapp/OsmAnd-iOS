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
    return [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@_%@", self.tag, self.name]];
}

@end
