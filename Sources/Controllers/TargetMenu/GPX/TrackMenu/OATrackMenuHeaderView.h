//
//  OATrackMenuHeaderView.h
//  OsmAnd
//
//  Created by Skalii on 15.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATrackMenuHudViewControllerConstants.h"

@class OASGpxTrackAnalysis, OAButton, OAFoldersCollectionView, OAGPXTableCellData;

@protocol OATrackMenuViewControllerDelegate;

@interface OATrackMenuHeaderView : UIView

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
@property (weak, nonatomic) IBOutlet UIView *gpxActivityContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *gpxActivityIconView;
@property (weak, nonatomic) IBOutlet UILabel *gpxActivityTextView;
@property (weak, nonatomic) IBOutlet UIView *gpxActivitySeparatorView;
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
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionActivityConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionNoActivityConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *activityDirectionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *activityNoDirectionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionNoDirectionNoActivityConstraint;

@property (nonatomic, weak) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (void)updateSelectedTab:(EOATrackMenuHudTab)selectedTab;
- (void)updateHeader:(BOOL)currentTrack
          shownTrack:(BOOL)shownTrack
      isNetworkRoute:(BOOL)isNetworkRoute
           routeIcon:(UIImage *)icon
               title:(NSString *)title
         nearestCity:(NSString *)nearestCity;
- (void)updateGpxActivityContainerView;

+ (NSMutableArray<OAGPXTableCellData *> *)generateGpxBlockStatistics:(OASGpxTrackAnalysis *)analysis withoutGaps:(BOOL)withoutGaps;
- (void)generateGpxBlockStatistics:(OASGpxTrackAnalysis *)analysis
                       withoutGaps:(BOOL)withoutGaps;

- (void)setDirection:(NSString *)direction;
- (void)setDescription;
- (void)setStatisticsCollection:(NSArray<OAGPXTableCellData *> *)cells;
- (void)setSelectedIndexGroupsCollection:(NSInteger)index;
- (void)setGroupsCollection:(NSArray<NSDictionary *> *)data withSelectedIndex:(NSInteger)index;

- (void)updateFrame:(CGFloat)width;
- (CGFloat)getInitialHeight:(CGFloat)additionalHeight;

+ (CGSize)getSizeForItem:(NSString *)title value:(NSString *)value isLast:(BOOL)isLast;

@end
