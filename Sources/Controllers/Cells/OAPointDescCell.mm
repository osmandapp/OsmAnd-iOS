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
#import "OANativeUtilities.h"
#import "OAPOIHelper.h"

@implementation OAPointDescCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft)
        _descView.textAlignment = NSTextAlignmentLeft;
    self.titleView.font = [UIFont scaledSystemFontOfSize:14.];
}

- (void) updateOpeningTimeInfo:(OAPOI *)poi
{
    if (_openingHoursView.text.length == 0)
    {
        _timeIcon.hidden = YES;
        _openingHoursView.hidden = YES;
    }
    else
    {
        auto parser = OpeningHoursParser::parseOpenedHours([_openingHoursView.text UTF8String]);
        if (!parser)
        {
            _timeIcon.hidden = YES;
            _openingHoursView.hidden = YES;
            return;
        }
        bool isOpened = parser->isOpened();
        
        UIColor *color;
        if (isOpened)
            color = UIColorFromRGB(0x32DA3A);
        else
            color = UIColorFromRGB(0xDA3A3A);
        
        _timeIcon.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_small_time"] color:color];
        
        _openingHoursView.textColor = color;
        _openingHoursView.text = [[OAPOIHelper sharedInstance] getOpeningHoursStatusChange:poi];
        
        _timeIcon.hidden = NO;
        _openingHoursView.hidden = NO;
    }
    
}

@end
