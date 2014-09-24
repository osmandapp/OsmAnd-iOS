//
//  OAQFlatAppearance.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAQFlatAppearance.h"

@implementation OAQFlatAppearance

- (void)setDefaults
{
    [super setDefaults];

#if __IPHONE_7_0
    if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)])
    {
        UITableViewCell* tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                reuseIdentifier:nil];

        self.labelFont = [tableViewCell.textLabel.font copy];
        self.valueFont = [tableViewCell.detailTextLabel.font copy];
        self.entryFont = [tableViewCell.detailTextLabel.font copy];
    }
#endif
    
}

@end
