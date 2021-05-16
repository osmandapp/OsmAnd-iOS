//
//  OAWebViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 26/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAWebViewCell.h"

@implementation OAWebViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAWebViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _webView.userInteractionEnabled = NO;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
