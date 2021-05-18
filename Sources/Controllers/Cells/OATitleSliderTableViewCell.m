//
//  OATitleSliderTableViewCell.m
//  OsmAnd Maps
//
//  Created by igor on 17.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATitleSliderTableViewCell.h"

@implementation OATitleSliderTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (IBAction)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    self.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", [slider value] * 100, @"%"];
}

@end
