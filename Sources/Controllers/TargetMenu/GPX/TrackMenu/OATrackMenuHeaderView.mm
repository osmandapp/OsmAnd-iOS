//
//  OATrackMenuHeaderView.mm
//  OsmAnd
//
//  Created by Skalii on 15.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHeaderView.h"
#import "OAGpxStatBlockCollectionViewCell.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXTrackAnalysis.h"

#define kBlockStatistickHeight 40.
#define kBlockStatistickWidthMin 80.
#define kBlockStatistickWidthMinByValue 60.
#define kBlockStatistickWidthMax 120.
#define kBlockStatistickWidthMaxByValue 100.
#define kBlockStatistickDivider 13.

@implementation OATrackMenuHeaderView
{
    NSArray<OAGPXTableCellData *> *_collectionData;
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

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAGpxStatBlockCollectionViewCell getCellIdentifier] bundle:nil]
          forCellWithReuseIdentifier:[OAGpxStatBlockCollectionViewCell getCellIdentifier]];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)updateConstraints
{
    BOOL hasDescription = !self.descriptionContainerView.hidden;
    BOOL hasCollection = !self.collectionView.hidden;
    BOOL hasContent = hasCollection || !self.locationContainerView.hidden || !self.actionButtonsContainerView.hidden;
    BOOL isOnlyTitleAndDescription = hasDescription && !hasContent;
    BOOL isOnlyTitle = !hasDescription && !hasContent;
    BOOL hasDirection = !self.directionContainerView.hidden;

    self.onlyTitleAndDescriptionConstraint.active = isOnlyTitleAndDescription;
    self.onlyTitleNoDescriptionConstraint.active = isOnlyTitle;

    self.titleBottomDescriptionConstraint.active = hasDescription;
    self.titleBottomNoDescriptionConstraint.active = !hasDescription && hasCollection;
    self.titleBottomNoDescriptionNoCollectionConstraint.active =
            !hasDescription && !hasCollection && !isOnlyTitleAndDescription && !isOnlyTitle;

    self.descriptionBottomCollectionConstraint.active = hasCollection;
    self.descriptionBottomNoCollectionConstraint.active = !hasCollection;

    self.regionDirectionConstraint.active = hasDirection;
    self.regionNoDirectionConstraint.active = !hasDirection;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionContainerView.hidden;
        BOOL hasCollection = !self.collectionView.hidden;
        BOOL hasContent = hasCollection || !self.locationContainerView.hidden || !self.actionButtonsContainerView.hidden;
        BOOL isOnlyTitleAndDescription = hasDescription && !hasContent;
        BOOL isOnlyTitle = !hasDescription && !hasContent;
        BOOL hasDirection = !self.directionContainerView.hidden;

        res = res || self.onlyTitleAndDescriptionConstraint.active != isOnlyTitleAndDescription;
        res = res || self.onlyTitleNoDescriptionConstraint.active != isOnlyTitle;

        res = res || self.titleBottomDescriptionConstraint.active != hasDescription;
        res = res || self.titleBottomNoDescriptionConstraint.active != !hasDescription && hasCollection;
        res = res || self.titleBottomNoDescriptionNoCollectionConstraint.active !=
                !hasDescription && !hasCollection && !isOnlyTitleAndDescription && !isOnlyTitle;

        res = res || self.descriptionBottomCollectionConstraint.active != hasDescription && hasCollection;
        res = res || self.descriptionBottomNoCollectionConstraint.active != hasDescription && !hasCollection;

        res = res || self.regionDirectionConstraint.active != hasDirection;
        res = res || self.regionNoDirectionConstraint.active != !hasDirection;
    }
    return res;
}

- (void)updateHeader:(EOATrackMenuHudTab)selectedTab
        currentTrack:(BOOL)currentTrack
          shownTrack:(BOOL)shownTrack
               title:(NSString *)title
{
    _selectedTab = selectedTab;

    self.backgroundColor = _selectedTab == EOATrackMenuHudOverviewTab || _selectedTab == EOATrackMenuHudSegmentsTab
            ? UIColor.whiteColor : UIColorFromRGB(color_bottom_sheet_background);

    self.bottomDividerView.hidden = _selectedTab == EOATrackMenuHudSegmentsTab;

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

    if ([self needsUpdateConstraints])
        [self updateConstraints];

    [self updateFrame];
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
                    kCellTitle: OALocalizedString(@"gpx_ascent"),
                    kCellRightIconName: @"ic_small_ascent"
            }]];
            [statisticCells addObject:[OAGPXTableCellData withData:@{
                    kTableValues: @{
                            @"string_value": [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationDown],
                            @"int_value": @(EOARouteStatisticsModeSlope)
                    },
                    kCellTitle: OALocalizedString(@"gpx_descent"),
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
    [self setCollection:statisticCells];
}

- (void)updateShowHideButton:(BOOL)shownTrack
{
    [self.showHideButton setTitle:shownTrack ? OALocalizedString(@"poi_hide") : OALocalizedString(@"sett_show")
                         forState:UIControlStateNormal];
    [self.showHideButton setImage:[UIImage templateImageNamed:shownTrack ? @"ic_custom_hide" : @"ic_custom_show"]
                         forState:UIControlStateNormal];
}

- (void)updateFrame
{
    CGRect headerFrame = self.frame;

    if (self.onlyTitleAndDescriptionConstraint.active)
    {
        headerFrame.size.height =
                self.descriptionContainerView.frame.origin.y + self.descriptionContainerView.frame.size.height;
    }
    else if (self.onlyTitleNoDescriptionConstraint.active)
    {
        headerFrame.size.height = self.titleContainerView.frame.size.height + self.onlyTitleNoDescriptionConstraint.constant;
    }
    else {
        if (self.descriptionContainerView.hidden)
            headerFrame.size.height -= self.descriptionContainerView.frame.size.height;

        if (self.locationContainerView.hidden)
            headerFrame.size.height -= self.locationContainerView.frame.size.height;

        if (self.collectionView.hidden)
            headerFrame.size.height -= self.collectionView.frame.size.height;

        if (self.actionButtonsContainerView.hidden)
            headerFrame.size.height -= self.actionButtonsContainerView.frame.size.height;
    }

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
    BOOL hasDescription = description && description.length > 0;

    [self.descriptionView setText:description];
    self.descriptionContainerView.hidden = !hasDescription;
}

- (void)setCollection:(NSArray<OAGPXTableCellData *> *)data
{
    BOOL hasData = data && data.count > 0;

    _collectionData = data;
    [self.collectionView reloadData];
    self.collectionView.hidden = !hasData;
}

- (void)makeOnlyHeader:(BOOL)hasDescription
{
    self.descriptionContainerView.hidden = !hasDescription;
    self.collectionView.hidden = YES;
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
    {
        [self updateShowHideButton:[self.trackMenuDelegate changeTrackVisible]];
    }
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
    return _collectionData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                   cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = _collectionData[indexPath.row];
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

        cell.separatorView.hidden =
                indexPath.row == [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1;

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
    OAGPXTableCellData *cellData = _collectionData[indexPath.row];
    BOOL isLast = indexPath.row == [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1;
    return [self getSizeForItem:cellData.title value:cellData.values[@"string_value"] isLast:isLast];
}

- (CGSize)getSizeForItem:(NSString *)title value:(NSString *)value isLast:(BOOL)isLast
{
    CGSize sizeByTitle = [OAUtilities calculateTextBounds:title
                                                    width:kBlockStatistickWidthMax
                                                   height:kBlockStatistickHeight
                                                     font:[UIFont systemFontOfSize:13. weight:UIFontWeightRegular]];
    CGSize sizeByValue = [OAUtilities calculateTextBounds:value
                                                    width:kBlockStatistickWidthMaxByValue
                                                   height:kBlockStatistickHeight
                                                     font:[UIFont systemFontOfSize:13. weight:UIFontWeightMedium]];
    CGFloat widthByTitle = sizeByTitle.width < kBlockStatistickWidthMin
            ? kBlockStatistickWidthMin : sizeByTitle.width > kBlockStatistickWidthMax
                    ? kBlockStatistickWidthMax : sizeByTitle.width;
    CGFloat widthByValue = (sizeByValue.width < kBlockStatistickWidthMinByValue
            ? kBlockStatistickWidthMinByValue : sizeByValue.width > kBlockStatistickWidthMaxByValue
                    ? kBlockStatistickWidthMaxByValue : sizeByValue.width)
                            + kBlockStatistickWidthMax - kBlockStatistickWidthMaxByValue;
    if (!isLast)
    {
        widthByTitle += kBlockStatistickDivider;
        widthByValue += kBlockStatistickDivider;
    }
    return CGSizeMake(MAX(widthByTitle, widthByValue), kBlockStatistickHeight);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = _collectionData[indexPath.row];
    EOARouteStatisticsMode modeType = (EOARouteStatisticsMode) [cellData.values[@"int_value"] intValue];
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate openAnalysis:modeType];
}

@end
