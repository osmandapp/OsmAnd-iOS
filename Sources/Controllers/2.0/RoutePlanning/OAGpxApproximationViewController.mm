//
//  OAGpxApproximationViewController.mm
//  OsmAnd
//
// Created by Skalii on 31.05.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAGpxApproximationViewController.h"
#import "OATitleSliderTableViewCell.h"
#import "OAIconTitleIconRoundCell.h"
#import "Localization.h"
#import "OAColors.h"

#define kThresholdSection @"thresholdSection"
#define kProfilesSection @"profilesSection"

@interface OAGpxApproximationBottomSheetScreen ()

@end

@implementation OAGpxApproximationBottomSheetScreen
{
    OAGpxApproximationViewController *vwController;
    NSDictionary<NSString *, NSArray *> *_data;

    NSInteger _selectedModeIndex;
    OAApplicationMode *_snapToRoadAppMode;
    NSArray<NSArray<OAGpxRtePt *> *> *_routePoints;
    float _distanceThreshold;
}

@synthesize tableData, tblView, vwController;

- (id)initWithTable:(UITableView *)tableView viewController:(OAGpxApproximationViewController *)viewController param:(id)param;
{
    self = [super init];
    if (self)
    {
        NSDictionary *customParam = (NSDictionary *) param;
        _snapToRoadAppMode = [customParam.allKeys containsObject:@"mode"] ? customParam[@"mode"] : OAApplicationMode.CAR;
        _routePoints = customParam[@"routePoints"];
        _distanceThreshold = 50;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void)initOnConstruct:(UITableView *)tableView viewController:(OAGpxApproximationViewController *)viewController
{
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self initData];
}

- (void)setupView
{
}

- (void)initData
{
    NSMutableDictionary<NSString *, NSArray *> *dictionary = [NSMutableDictionary new];

    NSMutableArray *thresholdSectionArray = [NSMutableArray array];
    [thresholdSectionArray addObject:@{
            @"type" : [OATitleSliderTableViewCell getCellIdentifier],
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

-(NSArray<OAApplicationMode *> *)getProfiles
{
    NSMutableArray<OAApplicationMode *> *profiles = [NSMutableArray arrayWithArray:OAApplicationMode.values];
    [profiles removeObject:OAApplicationMode.DEFAULT];
    [profiles enumerateObjectsUsingBlock:^(OAApplicationMode *profile, NSUInteger ids, BOOL *stop) {
        if ([profile.getRoutingProfile isEqualToString:@"public_transport"])
            [profiles removeObject:profile];
    }];
    return [NSArray arrayWithArray:profiles];
}

- (void)doneButtonPressed
{
    [vwController setCancel:NO];
    [vwController setApply:YES];
    [vwController dismiss];
}

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

    if ([item[@"type"] isEqualToString:[OATitleSliderTableViewCell getCellIdentifier]])
    {
        OATitleSliderTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.titleLabel.text = item[@"title"];
            cell.sliderView.value = _distanceThreshold;
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f %@", cell.sliderView.value * 100, OALocalizedString(@"units_km")];
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
    if ([item[@"type"] isEqualToString:[OATitleSliderTableViewCell getCellIdentifier]])
        return 80;
    else if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]])
        return 48;

    return UITableViewAutomaticDimension;
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = UIColorFromRGB(color_bottom_sheet_background);
}

@end

@interface OAGpxApproximationViewController ()

@end

@implementation OAGpxApproximationViewController
{
    BOOL _cancel;
    BOOL _apply;
}

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OAGpxRtePt *> *> *)routePoints
{
    NSMutableDictionary *customParam = [NSMutableDictionary new];
    customParam[@"mode"] = mode;
    customParam[@"routePoints"] = routePoints;
    return [super initWithParam:customParam];
}

- (void)setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAGpxApproximationBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];

    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.subviews.firstObject.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void)dismiss
{
    [super dismiss];
    if (self.delegate)
    {
        if (_apply)
            [self.delegate onApplyGpxApproximation];
        else if (_cancel)
            [self.delegate onCancelGpxApproximation];
    }
}

- (void)dismiss:(id)sender
{
    [super dismiss:sender];
    if (self.delegate)
    {
        if (_apply)
            [self.delegate onApplyGpxApproximation];
        else if (_cancel)
            [self.delegate onCancelGpxApproximation];
    }
}

- (void)setCancel:(BOOL)cancel
{
    _cancel = cancel;
}

- (void)setApply:(BOOL)apply
{
    _apply = apply;
}

@end