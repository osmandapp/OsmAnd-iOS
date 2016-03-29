//
//  OAPointDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPointDescCell.h"
#import "OAUtilities.h"
#import "OAOpeningHoursParser.h"
#import "Localization.h"

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
    
    OAOpeningHoursParser *parser = [[OAOpeningHoursParser alloc] initWithOpeningHours:_openingHoursView.text];
    BOOL isOpenedNow = [parser isOpenedForTime:[NSDate date]];

    NSDate *newTime = [NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 + intervalMinutes * 60];
    BOOL isOpened = [parser isOpenedForTime:newTime];
    if (isOpened == isOpenedNow)
        return (isOpenedNow ? OALocalizedString(@"time_open") : OALocalizedString(@"time_closed"));

    int imax = arrLength - 1;
    int imin = 0;
    int imid;
    while (imax >= imin)
    {
        imid = (imin + imax) / 2;
        
        newTime = [NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 + minutesArr[imid] * 60];
        BOOL isOpened = [parser isOpenedForTime:newTime];
        if (isOpened == isOpenedNow)
            imin = imid + 1;
        else
            imax = imid - 1;
    }
    
    int hours, minutes, seconds;
    [OAUtilities getHMS:minutesArr[imid] * 60 hours:&hours minutes:&minutes seconds:&seconds];

    NSMutableString *timeStr = [NSMutableString string];
    if (hours > 0)
        [timeStr appendFormat:@"%d %@", hours, OALocalizedString(@"units_hour")];
    if (minutes > 0)
        [timeStr appendFormat:@"%@%d %@", (timeStr.length > 0 ? @" " : @""), minutes, OALocalizedString(@"units_min")];
    
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
        OAOpeningHoursParser *parser = [[OAOpeningHoursParser alloc] initWithOpeningHours:_openingHoursView.text];
        BOOL isOpened = [parser isOpenedForTime:[NSDate date]];
        
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
