//
//  OAButtonCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAButtonCell.h"
#import "OAUtilities.h"

@implementation OAButtonCell
{
    BOOL _showIcon;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _showIcon = NO;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)showImage:(BOOL)show
{
    self.iconView.hidden = !show;
    self.buttonLeadingNoIcon.active = !show;
    self.buttonLeadingToIcon.active = show;
    if ([self isDirectionRTL])
        self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    _showIcon = show;
}


@end
