//
//  OAStorageStateValuesCell.h
//  OsmAnd
//
//  Created by Skalii on 29.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAStorageStateValuesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *valuesContainerView;
@property (weak, nonatomic) IBOutlet UIView *firstValueView;
@property (weak, nonatomic) IBOutlet UIView *secondValueView;
@property (weak, nonatomic) IBOutlet UIView *thirdValueView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *firstValueViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *secondValueViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *thirdValueViewWidth;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *valuesWithDescriptionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *valuesNoDescriptionConstraint;

@property (weak, nonatomic) IBOutlet UIView *descriptionContainerView;
@property (weak, nonatomic) IBOutlet UIView *firstValueDescriptionView;
@property (weak, nonatomic) IBOutlet UILabel *firstDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *secondValueDescriptionView;
@property (weak, nonatomic) IBOutlet UILabel *secondDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *thirdValueDescriptionView;
@property (weak, nonatomic) IBOutlet UILabel *thirdDescriptionLabel;

- (void)showDescription:(BOOL)show;

- (void)setTotalAvailableValue:(NSInteger)value;
- (void)setFirstValue:(NSInteger)value;
- (void)setSecondValue:(NSInteger)value;
- (void)setThirdValue:(NSInteger)value;

@end
