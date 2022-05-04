//
//  OATrackMenuHeaderView.h
//  OsmAnd
//
//  Created by Skalii on 15.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATrackMenuHudViewController.h"

@class OAGPX, OAGPXDocument, OAGPXTrackAnalysis;
@class OAButton, OAFoldersCollectionView;

@protocol OATrackMenuViewControllerDelegate;

@interface OATrackMenuHeaderView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIView *sliderView;

@property (weak, nonatomic) IBOutlet UIView *titleContainerView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;

@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (weak, nonatomic) IBOutlet UICollectionView *statisticsCollectionView;
@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *groupsCollectionView;

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

@property (weak, nonatomic) IBOutlet UIView *bottomDividerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *locationWithStatisticsTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionDirectionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionNoDirectionConstraint;

@property (nonatomic, weak) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (void)updateSelectedTab:(EOATrackMenuHudTab)selectedTab;
- (void)updateHeader:(BOOL)currentTrack
          shownTrack:(BOOL)shownTrack
               title:(NSString *)title;

- (void)generateGpxBlockStatistics:(OAGPXTrackAnalysis *)analysis
                       withoutGaps:(BOOL)withoutGaps;

- (void)setDirection:(NSString *)direction;
- (void)setDescription;
- (void)setStatisticsCollection:(NSArray<OAGPXTableCellData *> *)cells;
- (void)setSelectedIndexGroupsCollection:(NSInteger)index;
- (void)setGroupsCollection:(NSArray<NSDictionary *> *)data withSelectedIndex:(NSInteger)index;

- (void)updateFrame:(CGFloat)width;
- (CGFloat)getInitialHeight:(CGFloat)additionalHeight;

@end
