//
//  OAMapSettingsContourLinesScreen.m
//  OsmAnd Maps
//
//  Created by igor on 20.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSettingsContourLinesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "Localization.h"
#import "OATimeTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAAppSettings.h"
#import "OASegmentSliderTableViewCell.h"

#define kContourLinesDensity @"contourDensity"
#define kContourLinesWidth @"contourWidth"
#define kContourLinesColorScheme @"contourColorScheme"
#define kContourLinesZoomLevel @"contourLines"

#define kCellTypeSwitch @"switchCell"
#define kCellTypeValue @"valueCell"
#define kCellTypePicker @"pickerCell"
#define kCellTypeCollection @"collectionCell"
#define kCellTypeSlider @"sliderCell"
#define kCellTypeMap @"MapCell"

#define kDefaultDensity @"high"
#define kDefaultWidth @"thin"
#define kDefaultColorScheme @"light_brown"
#define kDefaultZoomLevel @"13"


@interface OAMapSettingsContourLinesScreen() <OACustomPickerTableViewCellDelegate>

@end

@implementation OAMapSettingsContourLinesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAMapStyleSettings *_styleSettings;

    NSArray<NSArray *> *_data;
    NSArray *_availableMaps;
    NSArray<NSString *> *_possibleZoomValues;
    NSMutableArray<NSString *> *_visibleWidthValues;
    NSMutableArray<NSString *> *_visibleDensityValues;
    NSArray<NSDictionary *> *_sectionHeaderFooterTitles;
    NSString *_minZoom;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];

        settingsScreen = EMapSettingsScreenContourLines;
        
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

- (void) setupView
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    title = OALocalizedString(@"product_title_srtm");
    _possibleZoomValues = @[@"11", @"12", @"13", @"14", @"15", @"16"];
    _visibleWidthValues = [NSMutableArray new];
    _visibleDensityValues = [NSMutableArray new];
    
    OAMapStyleParameter *width = [_styleSettings getParameter:kContourLinesWidth];
    NSArray *values = width.possibleValues;
    for (OAMapStyleParameterValue *value in values)
    {
        if (![value.name isEqualToString:@""])
            [_visibleWidthValues addObject:value.name];
    }
    
    OAMapStyleParameter *density = [_styleSettings getParameter:kContourLinesDensity];
    values = density.possibleValues;
    for (OAMapStyleParameterValue *value in values)
    {
        if (![value.name isEqualToString:@""])
            [_visibleDensityValues addObject:value.name];
    }
    
    
//    OAMapStyleParameter *zoom = [_styleSettings getParameter:kContourLinesZoomLevel]
//    _minZoom =  ;
    
 //   NSArray *tmpParameters = [styleSettings getAllParameters];
//    NSMutableArray *tmpList = [NSMutableArray array];
//
//    for (OAMapStyleParameter *p in tmpParameters)
//    {
//        if ([p.name isEqual: kContourLinesDensity] || [p.name isEqual: kContourLinesWidth] || [p.name isEqual: kContourLinesColorScheme] || [p.name isEqual: kContourLinesZoomLevel])
//            [tmpList addObject: p];
//    }
//    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
//    parameters = [tmpList sortedArrayUsingDescriptors:@[sd]];
    
    NSMutableArray *switchArr = [NSMutableArray array];
    [switchArr addObject:@{
        @"type" : kCellTypeSwitch
    }];
    
    NSMutableArray *zoomArr = [NSMutableArray array];
    [zoomArr addObject:@{
        @"type" : kCellTypeValue,
        @"title" : OALocalizedString(@"display_from_zoom_level"),
        @"parameter" : [_styleSettings getParameter:kContourLinesZoomLevel]
    }];
    [zoomArr addObject:@{
        @"type" : kCellTypePicker,
        @"value" : _possibleZoomValues,
        @"parameter" : [_styleSettings getParameter:kContourLinesZoomLevel]
    }];
    
    NSMutableArray *linesArr = [NSMutableArray array];
//    [linesArr addObject:@{
//        @"type" : kCellTypeCollection,
//        @"name" : OALocalizedString(@"color_scheme"),
//        @"parameter" : [_styleSettings getParameter:kContourLinesColorScheme]
//    }];
    [linesArr addObject:@{
        @"type" : kCellTypeSlider,
        @"parameter" : [_styleSettings getParameter:kContourLinesWidth],
        @"name" : OALocalizedString(@"line_width")
    }];
    [linesArr addObject:@{
        @"type" : kCellTypeSlider,
        @"parameter" : [_styleSettings getParameter:kContourLinesDensity],
        @"name" : OALocalizedString(@"line_density")
    }];
    
    NSMutableArray *availableMapsArr = [NSMutableArray array];
    if (_availableMaps)
    {
       //fill array
        //kCellTypeMap
    }
    
    NSMutableArray *result = [NSMutableArray array];
    [result addObject: switchArr];
    [result addObject: zoomArr];
    [result addObject: linesArr];
    if (_availableMaps)
        [result addObject: availableMapsArr];
    
    _data = [NSArray arrayWithArray:result];
    
    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@""),
                        @"footer" : OALocalizedString(@"")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@""),
                        @"footer" : OALocalizedString(@"contour_zoom_level_descr")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"appearance"),
                        @"footer" : OALocalizedString(@"line_density_slowdown_warning")
                        }];
    if (_availableMaps)
    {
        [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"available_srtm_maps"),
                        @"footer" : OALocalizedString(@"available_srtm_maps_descr")
                        }];
    }
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];

}

- (NSDictionary*) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (BOOL) isContourLinesOn
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
    return [parameter.value isEqual:@"disabled"] ? false : true;
}

- (NSString *) switchCellTitle
{
    if ([self isContourLinesOn])
        return OALocalizedString(@"shared_string_enabled");
    else
        return OALocalizedString(@"rendering_value_disabled_name");
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
   
//        OAMapStyleParameter *p = d[@"value"];
//        static NSString* const identifierCell = @"OASettingsTableViewCell";
//        OASettingsTableViewCell* cell = nil;
//
//        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
//        if (cell == nil)
//        {
//            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
//            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
//        }
//
//        if (cell)
//        {
//            if ([p.name isEqualToString:@"contourLines"])
//                [cell.textView setText:OALocalizedString(@"display_starting_at_zoom_level")];
//            else
//                [cell.textView setText:p.title];
//
//            [cell.descriptionView setText:[p getValueTitle]];
//        }
//
//        return cell;

    if ([item[@"type"] isEqualToString: kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.textView setText:[self switchCellTitle]];
            [cell.switchView setOn:[self isContourLinesOn]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
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
        OAMapStyleParameter *p = item[@"parameter"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = [p getValueTitle];
        cell.lbTime.textColor = [UIColor blackColor];

        return cell;
    }
    
    else if ([item[@"type"] isEqualToString: kCellTypePicker])
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
        OAMapStyleParameter *p = item[@"parameter"];
//        NSInteger index = [_possibleZoomValues indexOfObject:[p getValueTitle]];
//        [cell.picker selectRow:index inComponent:0 animated:NO];
        cell.delegate = self;
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString: kCellTypeCollection])
    {
        
    }
    
    else if ([item[@"type"] isEqualToString: kCellTypeSlider])
    {
        static NSString* const identifierCell = @"OASegmentSliderTableViewCell";
        OASegmentSliderTableViewCell* cell = nil;
        cell = (OASegmentSliderTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASegmentSliderCell" owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            OAMapStyleParameter *p = (OAMapStyleParameter *)item[@"parameter"];
//            OAMapStyleParameterValue *value = p.possibleValues[[p.name isEqualToString:kContourLinesDensity] ? 3 : 1];
//            p.value = value.name;
//            [_styleSettings save:p];
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = [p getValueTitle];
//            for ( OAMapStyleParameterValue *value in p.possibleValues)
//            {
//                NSLog(@"++%@", value.name);
//                NSLog(@"--%@", value.title);
//            }
            NSString *currentValueName = p.value;
            if ([p.value isEqualToString:@""])
            {
                currentValueName =  [p.name isEqualToString:kContourLinesDensity] ? kDefaultDensity : kDefaultWidth;
            }
            
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            if ([p.name  isEqualToString:kContourLinesDensity])
            {
                [cell.sliderView addTarget:self action:@selector(widthChanged:) forControlEvents:UIControlEventValueChanged];
                cell.sliderView.value = [_visibleDensityValues indexOfObject:currentValueName]/(_visibleDensityValues.count - 1);
            }
            else if ([p.name isEqualToString:kContourLinesWidth])
            {
                [cell.sliderView addTarget:self action:@selector(densityChanged:) forControlEvents:UIControlEventValueChanged];
                cell.sliderView.value = [_visibleWidthValues indexOfObject:currentValueName]/(_visibleWidthValues.count - 1);
            }
            
            
        }
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString: kCellTypeMap])
    {
    }
    
    else
        return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kEstimatedRowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self getItem:indexPath][@"type"] isEqualToString: kCellTypePicker])
        return 162.0;
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [_sectionHeaderFooterTitles[section][@"header"] isEqualToString:@""] ? 0.0 : 34.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tblView deselectRowAtIndexPath:indexPath animated:NO];
//    NSDictionary *d = arr[indexPath.row];
//    if ([d[@"type"] isEqualToString: @"parameter"])
//    {
//        OAMapStyleParameter *p = d[@"value"];
//        if (p.dataType != OABoolean)
//        {
//            OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];
//
//            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
//
//            [tableView deselectRowAtIndexPath:indexPath animated:NO];
//        }
//    }
//    else
//    {
//        OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
//        parameter.value = ![self isContourLinesOn] ? [_settings.contourLinesZoom get] : @"disabled";
//        [_styleSettings save:parameter];
//        [tblView reloadData];
//    }
}

- (void) widthChanged:(UISlider*)sender
{
    
}

- (void) densityChanged:(UISlider*)sender
{
    
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
        parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [_styleSettings save:parameter];
    }
    [tblView reloadData];
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag
{
    _minZoom = zoom;
    OAMapStyleParameter *parameter = [_styleSettings getParameter:kContourLinesZoomLevel];
    parameter.value = zoom;
    [_styleSettings save:parameter];
    [[OAAppSettings sharedManager].contourLinesZoom set:zoom];
    [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
