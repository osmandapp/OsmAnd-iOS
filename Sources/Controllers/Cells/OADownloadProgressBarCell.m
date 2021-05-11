//
//  OADownloadProgressBarCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadProgressBarCell.h"

@implementation OADownloadProgressBarCell

+ (NSString *) getCellIdentifier
{
    return @"OADownloadProgressBarCell";
}

- (void) awakeFromNib {
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
