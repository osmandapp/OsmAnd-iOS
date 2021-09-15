//
//  OACoodinateSearchCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACoodinateSearchCell.h"

@implementation OACoodinateSearchCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    if ([self isDirectionRTL])
        self.textField.textAlignment = NSTextAlignmentLeft;
    else
        self.textField.textAlignment = NSTextAlignmentRight;
}

@end
