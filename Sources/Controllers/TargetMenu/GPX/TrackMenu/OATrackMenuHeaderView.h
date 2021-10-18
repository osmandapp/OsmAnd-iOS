//
//  OATrackMenuHeaderView.h
//  OsmAnd
//
//  Created by Skalii on 15.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAGPXDocument, OAGPXTrackAnalysis, OAButton;

@interface OATrackMenuHeaderView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIView *titleContainerView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;

@property (weak, nonatomic) IBOutlet UIView *descriptionContainerView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UIView *locationContainerView;
@property (weak, nonatomic) IBOutlet UIView *directionContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *directionIconView;
@property (weak, nonatomic) IBOutlet UILabel *directionTextView;
@property (weak, nonatomic) IBOutlet UIView *locationSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *regionContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *regionIconView;
@property (weak, nonatomic) IBOutlet UILabel *regionTextView;

@property (weak, nonatomic) IBOutlet UIStackView *actionButtonsContainerView;
@property (weak, nonatomic) IBOutlet OAButton *showHideButton;
@property (weak, nonatomic) IBOutlet OAButton *appearanceButton;
@property (weak, nonatomic) IBOutlet OAButton *exportButton;
@property (weak, nonatomic) IBOutlet OAButton *navigationButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomDescriptionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomNoDescriptionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomNoDescriptionNoCollectionConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomCollectionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomNoCollectionConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *onlyTitleAndDescriptionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *onlyTitleNoDescriptionConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionDirectionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionNoDirectionConstraint;

- (void)updateFrame;

- (void)setDirection:(NSString *)direction;
- (void)setDescription:(NSString *)description;
- (void)setCollection:(NSArray *)data;
- (void)makeOnlyHeader:(BOOL)hasDescription;
- (void)showLocation:(BOOL)show;

@end
