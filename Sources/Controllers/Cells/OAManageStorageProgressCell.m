//
//  OAManageStorageProgressCell.h
//  OsmAnd
//
//  Created by Skalii on 29.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAManageStorageProgressCell.h"

@implementation OAManageStorageProgressCell
{
    NSInteger _totalProgress;
    NSInteger _firstProgress;
    NSInteger _secondProgress;
    NSInteger _thirdProgress;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.progressFirstViewWidth.constant = (float) _firstProgress / _totalProgress * self.progressContainerView.frame.size.width;
    self.progressSecondViewWidth.constant = (float) _secondProgress / _totalProgress * self.progressContainerView.frame.size.width;
    self.progressThirdViewWidth.constant = (float) _thirdProgress / _totalProgress * self.progressContainerView.frame.size.width;
}

- (void)updateConstraints
{
    BOOL hasDescription = !self.descriptionContainerView.hidden;

    self.progressWithDescriptionConstraint.active = hasDescription;
    self.progressNoDescriptionConstraint.active = !hasDescription;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionContainerView.hidden;

        res = res || self.progressWithDescriptionConstraint.active != hasDescription;
        res = res || self.progressNoDescriptionConstraint.active != !hasDescription;
    }
    return res;
}

-(void)showDescription:(BOOL)show
{
    self.descriptionContainerView.hidden = !show;
}

-(void)setTotalProgress:(NSInteger)progress
{
    _totalProgress = progress;
}

-(void)setFirstProgress:(NSInteger)progress
{
    _firstProgress = progress;
}

-(void)setSecondProgress:(NSInteger)progress
{
    _secondProgress = progress;
}

-(void)setThirdProgress:(NSInteger)progress
{
    _thirdProgress = progress;
}

@end
