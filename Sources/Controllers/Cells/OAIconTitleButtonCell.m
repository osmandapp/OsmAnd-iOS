//
//  OAIconTitleButtonCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleButtonCell.h"
#import "OAUtilities.h"

@implementation OAIconTitleButtonCell

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

-(void)showImage:(BOOL)show
{
    self.iconView.hidden = !show;
    [self setNeedsLayout];
}

- (void) setButtonText:(NSString *)text
{
    [self.buttonView setTitle:text forState:UIControlStateNormal];
}

@end
