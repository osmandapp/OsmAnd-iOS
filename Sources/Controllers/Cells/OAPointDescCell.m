//
//  OAPointDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPointDescCell.h"
#import "OAUtilities.h"
#import "OpeningHoursParser.h"

#include "java/util/Calendar.h"

@implementation OAPointDescCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_openingHoursView.text.length > 0)
    {
        CGFloat w = self.bounds.size.width - 153.0;
        CGSize s = [OAUtilities calculateTextBounds:_openingHoursView.text width:w height:_openingHoursView.bounds.size.height font:_openingHoursView.font];
        CGFloat x = self.bounds.size.width - 13.0 - s.width - 2.0 - _timeIcon.bounds.size.width;
        CGRect f = _timeIcon.frame;
        f.origin.x = x;
        _timeIcon.frame = f;
    }
    
}

- (void) updateOpeningTimeInfo
{
    if (_openingHoursView.text.length == 0)
    {
        _timeIcon.hidden = YES;
        _openingHoursView.hidden = YES;
    }
    else
    {
        NetOsmandUtilOpeningHoursParser_OpeningHours *parser = [NetOsmandUtilOpeningHoursParser parseOpenedHoursWithNSString:_openingHoursView.text];
        JavaUtilCalendar *cal = JavaUtilCalendar_getInstance();
        BOOL isOpened = [parser isOpenedForTimeWithJavaUtilCalendar:cal];
        
        UIColor *color;
        if (isOpened)
            color = UIColorFromRGB(0x32DA3A);
        else
            color = UIColorFromRGB(0xDA3A3A);
        
        _timeIcon.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_small_time"] color:color];
        
        _openingHoursView.textColor = color;
        
        _timeIcon.hidden = NO;
        _openingHoursView.hidden = NO;
    }
    
}

- (void) updateDescVisibility
{
    CGFloat w = self.bounds.size.width - 59.0;
    CGSize nameSize = [OAUtilities calculateTextBounds:_titleView.text width:w font:_titleView.font];
    CGSize descSize = [OAUtilities calculateTextBounds:_descView.text width:w font:_descView.font];
    
    _descView.hidden = nameSize.width + descSize.width + 5.0 > w;
}

@end
