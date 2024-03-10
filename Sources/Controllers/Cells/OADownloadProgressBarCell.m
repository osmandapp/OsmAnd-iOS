//
//  OADownloadProgressBarCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadProgressBarCell.h"

@interface OADownloadProgressBarCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressBarViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressStatusLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressValueLabelTopConstraint;

@end

@implementation OADownloadProgressBarCell

- (void) awakeFromNib {
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)updateConstraints
{
    BOOL hasStatus = !self.progressStatusLabel.hidden;
    BOOL hasValue = !self.progressValueLabel.hidden;
    
    if (!hasStatus && !hasValue)
    {
        self.progressBarViewBottomConstraint.active = YES;
        self.progressStatusLabelTopConstraint.active = NO;
        self.progressValueLabelTopConstraint.active = NO;
    }
    else
    {
        self.progressBarViewBottomConstraint.active = NO;
        self.progressStatusLabelTopConstraint.active = YES;
        self.progressValueLabelTopConstraint.active = YES;
    }

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasStatus = !self.progressStatusLabel.hidden;
        BOOL hasValue = !self.progressValueLabel.hidden;

        res = res || self.progressStatusLabelTopConstraint.active != hasStatus;
        res = res || self.progressValueLabelTopConstraint.active != !hasValue;
    }
    return res;
}

- (void)showLabels:(BOOL)show
{
    self.progressStatusLabel.hidden = !show;
    self.progressValueLabel.hidden = !show;
}

@end
