//
//  OAIconTextDescSwitchCell.m
//  OsmAnd
//
//  Created by igor on 18.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconTextDescSwitchCell.h"

@implementation OAIconTextDescSwitchCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.dividerView.layer setCornerRadius:0.5f];
    [self makeSafeAreaClickable];
}

- (void) makeSafeAreaClickable
{
    UIButton *myButton = [[UIButton alloc] initWithFrame:CGRectZero];
    myButton.backgroundColor = UIColor.clearColor;
    [myButton addTarget:self action:@selector(switchAreaButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    myButton.translatesAutoresizingMaskIntoConstraints = false;
    [self addSubview:myButton];

    [myButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:0].active = YES;
    [myButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0].active = YES;
    [myButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0].active = YES;
    [myButton.leftAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0].active = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (IBAction)switchAreaButtonAction:(id)sender {
    [self.switchView setOn:!self.switchView.isOn animated:YES];
    [self.switchView sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
