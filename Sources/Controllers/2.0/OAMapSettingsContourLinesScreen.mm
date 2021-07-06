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
#import "Localization.h"
#import "OATimeTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAAppSettings.h"
#import "OASegmentSliderTableViewCell.h"
#import "OAMapViewController.h"
#import "OASettingSwitchCell.h"
#import "OAColors.h"
#import "OAColorsTableViewCell.h"
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import <MBProgressHUD.h>
#import "OAAutoObserverProxy.h"
#import "OAImageDescTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAMapViewController.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

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
#define kCellTypeInfo @"imageDescCell"
#define kCellTypeButton @"buttonIconCell"

#define kDefaultDensity @"high"
#define kDefaultWidth @"thin"
#define kDefaultColorScheme @"light_brown"
#define kDefaultZoomLevel @"13"

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAMapSettingsContourLinesScreen() <OACustomPickerTableViewCellDelegate, OAColorsTableViewCellDelegate>

@end

@implementation OAMapSettingsContourLinesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    OAMapViewController *_mapViewController;
    OAMapStyleSettings *_styleSettings;
    NSObject *_dataLock;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;

    NSArray<NSArray *> *_data;
    NSArray<NSString *> *_visibleZoomValues;
    NSArray<NSString *> *_visibleWidthValues;
    NSArray<NSString *> *_visibleDensityValues;
    NSArray<NSString *> *_visibleColorValues;
    NSMutableArray *_colors;
    NSArray<NSDictionary *> *_sectionHeaderFooterTitles;
    NSString *_minZoom;
    NSInteger _currentColor;
    NSArray<OARepositoryResourceItem *> *_mapItems;
    BOOL _showZoomPicker;
    NSString *_defaultColorScheme;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _iapHelper = [OAIAPHelper sharedInstance];
        _dataLock = [[NSObject alloc] init];
        
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
    if (_downloadTaskProgressObserver)
    {
        [_downloadTaskProgressObserver detach];
        _downloadTaskProgressObserver = nil;
    }
    if (_downloadTaskCompletedObserver)
    {
        [_downloadTaskCompletedObserver detach];
        _downloadTaskCompletedObserver = nil;
    }
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
    
    [self deinit];
}

- (void) commonInit
{
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _showZoomPicker = NO;
}

- (void) deinit
{
}

- (void) initData
{
}

- (void) setupView
{
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
    _styleSettings = [OAMapStyleSettings sharedInstance];
    title = OALocalizedString(@"product_title_srtm");
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    tblView.estimatedRowHeight = kEstimatedRowHeight;
    
    OAMapStyleParameter *zoomLevelParameter = [_styleSettings getParameter:kContourLinesZoomLevel];
    NSArray *zoomValues = [zoomLevelParameter possibleValues];
    NSMutableArray<NSString *> *visibleZoomValues = [NSMutableArray array];
    for (OAMapStyleParameterValue* v in zoomValues)
    {
        if (v.name.length > 0 && ![v.name isEqualToString:@"disabled"])
            [visibleZoomValues addObject:v.name];
    }
    _visibleZoomValues = visibleZoomValues;
    
    OAMapStyleParameter *widthParameter = [_styleSettings getParameter:kContourLinesWidth];
    NSArray *widthValues = [widthParameter possibleValuesUnsorted];
    NSMutableArray<NSString *> *visibleWidthValues = [NSMutableArray array];
    for (OAMapStyleParameterValue* v in widthValues)
    {
        if (v.name.length > 0)
            [visibleWidthValues addObject:v.name];
    }
    _visibleWidthValues = visibleWidthValues;
    
    OAMapStyleParameter *densityParameter = [_styleSettings getParameter:kContourLinesDensity];
    NSArray *densityValues = [densityParameter possibleValuesUnsorted];
    NSMutableArray<NSString *> *visibleDensityValues = [NSMutableArray array];
    for (OAMapStyleParameterValue* v in densityValues)
    {
        if (v.name.length > 0)
            [visibleDensityValues addObject:v.name];
    }
    _visibleDensityValues = visibleDensityValues;
    
    _colors = [NSMutableArray new];
    NSMutableArray *colorNames = [NSMutableArray new];
    OAMapStyleParameter *colorParameter = [_styleSettings getParameter:kContourLinesColorScheme];
    NSArray *colorValues = [colorParameter possibleValuesUnsorted];
    BOOL nightMode = _settings.nightMode;
    _defaultColorScheme = kDefaultColorScheme;
    NSNumber *defaultColor = nil;
    for (OAMapStyleParameterValue *value in colorValues)
    {
        NSDictionary<NSString *, NSNumber *> *renderingAttrs;
        NSMutableDictionary<NSString *, NSString *> *additionalSettings = [NSMutableDictionary dictionary];
        if (value.name.length > 0)
            additionalSettings[@"contourColorScheme"] = value.name;
        if (nightMode)
            additionalSettings[@"nightMode"] = @"true";
        
        renderingAttrs = [_mapViewController getRoadRenderingAttributes:@"contourLineColor" additionalSettings:additionalSettings];
        if (renderingAttrs.count > 0)
        {
            if (value.name.length > 0)
            {
                [colorNames addObject:value.name];
                [_colors addObject:renderingAttrs.allValues.firstObject];
            }
            else
            {
                defaultColor = renderingAttrs.allValues.firstObject;
            }
        }
    }
    _visibleColorValues = [colorNames copy];
    if (defaultColor)
    {
        NSUInteger defaultColorIndex = [_colors indexOfObject:defaultColor];
        if (defaultColorIndex != NSNotFound)
            _defaultColorScheme = colorNames[defaultColorIndex];
    }
    _currentColor = [_visibleColorValues indexOfObject:colorParameter.value.length == 0 ? _defaultColorScheme : colorParameter.value];
    
    [self updateAvailableMaps];
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *switchArr = [NSMutableArray array];
    [switchArr addObject:@{
        @"type" : kCellTypeSwitch
    }];
    OAMapStyleParameter *param = nil;
    if ([self isContourLinesOn])
    {
        NSMutableArray *zoomArr = [NSMutableArray array];
        param = [_styleSettings getParameter:kContourLinesZoomLevel];
        if (param)
        {
            [zoomArr addObject:@{
                @"type" : kCellTypeValue,
                @"title" : OALocalizedString(@"display_starting_at_zoom_level"),
                @"parameter" : param
            }];
        }
        if (_showZoomPicker)
        {
            param = [_styleSettings getParameter:kContourLinesZoomLevel];
            if (param)
            {
                [zoomArr addObject:@{
                    @"type" : kCellTypePicker,
                    @"value" : _visibleZoomValues,
                    @"parameter" : param
                }];
            }
        }
        
        NSMutableArray *linesArr = [NSMutableArray array];
        param = [_styleSettings getParameter:kContourLinesColorScheme];
        if (param)
        {
            [linesArr addObject:@{
                @"type" : kCellTypeCollection,
                @"title" : OALocalizedString(@"map_settings_color_scheme"),
                @"parameter" : param
            }];
        }
        param = [_styleSettings getParameter:kContourLinesWidth];
        if (param)
        {
            [linesArr addObject:@{
                @"type" : kCellTypeSlider,
                @"parameter" : param,
                @"name" : OALocalizedString(@"map_settings_line_width")
            }];
        }
        param = [_styleSettings getParameter:kContourLinesDensity];
        if (param)
        {
            [linesArr addObject:@{
                @"type" : kCellTypeSlider,
                @"parameter" : param,
                @"name" : OALocalizedString(@"map_settings_line_density")
            }];
        }
        
        NSMutableArray *availableMapsArr = [NSMutableArray array];
        for (OARepositoryResourceItem* item in _mapItems)
        {
            [availableMapsArr addObject:@{
                @"type" : kCellTypeMap,
                @"item" : item,
            }];
        }

        [result addObject: switchArr];
        [result addObject: zoomArr];
        [result addObject: linesArr];
        if (availableMapsArr.count > 0)
            [result addObject: availableMapsArr];
    }
    else
    {
        NSMutableArray *imageArr = [NSMutableArray array];
        [imageArr addObject:@{
            @"type" : kCellTypeInfo,
            @"desc" : OALocalizedString(@"enable_contour_lines"),
            @"img" : @"img_empty_state_contour_lines.png"
        }];
        [imageArr addObject:@{
            @"type" : kCellTypeButton,
            @"title" : OALocalizedString(@"shared_string_read_more"),
            @"link" : @"",
            @"img" : @"ic_custom_safari.png"
        }];
        [result addObject: switchArr];
        [result addObject: imageArr];
    }
    _data = [NSArray arrayWithArray:result];
    
    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@""),
                        @"footer" : OALocalizedString(@"")
                        }];
    if ([self isContourLinesOn])
    {
        [sectionArr addObject:@{
                            @"header" : OALocalizedString(@""),
                            @"footer" : OALocalizedString(@"map_settings_contour_zoom_level_descr")
                            }];
        [sectionArr addObject:@{
                            @"header" : OALocalizedString(@"map_settings_appearance"),
                            @"footer" : OALocalizedString(@"map_settings_line_density_slowdown_warning")
                            }];
        if (_mapItems.count > 0)
        {
            [sectionArr addObject:@{
                            @"header" : OALocalizedString(@"osmand_live_available_maps"),
                            @"footer" : OALocalizedString(@"map_settings_available_srtm_maps_descr")
                            }];
        }
    }
    else
    {
        [sectionArr addObject:@{
            @"header" : OALocalizedString(@""),
            @"footer" : OALocalizedString(@"")
        }];
    }
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
}

- (void) updateAvailableMaps
{
    CLLocationCoordinate2D loca = [OAResourcesUIHelper getMapLocation];
    [OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion latLon:loca onComplete:^(NSArray<OARepositoryResourceItem *>* res) {
        _mapItems = res;
        [self generateData];
        [tblView reloadData];
    }];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (BOOL) isContourLinesOn
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
    return [parameter.value isEqual:@"disabled"] ? false : true;
}

- (NSString *) getLocalizedParamValue:(NSString *)value
{
    return OALocalizedString([NSString stringWithFormat:@"rendering_value_%@_name", value]);
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

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:kCellTypeSwitch])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.text = [self isContourLinesOn] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = [self isContourLinesOn] ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
            cell.imgView.tintColor = [self isContourLinesOn] ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:[self isContourLinesOn]];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeValue])
    {
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.lbTime.textColor = UIColorFromRGB(color_text_footer);
        }
        OAMapStyleParameter *p = item[@"parameter"];
        cell.lbTitle.text = item[@"title"];
        NSString *title = p.value.length == 0 ? kDefaultZoomLevel : p.value;
        cell.lbTime.text = title;
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypePicker])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.dataArray = _visibleZoomValues;
        OAMapStyleParameter *p = item[@"parameter"];
        NSString *v = p.value.length == 0 ? kDefaultZoomLevel : p.value;
        NSInteger index = [_visibleZoomValues indexOfObject:v];
        if (index != NSNotFound)
            [cell.picker selectRow:index inComponent:0 animated:NO];
        
        cell.delegate = self;
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeCollection])
    {
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAColorsTableViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _colors;
            cell.delegate = self;
            cell.titleLabel.text = item[@"title"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            OAMapStyleParameter *p = item[@"parameter"];
            cell.valueLabel.text = [self getLocalizedParamValue:p.value.length == 0 ? _defaultColorScheme : p.value];
            cell.currentColor = _currentColor;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSlider])
    {
        OASegmentSliderTableViewCell* cell = nil;
        cell = (OASegmentSliderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            OAMapStyleParameter *p = (OAMapStyleParameter *)item[@"parameter"];
            cell.titleLabel.text = item[@"name"];
            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            if ([p.name isEqualToString:kContourLinesDensity])
            {
                NSString *v = p.value.length == 0 ? kDefaultDensity : p.value;
                cell.valueLabel.text = [self getLocalizedParamValue:v];
                cell.numberOfMarks = _visibleDensityValues.count;
                cell.selectedMark = [_visibleDensityValues indexOfObject:v];
                [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
                [cell.sliderView addTarget:self action:@selector(densityChanged:) forControlEvents:UIControlEventTouchUpInside];
            }
            else if ([p.name isEqualToString:kContourLinesWidth])
            {
                NSString *v = p.value.length == 0 ? kDefaultWidth : p.value;
                cell.valueLabel.text = [self getLocalizedParamValue:v];
                cell.numberOfMarks = _visibleWidthValues.count;
                cell.selectedMark = [_visibleWidthValues indexOfObject:v];
                [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
                [cell.sliderView addTarget:self action:@selector(widthChanged:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        static NSString* const repositoryResourceCell = @"repositoryResourceCell";
        static NSString* const downloadingResourceCell = @"downloadingResourceCell";
        OAResourceItem *mapItem = _mapItems[indexPath.row];
        NSString* cellTypeId = mapItem.downloadTask ? downloadingResourceCell : repositoryResourceCell;
        
        uint64_t _sizePkg = mapItem.sizePkg;
        if ((mapItem.resourceType == OsmAndResourceType::SrtmMapRegion || mapItem.resourceType == OsmAndResourceType::HillshadeRegion || mapItem.resourceType == OsmAndResourceType::SlopeRegion)
            && ![_iapHelper.srtm isActive])
        {
            mapItem.disabled = YES;
        }
        NSString *title = mapItem.title;
        NSString *subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourcesUIHelper resourceTypeLocalized:mapItem.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
        if (cell == nil)
        {
            if ([cellTypeId isEqualToString:repositoryResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellTypeId];

                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
                cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

                UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
            else if ([cellTypeId isEqualToString:downloadingResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellTypeId];

                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
                cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

                FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
                progressView.iconView = [[UIView alloc] init];

                cell.accessoryView = progressView;
            }
        }
        
        if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            if (!mapItem.disabled)
            {
                cell.textLabel.textColor = [UIColor blackColor];
                UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
            else
            {
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.accessoryView = nil;
            }
        }
        
        cell.imageView.image = [UIImage templateImageNamed: [OAResourcesUIHelper iconNameByResourseType:mapItem.resourceType]];
        cell.imageView.tintColor = UIColorFromRGB(color_tint_gray);
        cell.textLabel.text = title;
        if (cell.detailTextLabel != nil)
            cell.detailTextLabel.text = subtitle;
        
        if ([cellTypeId isEqualToString:downloadingResourceCell])
            [self updateDownloadingCell:cell indexPath:indexPath];

        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeInfo])
    {
        OAImageDescTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAImageDescTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageDescTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageDescTableViewCell *)[nib objectAtIndex:0];
            cell.descView.text = item[@"desc"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.titleView.text = item[@"title"];
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [tblView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:tblView]];
    if (!indexPath)
        return;
    
    [tblView.delegate tableView: tblView accessoryButtonTappedForRowWithIndexPath: indexPath];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *) view;
        v.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *) view;
        v.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section < _sectionHeaderFooterTitles.count ? _sectionHeaderFooterTitles[section][@"header"] : @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section < _sectionHeaderFooterTitles.count ? _sectionHeaderFooterTitles[section][@"footer"] : @"";
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
    [tblView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kCellTypePicker] || [type isEqualToString:kCellTypeCollection] || [type isEqualToString:kCellTypeSlider] || [type isEqualToString:kCellTypeInfo])
        return nil;
    
    return indexPath;
}

#pragma mark - Selectors

- (void) onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kCellTypeValue])
    {
        _showZoomPicker = !_showZoomPicker;
        [self generateData];
        if (_showZoomPicker)
            [self.tblView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationTop];
        else
            [self.tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationTop];
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceItem *mapItem = _mapItems[indexPath.row];
        if (mapItem.downloadTask != nil)
        {
            [OAResourcesUIHelper offerCancelDownloadOf:mapItem];
        }
        else if ([mapItem isKindOfClass:[OARepositoryResourceItem class]])
        {
            OARepositoryResourceItem* item = (OARepositoryResourceItem*)mapItem;
            if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion
                 || item.resourceType == OsmAndResourceType::SlopeRegion) && ![_iapHelper.srtm isActive])
            {
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
            }
            else
            {
                [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:^(id<OADownloadTask> task) {
                    [self updateAvailableMaps];
                } onTaskResumed:nil];
            }
        }
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        [self linkButtonPressed];
    }
}

- (void) linkButtonPressed
{
    NSURL *url = [NSURL URLWithString:@"https://osmand.net/features/contour-lines-plugin"];
    if ([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void) widthChanged:(UISlider *)sender
{
    if (sender)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
        OASegmentSliderTableViewCell *cell = (OASegmentSliderTableViewCell *) [tblView cellForRowAtIndexPath:indexPath];
        NSInteger index = cell.selectedMark;
        OAMapStyleParameter *p = [_styleSettings getParameter:kContourLinesWidth];
        NSString *currentValue = p.value.length == 0 ? kDefaultWidth : p.value;
        NSString *selectedValue = _visibleWidthValues[index];
        if (![currentValue isEqualToString:selectedValue])
        {
            p.value = selectedValue;
            [_styleSettings save:p];
            [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void) densityChanged:(UISlider *)sender
{
    if (sender)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
        OASegmentSliderTableViewCell *cell = (OASegmentSliderTableViewCell *) [tblView cellForRowAtIndexPath:indexPath];
        NSInteger index = cell.selectedMark;
        OAMapStyleParameter *p = [_styleSettings getParameter:kContourLinesDensity];
        NSString *currentValue = p.value.length == 0 ? kDefaultDensity : p.value;
        NSString *selectedValue = _visibleDensityValues[index];
        if (![currentValue isEqualToString:selectedValue])
        {
            p.value = selectedValue;
            [_styleSettings save:p];
            [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
       OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
       parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
       [_styleSettings save:parameter];
       [self generateData];
       [tblView reloadData];
    }
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void) zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:kContourLinesZoomLevel];
    if (parameter.value != zoom)
    {
        _minZoom = zoom;
        parameter.value = zoom;
        [_styleSettings save:parameter];
        [[OAAppSettings sharedManager].contourLinesZoom set:zoom];
        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - OAColorsTableViewCellDelegate

- (void) colorChanged:(NSInteger)row
{
    OAMapStyleParameter *p = [_styleSettings getParameter:kContourLinesColorScheme];
    NSString *currentValue = p.value.length == 0 ? _defaultColorScheme : p.value;
    NSString *selectedValue = _visibleColorValues[row];
    if (![currentValue isEqualToString:selectedValue])
    {
        _currentColor = row;
        p.value = selectedValue;
        [_styleSettings save:p];
        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
    [self updateDownloadingCell:cell indexPath:indexPath];
}

- (void) updateDownloadingCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    OAResourceItem *mapItem = _mapItems[indexPath.row];
    if (mapItem.downloadTask)
    {
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        
        float progressCompleted = mapItem.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001f && mapItem.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (mapItem.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            progressView.progress = 0.0f;
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
    }
}

- (void) refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        for (int i = 0; i < _mapItems.count; i++)
        {
            OAResourceItem *item = (OAResourceItem *)_mapItems[i];
            if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:3]];
        }
    }
}

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;
        
        [self refreshDownloadingContent:task.key];
    });
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;
        
        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0) {
                id<OADownloadTask> nextTask =  [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
                [nextTask resume];
            }
            [self updateAvailableMaps];
        }
        else
        {
            [self refreshDownloadingContent:task.key];
        }
    });
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
        {
            return;
        }

        [OAManageResourcesViewController prepareData];
        [self updateAvailableMaps];
    });
}

@end
