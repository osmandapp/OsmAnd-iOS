//
//  OAAngleStraightLineViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 30.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAAngleStraightLineViewController.h"
#import "OAValueTableViewCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OASegmentedSlider.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAColors.h"
#import "Localization.h"

#define kAngleMinValue 0.
#define kAngleMaxValue 90.
#define kAngleStepValue 5

@interface OAAngleStraightLineViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAAngleStraightLineViewController
{
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
    NSInteger _selectedValue;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _selectedValue = (NSInteger) [self.appMode getStrAngle];
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"recalc_angle_dialog_title");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.backButton.hidden = YES;
    self.cancelButton.hidden = NO;
    self.doneButton.hidden = NO;
    self.subtitleLabel.hidden = YES;

    [self generateData];
}

- (void)generateData
{
    _data = @[@{
        @"type" : [OASegmentSliderTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_angle"),
        @"value" : [NSString stringWithFormat:@"%ld°", _selectedValue],
        @"minValue" : [NSString stringWithFormat:@"%d°", (int) kAngleMinValue],
        @"maxValue" : [NSString stringWithFormat:@"%d°", (int) kAngleMaxValue],
        @"marksCount" : @((kAngleMaxValue / kAngleStepValue) + 1),
        @"selectedMark" : @(_selectedValue / kAngleStepValue)
    }];
}

- (IBAction)doneButtonPressed:(id)sender
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [self.appMode setStrAngle:_selectedValue];
    if (self.delegate)
        [self.delegate onSettingsChanged];
    if (self.appMode == [routingHelper getAppMode] && ([routingHelper isRouteCalculated] || [routingHelper isRouteBeingCalculated]))
        [routingHelper recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.topLeftLabel.text = item[@"title"];
            cell.topRightLabel.text = item[@"value"];
            cell.topRightLabel.textColor = UIColorFromRGB(color_primary_purple);
            cell.topRightLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
            cell.bottomLeftLabel.text = item[@"minValue"];
            cell.bottomRightLabel.text = item[@"maxValue"];

            [cell.sliderView setNumberOfMarks:[item[@"marksCount"] integerValue] additionalMarksBetween:0];
            cell.sliderView.selectedMark = [item[@"selectedMark"] integerValue];
            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.sliderView addTarget:self
                                action:@selector(sliderChanged:)
                      forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return OALocalizedString(@"recalc_angle_dialog_descr");
}

#pragma mark - Selectors

- (void)sliderChanged:(UISlider *)sender
{
    UISlider *slider = (UISlider *) sender;
    if (slider)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:slider.tag & 0x3FF inSection:slider.tag >> 10];
        OASegmentSliderTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        _selectedValue = cell.sliderView.selectedMark * kAngleStepValue;
        [self generateData];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
