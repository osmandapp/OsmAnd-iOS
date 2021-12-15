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
#import "OAGpxApproximator.h"
#import "OAResultMatcher.h"
#import "OAGpxRouteApproximation.h"
#import "OAGPXDocumentPrimitives.h"
#import "OALocationsHolder.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"

#define kThresholdSection @"thresholdSection"
#define kProfilesSection @"profilesSection"

#define kApproximationMinDistance 0
#define kApproximationMaxDistance 100

@interface OAGpxApproximationViewController () <UITableViewDelegate, UITableViewDataSource, OAGpxApproximationProgressDelegate>

@end

@implementation OAGpxApproximationViewController
{
    OAGpxApproximationViewController *vwController;
    NSDictionary<NSString *, NSArray *> *_data;

    OAApplicationMode *_snapToRoadAppMode;
    NSArray<NSArray<OAGpxTrkPt *> *> *_routePoints;
    float _distanceThreshold;
	
	OsmAndAppInstance _app;

    NSArray<OALocationsHolder *> *_locationsHolders;
	NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *_resultMap;
    OAGpxApproximator *_gpxApproximator;
    UIProgressView *_progressBarView;
}

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OAGpxTrkPt *> *> *)routePoints
{
    self = [super init];
    if (self)
    {
        _routePoints = routePoints;
		NSMutableArray<OALocationsHolder *> *locationsHolders = [NSMutableArray array];
		for (NSArray<OAGpxTrkPt *> *points in routePoints)
			 [locationsHolders addObject:[[OALocationsHolder alloc] initWithLocations:points]];
		_locationsHolders = locationsHolders;
        _distanceThreshold = kApproximationMaxDistance / 2;
		_app = OsmAndApp.instance;
		_resultMap = [NSMutableDictionary dictionary];
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
	
	[self calculateGpxApproximation:YES];
	
	_progressBarView = [[UIProgressView alloc] init];
	_progressBarView.hidden = YES;
	_progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_progressBarView.progressTintColor = UIColorFromRGB(color_primary_purple);
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

- (BOOL)setSnapToRoadAppMode:(OAApplicationMode *)appMode
{
    if (appMode != nil && _snapToRoadAppMode != appMode) {
        _snapToRoadAppMode = appMode;
        return YES;
    }
    return NO;
}

- (void)startProgress
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (_progressBarView)
			_progressBarView.progress = 0;
			_progressBarView.hidden = NO;
	});
}

- (void)finishProgress
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (_progressBarView)
			_progressBarView.hidden = YES;
	});
}

- (void)updateProgress:(NSInteger)progress
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (_progressBarView)
		{
			if (_progressBarView.hidden)
				_progressBarView.hidden = NO;
			_progressBarView.progress = progress;
		}
	});
}

- (OAGpxApproximator *) getNewGpxApproximator:(OALocationsHolder *)locationsHolder
{
    OAGpxApproximator *gpxApproximator = [[OAGpxApproximator alloc] initWithApplicationMode:_snapToRoadAppMode pointApproximation:_distanceThreshold locationsHolder:locationsHolder];
	gpxApproximator.progressDelegate = self;
    return gpxApproximator;
}

- (BOOL) calculateGpxApproximation:(BOOL)newCalculation
{
	if (newCalculation)
	{
		if (_gpxApproximator != nil)
		{
			[_gpxApproximator cancelApproximation];
			_gpxApproximator = nil;
		}
		[_resultMap removeAllObjects];
		[self startProgress];
	}
	OAGpxApproximator *gpxApproximator = nil;
	for (OALocationsHolder *locationsHolder in _locationsHolders)
	{
		if (!_resultMap[locationsHolder])
		{
			gpxApproximator = [self getNewGpxApproximator:locationsHolder];
			break;
		}
	}
	if (gpxApproximator != nil)
	{
		_gpxApproximator = gpxApproximator;
		_gpxApproximator.mode = _snapToRoadAppMode;
		_gpxApproximator.pointApproximation = _distanceThreshold;
		[self approximateGpx:_gpxApproximator];
		return YES;
	}
	return NO;
}

- (void) approximateGpx:(OAGpxApproximator *)gpxApproximator
{
    [self onApproximationStarted];
	[gpxApproximator calculateGpxApproximation:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *object) {
		if (!gpxApproximator.isCancelled)
		{
			if (*object)
				_resultMap[gpxApproximator.locationsHolder] = *object;
			if (![self calculateGpxApproximation:NO])
				[self onApproximationFinished];
		}
		return YES;
	} cancelledFunc:^BOOL{
		return NO;
	}]];
}

- (void) onApproximationStarted
{
    [self setApplyButtonEnabled:NO];
}

- (void) onApproximationFinished
{
    [self finishProgress];
    NSMutableArray<OAGpxRouteApproximation *> *approximations = [NSMutableArray array];
    NSMutableArray<NSArray<OAGpxTrkPt *> *> *points = [NSMutableArray array];
    for (OALocationsHolder *locationsHolder in _locationsHolders)
	{
        OAGpxRouteApproximation *approximation = _resultMap[locationsHolder];
        if (approximation != nil)
		{
            [approximations addObject:approximation];
            [points addObject:locationsHolder.getWptPtList];
        }
    }
	if (self.delegate)
		[self.delegate onGpxApproximationDone:approximations pointsList:points mode:_snapToRoadAppMode];
	[self setApplyButtonEnabled:approximations.count > 0];
}

- (void) setApplyButtonEnabled:(BOOL)enabled
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.rightButton.userInteractionEnabled = enabled;
		self.rightButton.backgroundColor = enabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_icon_inactive);
	});
}

// MARK: Selectors

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    _distanceThreshold = slider.value;
	[self calculateGpxApproximation:YES];
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
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
			cell.separatorHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;
        }
        if (cell)
        {
			BOOL selected = NO;
            if (indexPath.row == 0)
            {
                cell.titleView.text = [item[@"title"] uppercaseString];
                cell.titleView.textColor = UIColorFromRGB(color_text_footer);
                cell.titleView.font = [UIFont systemFontOfSize:13];
                cell.secondaryImageView.hidden = YES;
				cell.secondaryImageView.image = nil;
            }
            else
            {
                OAApplicationMode *profile = item[@"profile"];
				selected = _snapToRoadAppMode == profile;
				cell.secondaryImageView.hidden = NO;
                cell.titleView.text = profile.toHumanString;
				cell.titleView.textColor = UIColor.blackColor;
				cell.titleView.font = [UIFont systemFontOfSize:17];
                UIImage *img = profile.getIcon;
                cell.secondaryImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.secondaryImageView.tintColor = UIColorFromRGB(profile.getIconColor);
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
		[tableView reloadData];
		[self calculateGpxApproximation:YES];
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

// MARK: OAGpxApproximationProgressDelegate

- (void)start:(OAGpxApproximator *)approximator
{
}

- (void)updateProgress:(OAGpxApproximator *)approximator progress:(NSInteger)progress
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (approximator == _gpxApproximator)
		{
			float partSize = 100. / _locationsHolders.count;
			float p = _resultMap.count * partSize + (progress / 100.) * partSize;
			[self updateProgress:(int)p];
		}
	});
}

- (void)finish:(OAGpxApproximator *)approximator
{
}

@end
