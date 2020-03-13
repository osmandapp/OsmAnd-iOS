//
//  OAQColorPickerElement.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAQColorPickerElement.h"

@implementation OAQColorPickerElement

- (void)updateCell:(QEntryTableViewCell *)cell selectedValue:(id)selectedValue
{
    [super updateCell:cell selectedValue:selectedValue];
    
    if (self.title == nil)
    {
        cell.textField.textColor = self.enabled ? self.appearance.valueColorEnabled : self.appearance.valueColorDisabled;
    }
    else
    {
        cell.textField.textColor = self.enabled ? self.appearance.entryTextColorEnabled : self.appearance.entryTextColorDisabled;
    }
}

@end
