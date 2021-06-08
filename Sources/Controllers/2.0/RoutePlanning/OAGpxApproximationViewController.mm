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
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAColors.h"

#define kThresholdSection @"thresholdSection"
#define kProfilesSection @"profilesSection"

@interface OAGpxApproximationViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAGpxApproximationViewController
{
    OAGpxApproximationViewController *vwController;
    NSDictionary<NSString *, NSArray *> *_data;

    NSInteger _selectedModeIndex;
    OAApplicationMode *_snapToRoadAppMode;
    NSArray<NSArray<OAGpxRtePt *> *> *_routePoints;
    float _distanceThreshold;

//    NSArray<OALocationsHolder *> *_locationsHolders;
//    OAGpxApproximator *_gpxApproximator;
//    NSDictionary<OALocationsHolder *, OAGpxApproximator *> *_resultMap;
    UIProgressView *_progressBarView;
}

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OAGpxRtePt *> *> *)routePoints
{
    self = [super init];
    if (self)
    {
        _snapToRoadAppMode = OAApplicationMode.CAR;
        _routePoints = routePoints;
        _distanceThreshold = 50;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setHeaderViewVisibility:YES];
}

- (CGFloat)initialHeight
{
    return DeviceScreenHeight * 0.6;
}

- (void)applyLocalization
{
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.rightButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void) commonInit
{
    [self setupView];
    [self initData];
}

- (void)onRightButtonPressed
{
    if (self.delegate)
        [self.delegate onApplyGpxApproximation];
}

- (void) onBottomSheetDismissed
{
    if (self.delegate)
        [self.delegate onCancelGpxApproximation];
}


- (void)setupView
{
//    calculateGpxApproximation(true);
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
    [profiles enumerateObjectsUsingBlock:^(OAApplicationMode *profile, NSUInteger ids, BOOL *stop) {
        if ([profile.getRoutingProfile isEqualToString:@"public_transport"])
            [profiles removeObject:profile];
    }];
    return [NSArray arrayWithArray:profiles];
}

- (BOOL)setSnapToRoadAppMode:(OAApplicationMode *)appMode
{
    if (appMode != nil && _snapToRoadAppMode != appMode) {
        _snapToRoadAppMode = appMode;
        return YES;
    }
    return NO;
}

- (void)startProgressBarView
{
    if (_progressBarView)
        _progressBarView.progress = 0;
        _progressBarView.hidden = NO;
}

- (void)finishProgressBarView
{
    if (_progressBarView)
        _progressBarView.hidden = YES;
}

- (void)updateProgressBarView:(NSInteger)progress
{
    if (_progressBarView)
    {
        if (!_progressBarView.hidden)
            _progressBarView.hidden = NO;
        _progressBarView.progress = progress;
    }
}

- (void)start/*:(OAGpxApproximator *)approximator*/
{
}

- (void)updateProgress:/*(OAGpxApproximator *)approximator*/ (NSInteger)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        if (approximator == self.approximator)
//        {
            float partSize = 100/* / _locationsHolders.count*/;
            float p = /*resultMap.count * */partSize + (progress / 100) * partSize;
            [self updateProgressBarView: (NSInteger) p];
//        }
    });
}

- (void)finish/*:(OAGpxApproximator *)approximator*/
{
}

/*private GpxApproximator getNewGpxApproximator(@NonNull LocationsHolder locationsHolder) {
    GpxApproximator gpxApproximator = null;
    try {
        OsmandApplication app = getMyApplication();
        if (app != null) {
            gpxApproximator = new GpxApproximator(app, snapToRoadAppMode, distanceThreshold, locationsHolder);
            gpxApproximator.setApproximationProgress(approximationProgress);
        }
    } catch (IOException e) {
        LOG.error(e.getMessage(), e);
    }
    return gpxApproximator;
}*/

/*public boolean calculateGpxApproximation(boolean newCalculation) {
    if (newCalculation) {
        if (gpxApproximator != null) {
            gpxApproximator.cancelApproximation();
            gpxApproximator = null;
        }
        resultMap.clear();
        startProgress();
    }
    GpxApproximator gpxApproximator = null;
    for (LocationsHolder locationsHolder : locationsHolders) {
        if (!resultMap.containsKey(locationsHolder)) {
            gpxApproximator = getNewGpxApproximator(locationsHolder);
            break;
        }
    }
    if (gpxApproximator != null) {
        try {
            this.gpxApproximator = gpxApproximator;
            gpxApproximator.setMode(snapToRoadAppMode);
            gpxApproximator.setPointApproximation(distanceThreshold);
            approximateGpx(gpxApproximator);
            return true;
        } catch (Exception e) {
            LOG.error(e.getMessage(), e);
        }
    }
    return false;
}*/

/*private void approximateGpx(@NonNull final GpxApproximator gpxApproximator) {
    onApproximationStarted();
    gpxApproximator.calculateGpxApproximation(new ResultMatcher<GpxRouteApproximation>() {
        @Override
        public boolean publish(final GpxRouteApproximation gpxApproximation) {
            OsmandApplication app = getMyApplication();
            if (app != null) {
                app.runInUIThread(new Runnable() {
                    @Override
                    public void run() {
                        if (!gpxApproximator.isCancelled()) {
                            if (gpxApproximation != null) {
                                resultMap.put(gpxApproximator.getLocationsHolder(), gpxApproximation);
                            }
                            if (!calculateGpxApproximation(false)) {
                                onApproximationFinished();
                            }
                        }
                    }
                });
            }
            return true;
        }

        @Override
        public boolean isCancelled() {
            return false;
        }
    });
}*/

/*private void onApproximationStarted() {
    setApplyButtonEnabled(false);
}*/

/*private void onApproximationFinished() {
    finishProgress();
    Fragment fragment = getTargetFragment();
    List<GpxRouteApproximation> approximations = new ArrayList<>();
    List<List<WptPt>> points = new ArrayList<>();
    for (LocationsHolder locationsHolder : locationsHolders) {
        GpxRouteApproximation approximation = resultMap.get(locationsHolder);
        if (approximation != null) {
            approximations.add(approximation);
            points.add(locationsHolder.getWptPtList());
        }
    }
    if (fragment instanceof GpxApproximationFragmentListener) {
        ((GpxApproximationFragmentListener) fragment).onGpxApproximationDone(
                approximations, points, snapToRoadAppMode);
    }
    setApplyButtonEnabled(!approximations.isEmpty());
}*/

#pragma mark - Selectors

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    _distanceThreshold = slider.value;
}

#pragma mark - UITableViewDataSource

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
        }
        if (cell)
        {
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.titleLabel.text = item[@"title"];
            cell.sliderView.value = _distanceThreshold;
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f %@", cell.sliderView.value, OALocalizedString(@"units_km")];

            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[_data.keyEnumerator.allObjects[indexPath.section]].count - 1)];

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
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            if (indexPath.row == 0)
            {
                cell.titleView.text = [item[@"title"] uppercaseString];
                cell.titleView.textColor = UIColorFromRGB(color_text_footer);
                cell.titleView.font = [UIFont systemFontOfSize:13];
                cell.secondaryImageView.hidden = YES;
            }
            else
            {
                OAApplicationMode *profile = item[@"profile"];
                BOOL selected = _snapToRoadAppMode == profile;
                if (selected)
                    _selectedModeIndex = indexPath.row;

                cell.titleView.text = profile.toHumanString;

                UIImage *img = profile.getIcon;
                cell.secondaryImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.secondaryImageView.tintColor = UIColorFromRGB(color_primary_purple);

                cell.iconView.image = selected ? [UIImage templateImageNamed:@"ic_checmark_default"] : [UIImage imageWithCIImage:[CIImage emptyImage]];
                cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            }

            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[_data.keyEnumerator.allObjects[indexPath.section]].count - 1)];
            cell.separatorView.hidden = indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1;
            cell.separatorHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];

            return cell;
        }
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATitleSliderRoundCell getCellIdentifier]])
        return 80;
    else if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]])
        return indexPath.row == 0 ? 38 : 48;

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]] && indexPath.row != 0)
    {
        BOOL selected = _snapToRoadAppMode == item[@"profile"];
        [cell setSelected:selected animated:NO];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]] && indexPath.row != 0)
    {
        _snapToRoadAppMode = item[@"profile"];
        [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], [NSIndexPath indexPathForRow:_selectedModeIndex inSection:indexPath.section]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationNone];
//        _selectedModeIndex = indexPath.row;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 16.;
}

@end
