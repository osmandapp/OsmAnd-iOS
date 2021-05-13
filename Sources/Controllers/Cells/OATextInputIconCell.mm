//
//  OATextInputIconCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextInputIconCell.h"
#import "OAUtilities.h"

@implementation OATextInputIconCell

+ (NSString *) getCellIdentifier
{
    return @"OATextInputIconCell";
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
