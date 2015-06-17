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
#import "Localization.h"

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

- (NSString *)findOpeningHours
{
    const int intervalMinutes = 120; // 2 hours
    const int arrLength = intervalMinutes / 5;
    int minutesArr[arrLength];

    int k = 0;
    for (int i = 0; i < arrLength; i++)
    {
        minutesArr[i] = k;
        k += 5;
    }
    
    NetOsmandUtilOpeningHoursParser_OpeningHours *parser = [NetOsmandUtilOpeningHoursParser parseOpenedHoursWithNSString:_openingHoursView.text];
    JavaUtilCalendar *cal = JavaUtilCalendar_getInstance();
    jlong currentTime = [cal getTimeInMillis];
    BOOL isOpenedNow = [parser isOpenedForTimeWithJavaUtilCalendar:cal];

    jlong newTime = currentTime + intervalMinutes * 60 * 1000;
    [cal setTimeInMillisWithLong:newTime];
    BOOL isOpened = [parser isOpenedForTimeWithJavaUtilCalendar:cal];
    if (isOpened == isOpenedNow)
        return (isOpenedNow ? OALocalizedString(@"time_open") : OALocalizedString(@"time_closed"));

    int imax = arrLength - 1;
    int imin = 0;
    int imid;
    while (imax >= imin)
    {
        imid = (imin + imax) / 2;
        
        jlong newTime = currentTime + minutesArr[imid] * 60 * 1000;
        [cal setTimeInMillisWithLong:newTime];
        isOpened = [parser isOpenedForTimeWithJavaUtilCalendar:cal];
        if (isOpened == isOpenedNow)
            imin = imid + 1;
        else
            imax = imid - 1;
    }
    
    int hours, minutes, seconds;
    [OAUtilities getHMS:minutesArr[imid] * 60 hours:&hours minutes:&minutes seconds:&seconds];

    NSMutableString *timeStr = [NSMutableString string];
    if (hours > 0)
        [timeStr appendFormat:@"%d %@", hours, @"h"];
    if (minutes > 0)
        [timeStr appendFormat:@"%@%d %@", (timeStr.length > 0 ? @" " : @""), minutes, @"min"];
    
    return (isOpenedNow ? [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"time_will_close"), timeStr] : [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"time_will_open"), timeStr]);
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
        _openingHoursView.text = [self findOpeningHours];
        
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
