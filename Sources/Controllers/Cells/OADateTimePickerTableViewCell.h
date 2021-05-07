//
//  OADateTimePickerTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OADateTimePickerTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePicker;

@end
