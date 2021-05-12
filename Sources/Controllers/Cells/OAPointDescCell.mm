//
//  OAPointDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPointDescCell.h"
#import "OAUtilities.h"
#import "Localization.h"

#include "OANativeUtilities.h"
#include <openingHoursParser.h>

@implementation OAPointDescCell

+ (NSString *) getCellIdentifier
{
    return @"OAPointDescCell";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft)
        _descView.textAlignment = NSTextAlignmentLeft;
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
    
    auto parser = OpeningHoursParser::parseOpenedHours([_openingHoursView.text UTF8String]);
    bool isOpenedNow = parser->isOpened();

    NSDate *newTime = [NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 + intervalMinutes * 60];
    bool isOpened = parser->isOpenedForTime([newTime toTm]);
    if (isOpened == isOpenedNow)
        return (isOpenedNow ? OALocalizedString(@"time_open") : OALocalizedString(@"time_closed"));

    int imax = arrLength - 1;
    int imin = 0;
    int imid;
    while (imax >= imin)
    {
        imid = (imin + imax) / 2;
        
        newTime = [NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 + minutesArr[imid] * 60];
        bool isOpened = parser->isOpenedForTime([newTime toTm]);
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
        auto parser = OpeningHoursParser::parseOpenedHours([_openingHoursView.text UTF8String]);
        bool isOpened = parser->isOpened();
        
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

@end
