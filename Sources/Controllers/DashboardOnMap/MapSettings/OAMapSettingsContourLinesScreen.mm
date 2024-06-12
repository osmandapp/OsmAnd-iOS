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
#import "OAValueTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAAppSettings.h"
#import "OASegmentSliderTableViewCell.h"
#import "OAMapViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAColorsTableViewCell.h"
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import <MBProgressHUD.h>
#import "OAAutoObserverProxy.h"
#import "OAImageDescTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAMapViewController.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"
#import "OASegmentedSlider.h"
#import "OALinks.h"
#import "OADownloadingCellMultipleResourceHelper.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

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

@interface OAMapSettingsContourLinesScreen() <OACustomPickerTableViewCellDelegate, OAColorsTableViewCellDelegate, OADownloadingCellResourceHelperDelegate>

@end

@implementation OAMapSettingsContourLinesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    OAMapViewController *_mapViewController;
    OAMapStyleSettings *_styleSettings;
    OADownloadingCellMultipleResourceHelper *_downloadingCellResourceHelper;
    NSObject *_dataLock;

    NSArray<NSArray *> *_data;
    NSArray<NSString *> *_visibleZoomValues;
    NSArray<NSString *> *_visibleWidthValues;
    NSArray<NSString *> *_visibleDensityValues;
    NSArray<NSString *> *_visibleColorValues;
    NSMutableArray *_colors;
    NSArray<NSDictionary *> *_sectionHeaderFooterTitles;
    NSString *_minZoom;
    NSInteger _currentColor;
    NSArray<OAMultipleResourceItem *> *_mapMultipleItems;
    NSArray<OAResourceItem *> *_multipleDownloadingItems;
    NSMutableArray<OAMultipleResourceItem *> *_collectedRegionMultipleMapItems;
    NSMutableArray<OARepositoryResourceItem *> *_collectedRegionMaps;
    NSString *_collectiongPreviousRegionId;
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
        [self setupDownloadingCellHelper];
        [self initData];
    }
    return self;
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
    _styleSettings = [OAMapStyleSettings sharedInstance];
    title = OALocalizedString(@"map_settings_topography");
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    tblView.estimatedRowHeight = kEstimatedRowHeight;
    
    OAMapStyleParameter *zoomLevelParameter = [_styleSettings getParameter:CONTOUR_LINES];
    NSArray *zoomValues = [zoomLevelParameter possibleValues];
    NSMutableArray<NSString *> *visibleZoomValues = [NSMutableArray array];
    for (OAMapStyleParameterValue* v in zoomValues)
    {
        if (v.name.length > 0 && ![v.name isEqualToString:@"disabled"])
            [visibleZoomValues addObject:v.name];
    }
    _visibleZoomValues = visibleZoomValues;
    
    OAMapStyleParameter *widthParameter = [_styleSettings getParameter:CONTOUR_WIDTH_ATTR];
    NSArray *widthValues = [widthParameter possibleValuesUnsorted];
    NSMutableArray<NSString *> *visibleWidthValues = [NSMutableArray array];
    for (OAMapStyleParameterValue* v in widthValues)
    {
        if (v.name.length > 0)
            [visibleWidthValues addObject:v.name];
    }
    _visibleWidthValues = visibleWidthValues;
    
    OAMapStyleParameter *densityParameter = [_styleSettings getParameter:CONTOUR_DENSITY_ATTR];
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
    OAMapStyleParameter *colorParameter = [_styleSettings getParameter:CONTOUR_COLOR_SCHEME_ATTR];
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
    
    [self fetchResources];
    [self generateData];
}

- (void)onRotation
{
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    [tblView reloadData];
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
        param = [_styleSettings getParameter:CONTOUR_LINES];
        if (param)
        {
            [zoomArr addObject:@{
                @"type" : kCellTypeValue,
                @"title" : OALocalizedString(@"show_from_zoom_level"),
                @"parameter" : param
            }];
        }
        if (_showZoomPicker)
        {
            param = [_styleSettings getParameter:CONTOUR_LINES];
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
        param = [_styleSettings getParameter:CONTOUR_COLOR_SCHEME_ATTR];
        if (param)
        {
            [linesArr addObject:@{
                @"type" : kCellTypeCollection,
                @"title" : OALocalizedString(@"srtm_color_scheme"),
                @"parameter" : param
            }];
        }
        param = [_styleSettings getParameter:CONTOUR_WIDTH_ATTR];
        if (param)
        {
            [linesArr addObject:@{
                @"type" : kCellTypeSlider,
                @"parameter" : param,
                @"name" : OALocalizedString(@"rendering_attr_depthContourWidth_name")
            }];
        }
        param = [_styleSettings getParameter:CONTOUR_DENSITY_ATTR];
        if (param)
        {
            [linesArr addObject:@{
                @"type" : kCellTypeSlider,
                @"parameter" : param,
                @"name" : OALocalizedString(@"map_settings_line_density")
            }];
        }
        
        NSMutableArray *availableMapsArr = [NSMutableArray array];
        for (OAMultipleResourceItem* item in _mapMultipleItems)
        {
            [availableMapsArr addObject:@{
                @"type" : kCellTypeMap,
                @"item" : item,
                @"resourceId" : [item getResourceId]
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
                            @"header" : OALocalizedString(@"shared_string_appearance"),
                            @"footer" : OALocalizedString(@"map_settings_line_density_slowdown_warning")
                            }];
        if (_mapMultipleItems.count > 0)
        {
            [sectionArr addObject:@{
                            @"header" : OALocalizedString(@"available_maps"),
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

- (void)setupDownloadingCellHelper
{
    _downloadingCellResourceHelper = [[OADownloadingCellMultipleResourceHelper alloc] init];
    _downloadingCellResourceHelper.hostViewController = self.vwController;
    [_downloadingCellResourceHelper setHostTableView:self.tblView];
    _downloadingCellResourceHelper.delegate = self;
    _downloadingCellResourceHelper.rightIconStyle = EOADownloadingCellRightIconTypeHideIconAfterDownloading;
}

- (NSArray<NSArray <NSDictionary *> *> *)data
{
    return _data;
}

- (void) fetchResources
{
    CLLocationCoordinate2D loc = [OAResourcesUIHelper getMapLocation];
    [OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion latLon:loc onComplete:^(NSArray<OARepositoryResourceItem *>* res) {
        @synchronized(_dataLock)
        {
            if (!res || res.count == 0)
                return;
            
            NSArray *sortedMaps = [res sortedArrayUsingComparator:^NSComparisonResult(OARepositoryResourceItem* obj1, OARepositoryResourceItem* obj2) {
                return [obj1.worldRegion.localizedName.lowercaseString compare:obj2.worldRegion.localizedName.lowercaseString];
            }];
            
            _collectedRegionMultipleMapItems = [NSMutableArray new];
            _collectedRegionMaps = [NSMutableArray new];
            _collectiongPreviousRegionId = nil;
            
            for (OARepositoryResourceItem *map in sortedMaps)
            {
                if (!_collectiongPreviousRegionId)
                {
                    [self startCollectingNewItem:_collectedRegionMaps map:map collectiongPreviousRegionId:_collectiongPreviousRegionId];
                }
                else if (!_collectiongPreviousRegionId || ![map.worldRegion.regionId isEqualToString:_collectiongPreviousRegionId])
                {
                    [self saveCollectedItemIfNeeded];
                    [self startCollectingNewItem:_collectedRegionMaps map:map collectiongPreviousRegionId:_collectiongPreviousRegionId];
                }
                else
                {
                    [self appendToCollectingItem:map];
                }
            }
            [self saveCollectedItemIfNeeded];
            
            _mapMultipleItems = [NSArray arrayWithArray:_collectedRegionMultipleMapItems];
            [self generateData];
            [_downloadingCellResourceHelper cleanCellCache];
            [tblView reloadData];
        }
    }];
}

- (void) startCollectingNewItem:(NSMutableArray<OARepositoryResourceItem *> *)collectedRegionMaps map:(OARepositoryResourceItem *)map collectiongPreviousRegionId:(NSString *)collectiongPreviousRegionId
{
    _collectiongPreviousRegionId = map.worldRegion.regionId;
    _collectedRegionMaps = [NSMutableArray arrayWithObject:map];
}

- (void) appendToCollectingItem:(OARepositoryResourceItem *)map
{
    [_collectedRegionMaps addObject:map];
}

- (void) saveCollectedItemIfNeeded
{
    if (_collectedRegionMaps.count > 1)
    {
        OAMultipleResourceItem *regionMultipleItem = [[OAMultipleResourceItem alloc] initWithType:OsmAndResourceType::SrtmMapRegion items:[NSArray arrayWithArray:_collectedRegionMaps]];
        regionMultipleItem.worldRegion = _collectedRegionMaps[0].worldRegion;
        [_collectedRegionMultipleMapItems addObject:regionMultipleItem];
    }
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
    NSString *paramName = [NSString stringWithFormat:@"rendering_value_%@_name", value];
    NSString *localizedParamName = OALocalizedString(paramName);
    return [localizedParamName isEqualToString:paramName] ? value :localizedParamName;
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
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = [self isContourLinesOn] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");

            NSString *imgName = [self isContourLinesOn] ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.leftIconView.image = [UIImage templateImageNamed:imgName];
            cell.leftIconView.tintColor = [self isContourLinesOn] ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];

            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:[self isContourLinesOn]];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeValue])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            OAMapStyleParameter *p = item[@"parameter"];
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = p.value.length == 0 ? kDefaultZoomLevel : p.value;
        }
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
            [cell showLabels:YES topRight:YES bottomLeft:NO bottomRight:NO];
        }
        if (cell)
        {
            OAMapStyleParameter *p = (OAMapStyleParameter *)item[@"parameter"];
            cell.topLeftLabel.text = item[@"name"];
            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            if ([p.name isEqualToString:CONTOUR_DENSITY_ATTR])
            {
                NSString *v = p.value.length == 0 ? kDefaultDensity : p.value;
                cell.topRightLabel.text = [self getLocalizedParamValue:v];
                [cell.sliderView setNumberOfMarks:_visibleDensityValues.count additionalMarksBetween:0];
                cell.sliderView.selectedMark = [_visibleDensityValues indexOfObject:v];
                [cell.sliderView addTarget:self action:@selector(densityChanged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            }
            else if ([p.name isEqualToString:CONTOUR_WIDTH_ATTR])
            {
                NSString *v = p.value.length == 0 ? kDefaultWidth : p.value;
                cell.topRightLabel.text = [self getLocalizedParamValue:v];
                [cell.sliderView setNumberOfMarks:_visibleWidthValues.count additionalMarksBetween:0];
                cell.sliderView.selectedMark = [_visibleWidthValues indexOfObject:v];
                [cell.sliderView addTarget:self action:@selector(widthChanged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            }
            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceSwiftItem *mapItem = [[OAResourceSwiftItem alloc] initWithItem:item[@"item"]];
        NSString *resourceId = item[@"resourceId"];
        return [_downloadingCellResourceHelper getOrCreateSwiftCellForResourceId:resourceId swiftResourceItem:mapItem];
    }
    else if ([item[@"type"] isEqualToString:kCellTypeInfo])
    {
        OAImageDescTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAImageDescTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageDescTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageDescTableViewCell *)[nib objectAtIndex:0];
            cell.descView.text = item[@"desc"];
            cell.iconView.image = [UIImage rtlImageNamed:item[@"img"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        OARightIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.rightIconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) accessoryButtonPressed:(UIControl *)button withEvent:(UIEvent *)event
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
        v.textLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    }
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *) view;
        v.textLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_showZoomPicker)
                [self.tblView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationTop];
            else
                [self.tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationTop];
        });
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        NSString *resourceId = item[@"resourceId"];
        [_downloadingCellResourceHelper onCellClicked:resourceId];
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        [self linkButtonPressed];
    }
}

- (void) linkButtonPressed
{
    NSURL *url = [NSURL URLWithString:kOsmAndFeaturesContourLinesPlugin];
    if ([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void) widthChanged:(UISlider *)sender
{
    if (sender)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
        OASegmentSliderTableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
        NSInteger index = cell.sliderView.selectedMark;
        OAMapStyleParameter *p = [_styleSettings getParameter:CONTOUR_WIDTH_ATTR];
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
        OASegmentSliderTableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
        NSInteger index = cell.sliderView.selectedMark;
        OAMapStyleParameter *p = [_styleSettings getParameter:CONTOUR_DENSITY_ATTR];
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
        [_downloadingCellResourceHelper cleanCellCache];
       [tblView reloadData];
    }
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void) customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:CONTOUR_LINES];
    if (parameter.value != value)
    {
        _minZoom = value;
        parameter.value = value;
        [_styleSettings save:parameter];
        [[OAAppSettings sharedManager].contourLinesZoom set:value];
        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - OAColorsTableViewCellDelegate

- (void) colorChanged:(NSInteger)row
{
    OAMapStyleParameter *p = [_styleSettings getParameter:CONTOUR_COLOR_SCHEME_ATTR];
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

#pragma mark - OADownloadingCellResourceHelperDelegate

- (void)onDownldedResourceInstalled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchResources];
        [self generateData];
        [_downloadingCellResourceHelper cleanCellCache];
        [self.tblView reloadData];
    });
}

@end
