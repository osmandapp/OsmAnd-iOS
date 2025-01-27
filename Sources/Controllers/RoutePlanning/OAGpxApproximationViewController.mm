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
#import "OALocationsHolder.h"

#define kThresholdSection @"thresholdSection"
#define kProfilesSection @"profilesSection"

#define kApproximationMinDistance 0
#define kApproximationMaxDistance 100

@interface OAGpxApproximationViewController () <UITableViewDelegate, UITableViewDataSource, OAGpxApproximationHelperDelegate>

@end

@implementation OAGpxApproximationViewController
{
    OAGpxApproximationViewController *vwController;
    NSDictionary<NSString *, NSArray *> *_data;
    OAApplicationMode *_snapToRoadAppMode;
    float _distanceThreshold;
    OAGpxApproximationHelper *_approximationHelper;
    NSArray<OALocationsHolder *> *_locationsHolders;
    UIProgressView *_progressBarView;
}

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints
{
    self = [super init];
    if (self)
    {
        NSMutableArray<OALocationsHolder *> *locationsHolders = [NSMutableArray array];
        for (NSArray<OASWptPt *> *points in routePoints)
            [locationsHolders addObject:[[OALocationsHolder alloc] initWithLocations:points]];
        _locationsHolders = locationsHolders;
        _distanceThreshold = kApproximationMaxDistance / 2;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self setHeaderViewVisibility:YES];
    
    _approximationHelper = [[OAGpxApproximationHelper alloc] initWithLocations:_locationsHolders initialAppMode:_snapToRoadAppMode initialThreshold:_distanceThreshold];
    _approximationHelper.delegate = self;
    [_approximationHelper calculateGpxApproximation:YES];
    
    _progressBarView = [[UIProgressView alloc] init];
    _progressBarView.hidden = YES;
    _progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _progressBarView.progressTintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    _progressBarView.frame = CGRectMake(0., -3., self.view.frame.size.width, 3.);
    [self.buttonsView addSubview:_progressBarView];
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
    if (self.delegate)
        [self.delegate onApplyGpxApproximation];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onLeftButtonPressed
{
    if (self.delegate)
        [self.delegate onCancelSnapApproximation:YES];
    [self dismiss];
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
    if (_progressBarView)
        _progressBarView.progress = 0;
    _progressBarView.hidden = NO;
}

- (void)didUpdateProgress:(NSInteger)progress
{
    if (_progressBarView)
    {
        if (_progressBarView.hidden)
            _progressBarView.hidden = NO;
        _progressBarView.progress = progress;
    }
}

- (void)didApproximationStarted
{
    [self setApplyButtonEnabled:NO];
}

- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    if (_progressBarView)
        _progressBarView.hidden = YES;
    
    if (self.delegate)
        [self.delegate onGpxApproximationDone:approximations pointsList:points mode:_snapToRoadAppMode];
    [self setApplyButtonEnabled:approximations.count > 0];
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
    [_approximationHelper updateDistanceThreshold:_distanceThreshold];
    [_approximationHelper calculateGpxApproximation:YES];
    OATitleSliderRoundCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.valueLabel.text = [OAOsmAndFormatter getFormattedDistance:_distanceThreshold];
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
        [_approximationHelper updateAppMode:_snapToRoadAppMode];
        [tableView reloadData];
        [_approximationHelper calculateGpxApproximation:YES];
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
