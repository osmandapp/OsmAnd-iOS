//
//  OAValueTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OAValueTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIButton *proButton;

- (void)valueVisibility:(BOOL)show;
- (void)showProButton:(BOOL)show;
- (void)setActiveTitleWidthGreaterThanEqualConstraint:(BOOL)active;
- (void)setActiveTitleWidthEqualConstraint:(BOOL)active;
- (void)setTitleWidthEqualConstraintValue:(CGFloat)value;

@end
