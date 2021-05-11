//
//  OACustomSelectionCollapsableCell.m
//  OsmAnd Maps
//
//  Created by Paul on 03.26.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACustomSelectionCollapsableCell.h"
#import "OAColors.h"

@implementation OACustomSelectionCollapsableCell

+ (NSString *) getCellIdentifier
{
    return @"OACustomSelectionCollapsableCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _selectionButtonContainer.layer.cornerRadius = 10.75;
    _selectionButtonContainer.layer.borderWidth = 1.5;
    _selectionButtonContainer.layer.borderColor = UIColorFromRGB(color_checkbox_outline).CGColor;
    
    _checkboxHeightContainer.constant = 21.5;
    _checkboxWidthContainer.constant = 21.5;
}

@end
