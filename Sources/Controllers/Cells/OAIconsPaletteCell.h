//
//  OAIconsPaletteCell.h
//  OsmAnd
//
//  Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"

@class OASuperViewController;

@interface OAIconsPaletteCell : OACollectionSingleLineTableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorOffsetViewWidth;
@property (weak, nonatomic) IBOutlet UIStackView *bottomButtonStackView;
@property (weak, nonatomic) IBOutlet UIStackView *descriptionLabelStackView;
@property (weak, nonatomic) IBOutlet UIView *underTitleView;

@property (weak, nonatomic) OASuperViewController *hostVC;

- (void)topButtonVisibility:(BOOL)show;

@end
