//
//  OAIconTextDescButtonTableViewCell.m
//  OsmAnd
//
//  Created by igor on 18.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconTextDescButtonTableViewCell.h"

@implementation OAIconTextDescButtonCell

+ (NSString *) getCellIdentifier
{
    return @"OAIconTextDescButtonCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.dividerIcon.layer setCornerRadius:0.5f];
    self.additionalView.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (IBAction)checkButtonPressed:(id)sender
{
    UIButton *button = sender;
    
    if (self.delegate)
        [self.delegate onButtonPressed:button.tag];
}

@end
