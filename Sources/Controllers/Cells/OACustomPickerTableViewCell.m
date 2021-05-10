//
//  OACustomPickerTableViewCell.m
//  OsmAnd Maps
//
//  Created by igor on 27.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACustomPickerTableViewCell.h"

@implementation OACustomPickerTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.picker.dataSource = self;
    self.picker.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.dataArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.dataArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.delegate)
        [self.delegate zoomChanged:self.dataArray[row] tag:pickerView.tag];
}

+ (NSString *) getCellIdentifier
{
    return @"OACustomPickerTableViewCell";
}

@end
