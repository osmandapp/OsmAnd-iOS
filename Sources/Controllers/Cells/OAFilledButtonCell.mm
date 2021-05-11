//
//  OAFilledButtonCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAFilledButtonCell.h"

@implementation OAFilledButtonCell

+ (NSString *) getCellIdentifier
{
    return @"OAFilledButtonCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _button.layer.cornerRadius = 6.;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
