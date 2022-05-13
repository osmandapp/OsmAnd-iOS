//
//  OATrackMenuHeaderView.mm
//  OsmAnd
//
//  Created by Skalii on 15.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHeaderView.h"
#import "OAFoldersCollectionView.h"
#import "OAGpxStatBlockCollectionViewCell.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXTrackAnalysis.h"
#import "OAWikiArticleHelper.h"

#define kTitleHeightMax 44.
#define kTitleHeightMin 30.
#define kDescriptionHeightMin 18.
#define kDescriptionHeightMax 36.
#define kBlockStatisticsLineHeight 20.
#define kBlockStatisticsHeight 40.
#define kBlockStatisticsWidthMin 80.
#define kBlockStatisticsWidthMinByValue 52.
#define kBlockStatisticsWidthMax 120.
#define kBlockStatisticsWidthMaxByValue 92.
#define kBlockStatisticsDivider 13.

@interface OATrackMenuHeaderView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation OATrackMenuHeaderView
{
    NSArray<OAGPXTableCellData *> *_statisticsCells;
    EOATrackMenuHudTab _selectedTab;
    OsmAndAppInstance _app;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self)
        {
            [self commonInit];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self)
        {
            self.frame = frame;
            [self commonInit];
        }
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.statisticsCollectionView.delegate = self;
    self.statisticsCollectionView.dataSource = self;
    [self.statisticsCollectionView registerNib:[UINib nibWithNibName:[OAGpxStatBlockCollectionViewCell getCellIdentifier] bundle:nil]
                    forCellWithReuseIdentifier:[OAGpxStatBlockCollectionViewCell getCellIdentifier]];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
}

- (void)updateConstraints
{
    BOOL hasStatistics = !self.statisticsCollectionView.hidden;
    BOOL hasLocation = !self.locationContainerView.hidden;
    BOOL hasDirection = !self.directionContainerView.hidden;

    self.locationWithStatisticsTopConstraint.active = hasLocation && hasStatistics;
    self.regionDirectionConstraint.active = hasDirection;
    self.regionNoDirectionConstraint.active = !hasDirection;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasStatistics = !self.statisticsCollectionView.hidden;
        BOOL hasLocation = !self.locationContainerView.hidden;
        BOOL hasDirection = !self.directionContainerView.hidden;

        res = res || self.locationWithStatisticsTopConstraint.active != (hasLocation && hasStatistics);
        res = res || self.regionDirectionConstraint.active != hasDirection;
        res = res || self.regionNoDirectionConstraint.active != !hasDirection;
    }
    return res;
}

- (void)updateSelectedTab:(EOATrackMenuHudTab)selectedTab
{
    _selectedTab = selectedTab;
}

- (void)updateHeader:(BOOL)currentTrack
          shownTrack:(BOOL)shownTrack
               title:(NSString *)title
{
    self.backgroundColor = _selectedTab != EOATrackMenuHudActionsTab
            ? UIColor.whiteColor : UIColorFromRGB(color_bottom_sheet_background);

    self.bottomDividerView.hidden = _selectedTab == EOATrackMenuHudSegmentsTab || _selectedTab == EOATrackMenuHudPointsTab;

    if (_selectedTab != EOATrackMenuHudActionsTab)
    {
        [self.titleView setText:currentTrack ? OALocalizedString(@"track_recording_name") : title];
        self.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
        self.titleIconView.tintColor = UIColorFromRGB(color_icon_inactive);
    }

    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        CLLocationCoordinate2D gpxLocation = self.trackMenuDelegate ? [self.trackMenuDelegate getCenterGpxLocation] : kCLLocationCoordinate2DInvalid;

        CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
        NSString *direction = lastKnownLocation && gpxLocation.latitude != DBL_MAX ?
                [OAOsmAndFormatter getFormattedDistance:getDistance(
                        lastKnownLocation.coordinate.latitude, lastKnownLocation.coordinate.longitude,
                        gpxLocation.latitude, gpxLocation.longitude)] : @"";
        [self setDirection:direction];

        if (!self.directionContainerView.hidden)
        {
            self.directionIconView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            self.directionIconView.tintColor = UIColorFromRGB(color_primary_purple);
            self.directionTextView.textColor = UIColorFromRGB(color_primary_purple);
        }

        if (gpxLocation.latitude != DBL_MAX)
        {
            OAWorldRegion *worldRegion = [_app.worldRegion findAtLat:gpxLocation.latitude
                                                                 lon:gpxLocation.longitude];
            self.regionIconView.image = [UIImage templateImageNamed:@"ic_small_map_point"];
            self.regionIconView.tintColor = UIColorFromRGB(color_tint_gray);
            [self.regionTextView setText:worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName];
            self.regionTextView.textColor = UIColorFromRGB(color_text_footer);
        }
        else
        {
            [self showLocation:NO];
        }

        [self updateShowHideButton:shownTrack];
        [self.showHideButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [self.showHideButton addTarget:self
                                action:@selector(onShowHidePressed:)
                      forControlEvents:UIControlEventTouchUpInside];

        [self.appearanceButton setTitle:OALocalizedString(@"map_settings_appearance")
                               forState:UIControlStateNormal];
        [self.appearanceButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [self.appearanceButton addTarget:self
                                  action:@selector(onAppearancePressed:)
                        forControlEvents:UIControlEventTouchUpInside];

        if (!currentTrack)
        {
            [self.exportButton setTitle:OALocalizedString(@"shared_string_export") forState:UIControlStateNormal];
            [self.exportButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [self.exportButton addTarget:self action:@selector(onExportPressed:)
                               forControlEvents:UIControlEventTouchUpInside];

            [self.navigationButton setTitle:OALocalizedString(@"routing_settings") forState:UIControlStateNormal];
            [self.navigationButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [self.navigationButton addTarget:self action:@selector(onNavigationPressed:)
                                   forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            self.exportButton.hidden = YES;
            self.navigationButton.hidden = YES;
        }
    }
    else if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        [self.titleView setText:OALocalizedString(@"actions")];
        self.titleIconView.image = nil;
        [self makeOnlyHeader:NO];
    }
    else
    {
        [self makeOnlyHeader:YES];
    }

    self.groupsCollectionView.hidden = _selectedTab != EOATrackMenuHudPointsTab || ![self.groupsCollectionView hasValues];

    [self updateFrame:self.frame.size.width];

    if ([self needsUpdateConstraints])
        [self updateConstraints];
}

- (void)generateGpxBlockStatistics:(OAGPXTrackAnalysis *)analysis
                       withoutGaps:(BOOL)withoutGaps
{
    NSMutableArray<OAGPXTableCellData *> *statisticCells = [NSMutableArray array];
    if (analysis)
    {
        if (analysis.totalDistance != 0)
        {
            float totalDistance = withoutGaps ? analysis.totalDistanceWithoutGaps : analysis.totalDistance;
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedDistance:totalDistance],
                            @"int_value": @(EOARouteStatisticsModeAltitude)
                    },
                    kCellTitle: OALocalizedString(@"shared_string_distance"),
                    kCellRightIconName: @"ic_small_distance"
            }]];
        }

        if (analysis.hasElevationData)
        {
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationUp],
                            @"int_value": @(EOARouteStatisticsModeSlope)
                    },
                    kCellTitle: OALocalizedString(@"altitude_ascent"),
                    kCellRightIconName: @"ic_small_ascent"
            }]];
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationDown],
                            @"int_value": @(EOARouteStatisticsModeSlope)
                    },
                    kCellTitle: OALocalizedString(@"altitude_descent"),
                    kCellRightIconName: @"ic_small_descent"
            }]];
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues:@{
                            @"string_value": [NSString stringWithFormat:@"%@ - %@",
                                                                        [OAOsmAndFormatter getFormattedAlt:analysis.minElevation],
                                                                        [OAOsmAndFormatter getFormattedAlt:analysis.maxElevation]],
                            @"int_value": @(EOARouteStatisticsModeAltitude)
                    },
                    kCellTitle: OALocalizedString(@"gpx_alt_range"),
                    kCellRightIconName: @"ic_small_altitude_range"
            }]];
        }

        if ([analysis isSpeedSpecified])
        {
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedSpeed:analysis.avgSpeed],
                            @"int_value": @(EOARouteStatisticsModeSpeed)
                    },
                    kCellTitle: OALocalizedString(@"gpx_average_speed"),
                    kCellRightIconName: @"ic_small_speed"
            }]];
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedSpeed:analysis.maxSpeed],
                            @"int_value": @(EOARouteStatisticsModeSpeed)
                    },
                    kCellTitle: OALocalizedString(@"gpx_max_speed"),
                    kCellRightIconName: @"ic_small_max_speed"
            }]];
        }

        if (analysis.hasSpeedData)
        {
            long timeSpan = withoutGaps ? analysis.timeSpanWithoutGaps : analysis.timeSpan;
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedTimeInterval:timeSpan shortFormat:YES],
                            @"int_value": @(EOARouteStatisticsModeSpeed)
                    },
                    kCellTitle: OALocalizedString(@"total_time"),
                    kCellRightIconName: @"ic_small_time_interval"
            }]];
        }

        if (analysis.isTimeMoving)
        {
            long timeMoving = withoutGaps ? analysis.timeMovingWithoutGaps : analysis.timeMoving;
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedTimeInterval:timeMoving shortFormat:YES],
                            @"int_value": @(EOARouteStatisticsModeSpeed)
                    },
                    kCellTitle: OALocalizedString(@"moving_time"),
                    kCellRightIconName: @"ic_small_time_moving"
            }]];
        }
    }
    [self setStatisticsCollection:statisticCells];
}

- (void)updateShowHideButton:(BOOL)shownTrack
{
    [UIView transitionWithView:self.showHideButton
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:^(void) {
                        [self.showHideButton setTitle:shownTrack
                                        ? OALocalizedString(@"poi_hide") : OALocalizedString(@"sett_show")
                                             forState:UIControlStateNormal];
                        [self.showHideButton setImage:[UIImage templateImageNamed:shownTrack
                                        ? @"ic_custom_hide" : @"ic_custom_show"]
                                             forState:UIControlStateNormal];
                    }
                    completion:nil];
}

- (void)updateFrame:(CGFloat)width
{
    CGFloat leftSafeMargin = [OAUtilities getLeftMargin];
    CGFloat leftMargin = 20. + leftSafeMargin;
    CGFloat contentMargin = 20. * 2 + leftSafeMargin;

    CGRect headerFrame = CGRectMake(0., 0., width, 0.);

    headerFrame.size.height += 6.;
    headerFrame.size.height += self.sliderView.frame.size.height;
    headerFrame.size.height += 6.;

    CGRect titleFrame = CGRectMake([self isDirectionRTL] ? 46. : 0., 0., headerFrame.size.width - (contentMargin + 46.), 0.);
    CGSize titleSize = [OAUtilities calculateTextBounds:self.titleView.text
                                                  width:titleFrame.size.width
                                                 height:kTitleHeightMax
                                                   font:self.titleView.font
                                             singleLine:NO];
    titleSize.height = (titleSize.width > titleFrame.size.width) || (titleSize.height > kTitleHeightMin)
            ? kTitleHeightMax
            : kTitleHeightMin;
    titleFrame.size.height = titleSize.height;
    self.titleView.frame = titleFrame;
    self.titleIconView.frame = CGRectMake(
            [self isDirectionRTL] ? 0. : titleFrame.size.width + 16.,
            (titleSize.height - 30.) / 2,
            30.,
            30.
    );

    CGRect titleCollectionFrame = CGRectMake(leftMargin, headerFrame.size.height, headerFrame.size.width - contentMargin, titleSize.height);
    self.titleContainerView.frame = titleCollectionFrame;
    headerFrame.size.height += self.titleContainerView.frame.size.height;

    if (self.descriptionView.hidden && self.statisticsCollectionView.hidden
            && self.locationContainerView.hidden && !self.actionButtonsContainerView.hidden)
        headerFrame.size.height += 16.;

    CGFloat descriptionHeight = [OAUtilities calculateTextBounds:self.descriptionView.text
                                                           width:headerFrame.size.width - contentMargin
                                                          height:kDescriptionHeightMax
                                                            font:self.descriptionView.font
                                                      singleLine:NO].height;
    descriptionHeight = descriptionHeight > kDescriptionHeightMin ? kDescriptionHeightMax : kDescriptionHeightMin;
    CGRect descriptionFrame = CGRectMake(leftMargin, headerFrame.size.height, headerFrame.size.width - contentMargin, descriptionHeight);
    if (!self.descriptionView.hidden)
        descriptionFrame.origin.y = titleCollectionFrame.origin.y + titleCollectionFrame.size.height + (_selectedTab == EOATrackMenuHudOverviewTab ? 8. : 2.);
    self.descriptionView.frame = descriptionFrame;
    headerFrame.size.height += !self.descriptionView.hidden
            ? self.descriptionView.frame.size.height + (_selectedTab == EOATrackMenuHudOverviewTab ? 8. : 2.)
            : 0.;

    CGRect statisticsCollectionFrame = CGRectMake(0., headerFrame.size.height + 2., headerFrame.size.width, self.statisticsCollectionView.frame.size.height);
    self.statisticsCollectionView.frame = statisticsCollectionFrame;
    headerFrame.size.height += !self.statisticsCollectionView.hidden ? self.statisticsCollectionView.frame.size.height + 2. : 0.;

    if (!self.groupsCollectionView.hidden)
        headerFrame.size.height += 6.;
    CGRect groupsCollectionFrame = CGRectMake(0., headerFrame.size.height, headerFrame.size.width, self.groupsCollectionView.frame.size.height);
    self.groupsCollectionView.frame = groupsCollectionFrame;
    headerFrame.size.height += !self.groupsCollectionView.hidden ? self.groupsCollectionView.frame.size.height : 0.;

    if (!self.locationContainerView.hidden && self.statisticsCollectionView.hidden)
        headerFrame.size.height += 10.;

    CGRect locationFrame = CGRectMake(
            leftMargin,
            headerFrame.size.height,
            headerFrame.size.width - contentMargin,
            self.locationContainerView.frame.size.height
    );
    self.locationContainerView.frame = locationFrame;
    headerFrame.size.height += !self.locationContainerView.hidden ? self.locationContainerView.frame.size.height + 10. : 0.;

    CGRect actionButtonsFrame = CGRectMake(
            16. + leftSafeMargin,
            headerFrame.size.height,
            headerFrame.size.width - (32. + leftSafeMargin),
            self.actionButtonsContainerView.frame.size.height
    );
    self.actionButtonsContainerView.frame = actionButtonsFrame;
    headerFrame.size.height += !self.actionButtonsContainerView.hidden ? self.actionButtonsContainerView.frame.size.height : 0.;

    headerFrame.size.height += !self.groupsCollectionView.hidden ? 6. : 16.;

    self.frame = headerFrame;
}

- (void)setDirection:(NSString *)direction
{
    BOOL hasDirection = direction && direction.length > 0;

    [self.directionTextView setText:direction];
    self.directionContainerView.hidden = !hasDirection;
    self.locationSeparatorView.hidden = !hasDirection;
}

- (void)setDescription
{
    NSString *description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";
    if (_selectedTab == EOATrackMenuHudOverviewTab)
        description = [OAWikiArticleHelper getFirstParagraph:description];

    BOOL hasDescription = description && description.length > 0;

    [self.descriptionView setText:description];
    self.descriptionView.hidden = !hasDescription;
}

- (void)setStatisticsCollection:(NSArray<OAGPXTableCellData *> *)cells
{
    BOOL hasData = cells && cells.count > 0;

    _statisticsCells = cells;
    [self.statisticsCollectionView reloadData];
    self.statisticsCollectionView.hidden = !hasData;
}

- (void)setSelectedIndexGroupsCollection:(NSInteger)index
{
    [self.groupsCollectionView setSelectedIndex:index];
    [self.groupsCollectionView reloadData];
}

- (void)setGroupsCollection:(NSArray<NSDictionary *> *)data withSelectedIndex:(NSInteger)index
{
    [self.groupsCollectionView setValues:data withSelectedIndex:index];
    [self.groupsCollectionView reloadData];
    self.groupsCollectionView.hidden = ![self.groupsCollectionView hasValues];
}

- (CGFloat)getInitialHeight:(CGFloat)additionalHeight
{
    CGFloat height = additionalHeight;
    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        height += (!self.descriptionView.hidden
                ? (self.descriptionView.frame.origin.y + self.descriptionView.frame.size.height)
                : (self.titleContainerView.frame.origin.y + self.titleContainerView.frame.size.height));

        if (!self.statisticsCollectionView.hidden || !self.groupsCollectionView.hidden)
            height += 12.;
        else if (!self.locationContainerView.hidden)
            height += 10.;
        else
            height += 16.;
    }
    else
    {
        height += self.frame.size.height;
    }

    return height;
}

- (void)makeOnlyHeader:(BOOL)hasDescription
{
    self.descriptionView.hidden = !hasDescription;
    self.statisticsCollectionView.hidden = YES;
    self.locationContainerView.hidden = YES;
    self.actionButtonsContainerView.hidden = YES;
}

- (void)showLocation:(BOOL)show
{
    self.locationContainerView.hidden = !show;
}

#pragma mark - Selectors

- (void)onShowHidePressed:(id)sender
{
    if (self.trackMenuDelegate)
        [self updateShowHideButton:[self.trackMenuDelegate changeTrackVisible]];
}

- (void)onAppearancePressed:(id)sender
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate openAppearance];
}

- (void)onExportPressed:(id)sender
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate openExport];
}

- (void)onNavigationPressed:(id)sender
{
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate openNavigation];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _statisticsCells.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                   cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = _statisticsCells[indexPath.row];
    OAGpxStatBlockCollectionViewCell *cell =
            [collectionView dequeueReusableCellWithReuseIdentifier:[OAGpxStatBlockCollectionViewCell getCellIdentifier]
                    forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAGpxStatBlockCollectionViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = nib[0];
    }
    if (cell)
    {
        [cell.valueView setText:cellData.values[@"string_value"]];
        cell.iconView.image = [UIImage templateImageNamed:cellData.rightIconName];
        cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        [cell.titleView setText:cellData.title];

        cell.separatorView.hidden = [cell isDirectionRTL]
                ? (indexPath.row == 0)
                : (indexPath.row == [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1);

        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = _statisticsCells[indexPath.row];
    BOOL isLast = indexPath.row == [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1;
    return [self getSizeForItem:cellData.title value:cellData.values[@"string_value"] isLast:isLast];
}

- (CGSize)getSizeForItem:(NSString *)title value:(NSString *)value isLast:(BOOL)isLast
{
    CGSize sizeByTitle = [OAUtilities calculateTextBounds:title
                                                    width:kBlockStatisticsWidthMax
                                                   height:kBlockStatisticsLineHeight
                                                     font:[UIFont systemFontOfSize:13. weight:UIFontWeightRegular]
                                                 singleLine:YES];
    CGSize sizeByValue = [OAUtilities calculateTextBounds:value
                                                    width:kBlockStatisticsWidthMaxByValue
                                                   height:kBlockStatisticsLineHeight
                                                     font:[UIFont systemFontOfSize:13. weight:UIFontWeightMedium]
                                                 singleLine:YES];
    CGFloat widthByTitle = sizeByTitle.width < kBlockStatisticsWidthMin
            ? kBlockStatisticsWidthMin : sizeByTitle.width > kBlockStatisticsWidthMax
                    ? kBlockStatisticsWidthMax : sizeByTitle.width;
    CGFloat widthByValue = (sizeByValue.width < kBlockStatisticsWidthMinByValue
            ? kBlockStatisticsWidthMinByValue : sizeByValue.width > kBlockStatisticsWidthMaxByValue
                    ? kBlockStatisticsWidthMaxByValue : sizeByValue.width)
                            + kBlockStatisticsWidthMax - kBlockStatisticsWidthMaxByValue;
    if (!isLast)
    {
        widthByTitle += kBlockStatisticsDivider;
        widthByValue += kBlockStatisticsDivider;
    }
    return CGSizeMake(MAX(widthByTitle, widthByValue), kBlockStatisticsHeight);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = _statisticsCells[indexPath.row];
    EOARouteStatisticsMode modeType = (EOARouteStatisticsMode) [cellData.values[@"int_value"] intValue];
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate openAnalysis:modeType];
}

@end
