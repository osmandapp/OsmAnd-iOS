//
//  OARecordSettingsBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OARecordSettingsBottomSheetViewController.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASwitchTableViewCell.h"
#import "OATitleSliderTableViewCell.h"

#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kLabelVerticalMargin 16.
#define kButtonHeight 42.
#define kButtonsVerticalMargin 32.
#define kHorizontalMargin 20.
#define kSliderHeight 84.
#define kSwitchHeight 48.

#define kRememberMyChoiseTag 0
#define kShowOnMapTag 1

@interface OARecordSettingsBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *messageView;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OARecordSettingsBottomSheetViewController
{
    OAAppSettings *_settings;
    NSMutableArray<NSDictionary *> *_data;
    double _delta;
    double _sliderValue;
    NSString *_sliderIntervalName;
    BOOL _isRememberChoise;
    BOOL _isShowOnMap;
    OARecordSettingsBottomSheetCompletionBlock _completitionBlock;
}

- (instancetype) initWithCompletitionBlock:(OARecordSettingsBottomSheetCompletionBlock)completitionBlock
{
    self = [super init];
    if (self)
    {
        _completitionBlock = completitionBlock;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    int interval = [_settings.mapSettingSaveTrackIntervalGlobal get];
    int index = 0;
    for (int i = 0; i < _settings.trackIntervalArray.count; i++)
        if ([_settings.trackIntervalArray[i] intValue] == interval)
        {
            index = i;
            break;
        }
    _delta = 1.0 / (_settings.trackIntervalArray.count - 1);
    _sliderValue = index * _delta;
    
    _isShowOnMap = _settings.mapSettingShowRecordingTrack.get;
    [self updateIntervalLabel:index];
    
    [self generateData];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.buttonsView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.buttonsSectionDividerView.backgroundColor = UIColor.clearColor;;

    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.saveButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.isFullScreenAvailable = NO;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"track_start_rec");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.rightButton setTitle:OALocalizedString(@"shared_string_ok") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width;
    if (OAUtilities.isIPad)
        width = kOABottomSheetWidthIPad;
    else if ([OAUtilities isLandscape])
        width = kOABottomSheetWidth;
    else
        width = DeviceScreenWidth;
    
    width -= 2 * kHorizontalMargin;
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat contentHeight = kSliderHeight + 2 * kSwitchHeight +  kButtonsVerticalMargin;
    CGFloat buttonsHeight = [self buttonsViewHeight];
    return headerHeight + contentHeight + buttonsHeight;
}

- (CGFloat) getLandscapeHeight
{
    return [self initialHeight];
}

- (void) generateData
{
    _data = [NSMutableArray new];
    
    [_data addObject:@{
        @"type" : [OATitleSliderTableViewCell getCellIdentifier],
        @"name" : OALocalizedString(@"rec_interval"),
        @"value" : @(_sliderValue),
        @"desc" : _sliderIntervalName
    }];
    
    [_data addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"track_interval_remember"),
        @"value" : @(_isRememberChoise),
        @"tag" : @(kRememberMyChoiseTag)
    }];
    
    [_data addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"map_settings_show"),
        @"value" : @(_isShowOnMap),
        @"tag" : @(kShowOnMapTag)
    }];
}

- (BOOL) isDraggingUpAvailable
{
    return NO;
}

#pragma mark - Actions

- (void) onRightButtonPressed
{
    [self hide:YES];
    _completitionBlock([self getInterval:_sliderValue], _isRememberChoise, _isShowOnMap);
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        if (sw.tag == kRememberMyChoiseTag)
        {
            _isRememberChoise = sw.on;
        }
        else if (sw.tag == kShowOnMapTag)
        {
            _isShowOnMap = sw.on;
        }
    }
}

- (void) sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    int i = [self getInterval:slider.value];
    _sliderValue = i * _delta;
    [self updateIntervalLabel:i];
}

- (int)getInterval:(float)value
{
    float floatInterval = roundf(value / _delta);
    int interval = (int)(floatInterval);
    if (interval < 0)
        interval = 0;
    else if (interval >= _settings.trackIntervalArray.count)
        interval = (int) _settings.trackIntervalArray.count - 1;
    return interval;
}

- (void)updateIntervalLabel:(int)interval
{
    _sliderIntervalName = [_settings getFormattedTrackInterval:[_settings.trackIntervalArray[interval] intValue]];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OATitleSliderTableViewCell getCellIdentifier]])
    {
        OATitleSliderTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = item[@"name"];
            cell.valueLabel.text = item[@"desc"];
            cell.sliderView.value = [item[@"value"] doubleValue];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            cell.backgroundColor = [UIColor clearColor];
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = [item[@"tag"] intValue];
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tintColor = UIColorFromRGB(color_bottom_sheet_secondary);
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

@end
