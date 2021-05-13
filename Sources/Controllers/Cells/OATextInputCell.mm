//
//  OATextInputCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextInputCell.h"
#import "OAUtilities.h"

@implementation OATextInputCell

+ (NSString *) getCellIdentifier
{
    return @"OATextInputCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
