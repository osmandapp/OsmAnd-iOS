//
//  OAGpxApproximationViewController.mm
//  OsmAnd
//
//  Created by Skalii on 31.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAGpxApproximationViewController.h"
#import "OATitleSliderRoundCell.h"
#import "OAIconTitleIconRoundCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAGpxApproximationHelper.h"
#import "OAGpxApproximationParams.h"

#define kThresholdSection @"thresholdSection"
#define kProfilesSection @"profilesSection"

#define kApproximationMinDistance 0
#define kApproximationMaxDistance 100

static const float kProgressMaximumValue = 100.f;

@interface OAGpxApproximationViewController () <UITableViewDelegate, UITableViewDataSource, OAGpxApproximationHelperDelegate>

@end

@implementation OAGpxApproximationViewController
{
    OAGpxApproximationViewController *vwController;
    NSDictionary<NSString *, NSArray *> *_data;
    OAApplicationMode *_snapToRoadAppMode;
    float _distanceThreshold;
    OAGpxApproximationParams *_approximationParams;
    OAGpxApproximationHelper *_approximationHelper;
    UIProgressView *_progressBarView;
    BOOL _isCalculating;
    BOOL _hasApproximationResult;
    BOOL _shouldCalculateOnApply;
}

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints
{
    return [self initWithMode:mode routePoints:routePoints shouldCalculateOnApply:NO];
}

- (instancetype)initWithMode:(OAApplicationMode *)mode
                 routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints
      shouldCalculateOnApply:(BOOL)shouldCalculateOnApply
{
    self = [super init];
    if (self)
    {
        _snapToRoadAppMode = mode;
        _distanceThreshold = kApproximationMaxDistance / 2;
        _approximationParams = [[OAGpxApproximationParams alloc] init];
        [_approximationParams setTrackPoints:routePoints];
        [_approximationParams setAppMode:mode];
        [_approximationParams setDistanceThreshold:(int)_distanceThreshold];
        _shouldCalculateOnApply = shouldCalculateOnApply;
    }
    return self;
}

- (void)dealloc
{
    [_approximationHelper cancelApproximationIfPossible];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [_approximationParams setAppMode:_snapToRoadAppMode];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self setHeaderViewVisibility:YES];
    
    _approximationHelper = [[OAGpxApproximationHelper alloc] initWithParams:_approximationParams];
    if (![_approximationHelper canApproximate])
    {
        [self setApplyButtonEnabled:NO];
        return;
    }
    if (_shouldCalculateOnApply)
    {
        [self setApplyButtonEnabled:YES];
        return;
    }
    _progressBarView = [[UIProgressView alloc] init];
    _progressBarView.hidden = YES;
    _progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _progressBarView.progressTintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    _progressBarView.frame = CGRectMake(0., -3., self.view.frame.size.width, 3.);
    [self.buttonsView addSubview:_progressBarView];
    _approximationHelper.delegate = self;
    [self setApplyButtonEnabled:NO];
    [_approximationHelper calculateGpxApproximationAsync];
}

- (CGFloat)initialHeight
{
    return DeviceScreenHeight * 0.45;
}

- (void)applyLocalization
{
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.rightButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void)onRightButtonPressed
{
    if (_shouldCalculateOnApply)
    {
        void (^onApplyConfiguration)(OAApplicationMode *, float) = self.onApplyConfiguration;
        OAApplicationMode *mode = _snapToRoadAppMode;
        float distanceThreshold = roundf(_distanceThreshold);
        [self setApplyButtonEnabled:NO];
        [self dismissViewControllerAnimated:YES completion:^{
            if (onApplyConfiguration)
                onApplyConfiguration(mode, distanceThreshold);
        }];
        return;
    }

    if (_isCalculating || !_hasApproximationResult)
        return;
    [self setApplyButtonEnabled:NO];
    id<OAPlanningPopupDelegate> delegate = self.delegate;
    [self dismissViewControllerAnimated:YES completion:^{
        [delegate onApplyGpxApproximation];
    }];
}

- (void)onLeftButtonPressed
{
    [self dismiss];
}

- (void)dismiss
{
    [_approximationHelper cancelApproximationIfPossible];
    if (!_shouldCalculateOnApply && self.delegate)
        [self.delegate onCancelSnapApproximation:_hasApproximationResult];
    [super dismiss];
}

- (void)initData
{
    NSMutableDictionary<NSString *, NSArray *> *dictionary = [NSMutableDictionary new];

    NSMutableArray *thresholdSectionArray = [NSMutableArray array];
    [thresholdSectionArray addObject:@{
        @"type" : [OATitleSliderRoundCell getCellIdentifier],
        @"title" : OALocalizedString(@"threshold_distance")
    }];
    dictionary[kThresholdSection] = thresholdSectionArray;

    NSMutableArray *profilesSectionArray = [NSMutableArray array];
    [profilesSectionArray addObject:@{
        @"type" : [OAIconTitleIconRoundCell getCellIdentifier],
        @"title" : OALocalizedString(@"select_profile")
    }];
    NSArray<OAApplicationMode *> *profiles = [self getProfiles];
    if (_snapToRoadAppMode == nil || ![profiles containsObject:_snapToRoadAppMode])
        _snapToRoadAppMode = profiles.firstObject;
    for (OAApplicationMode *profile in profiles)
    {
        [profilesSectionArray addObject:@{
            @"type" : [OAIconTitleIconRoundCell getCellIdentifier],
            @"profile" : profile
        }];
    }
    dictionary[kProfilesSection] = profilesSectionArray;

    _data = [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray<OAApplicationMode *> *)getProfiles
{
    NSMutableArray<OAApplicationMode *> *profiles = [NSMutableArray arrayWithArray:OAApplicationMode.values];
    [profiles removeObject:OAApplicationMode.DEFAULT];
    NSMutableArray<OAApplicationMode *> *toRemove = [NSMutableArray array];
    [profiles enumerateObjectsUsingBlock:^(OAApplicationMode *profile, NSUInteger ids, BOOL *stop) {
        if ([profile.getRoutingProfile isEqualToString:@"public_transport"])
            [toRemove addObject:profile];
    }];
    [profiles removeObjectsInArray:toRemove];
    return profiles;
}

- (void)didStartProgress
{
    _isCalculating = YES;
    if (_progressBarView)
        _progressBarView.progress = 0;
    _progressBarView.hidden = NO;
}

- (void)didUpdateProgress:(NSInteger)progress
{
    if (_isCalculating && _progressBarView)
    {
        if (_progressBarView.hidden)
            _progressBarView.hidden = NO;
        float normalizedProgress = MIN(MAX((float)progress / kProgressMaximumValue, 0.f), 1.f);
        [_progressBarView setProgress:MAX(_progressBarView.progress, normalizedProgress) animated:YES];
    }
}

- (void)didApproximationStarted
{
    [self setApplyButtonEnabled:NO];
}

- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    BOOL hasResult = approximations.count > 0 && approximations.count == points.count;
    if (hasResult && self.delegate)
        [self.delegate onGpxApproximationDone:approximations pointsList:points mode:_snapToRoadAppMode];
    _isCalculating = NO;
    _hasApproximationResult = _hasApproximationResult || hasResult;
    [_progressBarView setProgress:hasResult ? 1.f : 0.f animated:YES];
    _progressBarView.hidden = YES;
    [self setApplyButtonEnabled:hasResult];
}

- (void) setApplyButtonEnabled:(BOOL)enabled
{
    self.rightButton.userInteractionEnabled = enabled;
    self.rightButton.backgroundColor = enabled ? [UIColor colorNamed:ACColorNameButtonBgColorPrimary] : [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
}

// MARK: Selectors

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    _distanceThreshold = slider.value;
    OATitleSliderRoundCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.valueLabel.text = [OAOsmAndFormatter getFormattedDistance:_distanceThreshold];
    if (!slider.tracking)
        [self applyDistanceThreshold];
}

- (void)sliderEditingDidEnd:(__unused id)sender
{
    [self applyDistanceThreshold];
}

- (void)applyDistanceThreshold
{
    [_approximationHelper setDistanceThreshold:(int)roundf(_distanceThreshold) recalculate:!_shouldCalculateOnApply];
}

// MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[_data.allKeys[section]].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];

    if ([item[@"type"] isEqualToString:[OATitleSliderRoundCell getCellIdentifier]])
    {
        OATitleSliderRoundCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSliderRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderRoundCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.sliderView.minimumValue = kApproximationMinDistance;
            cell.sliderView.maximumValue = kApproximationMaxDistance;
        }
        if (cell)
        {
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.sliderView addTarget:self
                                action:@selector(sliderEditingDidEnd:)
                      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            cell.titleLabel.text = item[@"title"];
            cell.sliderView.value = _distanceThreshold;
            cell.valueLabel.text = [OAOsmAndFormatter getFormattedDistance:_distanceThreshold];
            cell.contentContainer.layer.cornerRadius = 12.;
            return cell;
        }
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]])
    {
        OAIconTitleIconRoundCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleIconRoundCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.iconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            BOOL selected = NO;
            if (indexPath.row == 0)
            {
                cell.titleView.text = [item[@"title"] uppercaseString];
                cell.titleView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
                cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                cell.secondaryImageView.hidden = YES;
                cell.secondaryImageView.image = nil;
            }
            else
            {
                OAApplicationMode *profile = item[@"profile"];
                selected = _snapToRoadAppMode == profile;
                cell.secondaryImageView.hidden = NO;
                cell.titleView.text = profile.toHumanString;
                cell.titleView.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                UIImage *img = profile.getIcon;
                cell.secondaryImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.secondaryImageView.tintColor = profile.getProfileColor;
            }
            cell.iconView.hidden = indexPath.row == 0;
            cell.iconView.image = selected ? [UIImage templateImageNamed:@"ic_checkmark_default"] : nil;
            [cell roundCorners:indexPath.row == 0 bottomCorners:indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1];
            cell.separatorView.hidden = indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1;

            [cell layoutIfNeeded];
            return cell;
        }
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]] && indexPath.row != 0)
    {
        _snapToRoadAppMode = item[@"profile"];
        [_approximationHelper setAppMode:_snapToRoadAppMode recalculate:!_shouldCalculateOnApply];
        [tableView reloadData];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 16.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]])
    {
        NSString *text;
        if (item[@"title"])
        {
            text = [item[@"title"] uppercaseString];
        }
        else
        {
            OAApplicationMode *profile = item[@"profile"];
            text = profile.toHumanString;
        }
        return [OAIconTitleIconRoundCell getHeight:text cellWidth:tableView.bounds.size.width];
    }
    return UITableViewAutomaticDimension;
}

@end
