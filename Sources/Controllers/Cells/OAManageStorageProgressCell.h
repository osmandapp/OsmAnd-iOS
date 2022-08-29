//
//  OAManageStorageProgressCell.h
//  OsmAnd
//
//  Created by Skalii on 29.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAManageStorageProgressCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *progressContainerView;
@property (weak, nonatomic) IBOutlet UIView *progressFirstView;
@property (weak, nonatomic) IBOutlet UIView *progressSecondView;
@property (weak, nonatomic) IBOutlet UIView *progressThirdView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progressFirstViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progressSecondViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progressThirdViewWidth;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progressWithDescriptionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progressNoDescriptionConstraint;

@property (weak, nonatomic) IBOutlet UIView *descriptionContainerView;
@property (weak, nonatomic) IBOutlet UIView *progressFirstDescriptionView;
@property (weak, nonatomic) IBOutlet UILabel *firstDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *progressSecondDescriptionView;
@property (weak, nonatomic) IBOutlet UILabel *secondDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *progressThirdDescriptionView;
@property (weak, nonatomic) IBOutlet UILabel *thirdDescriptionLabel;

-(void)showDescription:(BOOL)show;

-(void)setTotalProgress:(NSInteger)progress;
-(void)setFirstProgress:(NSInteger)progress;
-(void)setSecondProgress:(NSInteger)progress;
-(void)setThirdProgress:(NSInteger)progress;

@end
