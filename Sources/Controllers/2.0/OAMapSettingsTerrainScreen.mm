//
//  OAMapSettingsTerrainScreen.m
//  OsmAnd Maps
//
//  Created by igor on 20.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSettingsTerrainScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASettingSwitchCell.h"
#import "OATimeTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OATitleSliderTableViewCell.h"
#import "OASegmentTableViewCell.h"
#import "OAButtonIconTableViewCell.h"
#import "OAImageDescTableViewCell.h"

#define kMinAllowedZoom 1
#define kMaxAllowedZoom 22

#define kCellTypeSwitch @"switchCell"
#define kCellTypeValue @"valueCell"
#define kCellTypePicker @"pickerCell"
#define kCellTypeSlider @"sliderCell"
#define kCellTypeMap @"mapCell"
#define kCellTypeSegment @"segmentCell"
#define kCellTypeImageDesc @"imageDescCell"
#define kCellTypeButton @"buttonIconCell"

#define kZoomSection 2

//typedef NS_ENUM(NSInteger, EOATerrainScreenType)
//{
//    EOATerrainScreenTypeDisabled = 0,
//    EOATerrainScreenTypeHillshade,
//    EOATerrainScreenTypeSlope
//};

@interface OAMapSettingsTerrainScreen() <OACustomPickerTableViewCellDelegate>

@end

@implementation OAMapSettingsTerrainScreen
{
    OsmAndAppInstance _app;
    OAMapStyleSettings *_styleSettings;
    BOOL _availableMaps;
    
    NSArray<NSArray *> *_dataDisabled;
    NSArray<NSArray *> *_data;
    NSArray* _sectionHeaderFooterTitles;
    NSIndexPath *_pickerIndexPath;
    
    int _minZoom;
    int _maxZoom;
    NSArray<NSString *> *_possibleZoomValues;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        settingsScreen = EMapSettingsScreenTerrain;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
}

- (void) setupDisabledData:(NSMutableArray *)result
{
    NSMutableArray *imageArr = [NSMutableArray array];
    [imageArr addObject:@{
        @"type" : kCellTypeImageDesc,
        @"desc" : OALocalizedString(@"enable_hillshade"),
        @"img" : @"img_empty_state_terrain"
    }];
    [imageArr addObject:@{
        @"type" : kCellTypeButton,
        @"title" : OALocalizedString(@"shared_string_read_more"),
        @"link" : @"",
        @"img" : @"ic_custom_safari"
    }];
    [result addObject: imageArr];
}

- (void) setupView
{
    title = OALocalizedString(@"map_settings_terrain");

    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    _possibleZoomValues = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22"];
    
    NSMutableArray *result = [NSMutableArray array];
    
    NSMutableArray *switchArr = [NSMutableArray array];
    [switchArr addObject:@{
        @"type" : kCellTypeSwitch
    }];
    [result addObject:[NSArray arrayWithArray:switchArr]];
    
    [self setupDisabledData:result];
    _dataDisabled = [NSArray arrayWithArray:[NSArray arrayWithArray:result]];
    [result removeAllObjects];
    
    [switchArr addObject:@{
        @"type" : kCellTypeSegment,
        @"title0" : OALocalizedString(@"map_settings_hillshade"),
        @"title1" : OALocalizedString(@"gpx_slope")
    }];

    NSMutableArray *transparencyArr = [NSMutableArray array];
    [transparencyArr addObject:@{
        @"type" : kCellTypeSlider,
        @"name" : OALocalizedString(@"map_settings_layer_transparency")
    }];
    
    NSMutableArray *zoomArr = [NSMutableArray new];
    [zoomArr addObject:@{
        @"title": OALocalizedString(@"rec_interval_minimum"),
        @"key" : @"minZoom",
        @"type" : kCellTypeValue,
    }];
    [zoomArr addObject:@{
        @"title": OALocalizedString(@"shared_string_maximum"),
        @"key" : @"maxZoom",
        @"type" : kCellTypeValue,
    }];
    [zoomArr addObject:@{
        @"type" : kCellTypePicker,
    }];

    NSMutableArray *availableMapsArr = [NSMutableArray array];
    if (_availableMaps)
    {
       //fill array
        //kCellTypeMap
        //OAIconTextDescButtonTableViewCell
    }

    [result addObject: switchArr];
    [result addObject: transparencyArr];
    [result addObject: zoomArr];
    if (_availableMaps)
        [result addObject: availableMapsArr];

    _data = [NSArray arrayWithArray:result];

    
    NSString *availableSectionFooter = _app.data.hillshade == EOATerrainTypeSlope ? OALocalizedString(@"map_settings_add_maps_slopes") : OALocalizedString(@"map_settings_add_maps_hillshade");
    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{}];
    [sectionArr addObject:@{}];
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"res_zoom_levels"),
        @"footer" : OALocalizedString(@"map_settings_zoom_level_description")
    }];
    if (_app.data.hillshade == EOATerrainTypeSlope)
    {
        [sectionArr addObject:@{
            @"header" : OALocalizedString(@"map_settings_legend"),
        }];
    }
    if (_availableMaps)
    {
        [sectionArr addObject:@{
            @"header" : OALocalizedString(@"osmand_live_available_maps"),
            @"footer" : availableSectionFooter
        }];
    }
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
}

- (void) linkButtonPressed:(UIButton*)sender
{
    NSURL *url = [NSURL URLWithString:@"https://osmand.net/features/contour-lines-plugin"];
    if ([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (BOOL)pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void)hideExistingPicker {
    
    [tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (void)hidePicker
{
    [tblView beginUpdates];
    if ([self pickerIsShown])
        [self hideExistingPicker];
    [tblView endUpdates];
}

- (NSIndexPath *)calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath {
    NSIndexPath *newIndexPath;
    if (([self pickerIsShown]) && (_pickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:kZoomSection];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:kZoomSection];
    
    return newIndexPath;
}

- (void)showNewPickerAtIndex:(NSIndexPath *)indexPath {
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kZoomSection]];
    
    [tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if ([self isTerrainOn])
    {
        if (indexPath.section != kZoomSection)
        {
            return _data[indexPath.section][indexPath.row];
        }
        else
        {
            NSArray *ar = _data[indexPath.section];
            if ([self pickerIsShown])
            {
                if ([indexPath isEqual:_pickerIndexPath])
                    return ar[2];
                else if (indexPath.row == 0)
                    return ar[0];
                else
                    return ar[1];
            }
            else
            {
                if (indexPath.row == 0)
                    return ar[0];
                else if (indexPath.row == 1)
                    return ar[1];
            }
        }
    }
    else
    {
        return _dataDisabled[indexPath.section][indexPath.row];
    }
}

- (NSString *) getSwitchSectionFooter
{
    if (_app.data.hillshade == EOATerrainTypeHillshade)
        return OALocalizedString(@"map_settings_hillshade_description");
    else if (_app.data.hillshade == EOATerrainTypeSlope)
        return OALocalizedString(@"map_settings_slopes_description");
    else
        return @"";
}

- (BOOL) isTerrainOn
{
    return [OsmAndApp instance].data.hillshade != EOATerrainTypeDisabled;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section < _sectionHeaderFooterTitles.count ? _sectionHeaderFooterTitles[section][@"header"] : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return [self getSwitchSectionFooter];
    return section < _sectionHeaderFooterTitles.count ? _sectionHeaderFooterTitles[section][@"footer"] : nil;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self isTerrainOn] ? _data.count : _dataDisabled.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isTerrainOn])
    {
        if (section == kZoomSection)
            return [self pickerIsShown] ? 3 : 2;
        else
            return _data[section].count;
    }
    else
    {
        return _dataDisabled[section].count;
    }
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString: kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.text = [self isTerrainOn] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = [self isTerrainOn] ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [[UIImage imageNamed:imgName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = [self isTerrainOn] ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:[self isTerrainOn]];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString: kCellTypeValue])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lbTitle.text = item[@"title"];
        if ([item[@"key"] isEqualToString:@"minZoom"])
            cell.lbTime.text = [NSString stringWithFormat:@"%d", _minZoom];
        else if ([item[@"key"] isEqualToString:@"maxZoom"])
            cell.lbTime.text = [NSString stringWithFormat:@"%d", _maxZoom];
        else
            cell.lbTime.text = @"";
        cell.lbTime.textColor = [UIColor blackColor];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        static NSString* const identifierCell = @"OAButtonIconTableViewCell";
        OAButtonIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAButtonIconTableViewCell" owner:self options:nil];
            cell = (OAButtonIconTableViewCell *)[nib objectAtIndex:0];
            cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];;
            [cell.buttonView setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        [cell.buttonView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.buttonView addTarget:self action:@selector(linkButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypePicker])
    {
        static NSString* const identifierCell = @"OACustomPickerTableViewCell";
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACustomPickerCell" owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        int minZoom = _minZoom >= kMinAllowedZoom && _minZoom <= kMaxAllowedZoom ? _minZoom : 1;
        int maxZoom = _maxZoom >= kMinAllowedZoom && _maxZoom <= kMaxAllowedZoom ? _maxZoom : 1;
        [cell.picker selectRow:indexPath.row == 1 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSlider])
    {
        static NSString* const identifierCell = @"OATitleSliderTableViewCell";
        OATitleSliderTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATitleSliderCell" owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = item[@"name"];
            cell.sliderView.value = _app.data.hillshadeAlpha;
            if (_app.data.hillshade != EOATerrainTypeDisabled)
                cell.sliderView.value = _app.data.hillshadeAlpha;
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", cell.sliderView.value * 100, @"%"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSegment])
    {
        static NSString* const identifierCell = @"OASegmentTableViewCell";
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASegmentTableViewCell" owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
        }
        if (cell)
        {
            [cell.segmentControl setSelectedSegmentIndex:_app.data.hillshade == EOATerrainTypeHillshade ? 0 : 1];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeImageDesc])
    {
        static NSString* const identifierCell = @"OAImageDescTableViewCell";
        OAImageDescTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAImageDescTableViewCell" owner:self options:nil];
            cell = (OAImageDescTableViewCell *)[nib objectAtIndex:0];
            cell.descView.text = item[@"desc"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kEstimatedRowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:_pickerIndexPath] ? 162 : UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kCellTypeValue])
    {
       [tblView beginUpdates];

       if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
           [self hideExistingPicker];
       else
       {
           NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
           if ([self pickerIsShown])
               [self hideExistingPicker];

           [self showNewPickerAtIndex:newPickerIndexPath];
           _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
       }
       [tblView endUpdates];
       [tblView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    [tblView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag
{
    if (pickerTag == 1)
        _minZoom = [zoom intValue];
    else if (pickerTag == 2)
        _maxZoom = [zoom intValue];
    [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Selectors

- (void) sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
   // if (_mapSettingType == EMapSettingOverlay)
        _app.data.hillshadeAlpha = slider.value;
   // else if (_mapSettingType == EMapSettingUnderlay)
    //    _app.data.underlayAlpha = slider.value;

}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        if (switchView.isOn)
        {
            [[OsmAndApp instance].data setHillshade:EOATerrainTypeHillshade];
        }
        else
        {
            _app.data.lastHillshade = _app.data.hillshade;
            [_app.data setHillshade:EOATerrainTypeDisabled];
        }
        [tblView beginUpdates];
        if (switchView.isOn)
        {
            [tblView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, _data.count - 2)] withRowAnimation:UITableViewRowAnimationFade];
            [tblView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        }
        else
        {
            [tblView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, _data.count - 2)] withRowAnimation:UITableViewRowAnimationFade];
            [tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [tblView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tblView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
    }
}

- (void) segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl*)sender;
    if (segment)
    {
        if (segment.selectedSegmentIndex == 0)
        {
            [_app.data setHillshade: EOATerrainTypeHillshade];
            //_terrainType = EOATerrainScreenTypeHillshade;

        }
        else if (segment.selectedSegmentIndex == 1)
        {
            [_app.data setHillshade: EOATerrainTypeSlope];
            //_terrainType = EOATerrainScreenTypeSlope;
        }
        [self setupView];
        [tblView reloadData];
    }
}

@end
