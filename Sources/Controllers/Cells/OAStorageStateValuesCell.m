//
//  OAStorageStateValuesCell.h
//  OsmAnd
//
//  Created by Skalii on 29.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAStorageStateValuesCell.h"

@implementation OAStorageStateValuesCell
{
    NSInteger _totalAvailableValue;
    NSInteger _firstValue;
    NSInteger _secondValue;
    NSInteger _thirdValue;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.firstValueViewWidth.constant = (float) _firstValue / _totalAvailableValue * self.valuesContainerView.frame.size.width;
    self.secondValueViewWidth.constant = (float) _secondValue / _totalAvailableValue * self.valuesContainerView.frame.size.width;
    self.thirdValueViewWidth.constant = (float) _thirdValue / _totalAvailableValue * self.valuesContainerView.frame.size.width;
}

- (void)updateConstraints
{
    BOOL hasDescription = !self.descriptionContainerView.hidden;

    self.valuesWithDescriptionConstraint.active = hasDescription;
    self.valuesNoDescriptionConstraint.active = !hasDescription;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionContainerView.hidden;

        res = res || self.valuesWithDescriptionConstraint.active != hasDescription;
        res = res || self.valuesNoDescriptionConstraint.active != !hasDescription;
    }
    return res;
}

-(void)showDescription:(BOOL)show
{
    self.descriptionContainerView.hidden = !show;
}

-(void)setTotalAvailableValue:(NSInteger)value
{
    _totalAvailableValue = value;
}

-(void)setFirstValue:(NSInteger)value
{
    _firstValue = value;
}

-(void)setSecondValue:(NSInteger)value
{
    _secondValue = value;
}

-(void)setThirdValue:(NSInteger)value
{
    _thirdValue = value;
}

@end
