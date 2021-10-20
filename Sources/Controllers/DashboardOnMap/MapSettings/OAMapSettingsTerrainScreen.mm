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
#import "OATitleRightIconCell.h"
#import "OAImageDescTableViewCell.h"
#import "OAImageTextViewCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAResourcesUIHelper.h"
#import "OAMapLayers.h"
#import "OATerrainMapLayer.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"
#import "OAAutoObserverProxy.h"

#define kMinAllowedZoom 1
#define kMaxAllowedZoom 22

#define kMaxMissingDataZoomShift 5

#define kCellTypeSwitch @"switchCell"
#define kCellTypeValue @"valueCell"
#define kCellTypePicker @"pickerCell"
#define kCellTypeSlider @"sliderCell"
#define kCellTypeMap @"mapCell"
#define kCellTypeSegment @"segmentCell"
#define kCellTypeButton @"buttonIconCell"

#define kZoomSection 2

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAMapSettingsTerrainScreen() <OACustomPickerTableViewCellDelegate>

@end

@implementation OAMapSettingsTerrainScreen
{
    OsmAndAppInstance _app;
    OAMapStyleSettings *_styleSettings;
    OAIAPHelper *_iapHelper;
    
    NSArray<NSArray *> *_dataDisabled;
    NSArray<NSArray *> *_data;
    NSArray* _sectionHeaderFooterTitles;
    NSIndexPath *_pickerIndexPath;
    
    NSInteger _minZoomHillshade;
    NSInteger _maxZoomHillshade;
    NSInteger _minZoomSlope;
    NSInteger _maxZoomSlope;
    NSArray<NSString *> *_possibleZoomValues;
    
    NSObject *_dataLock;
    NSArray<OARepositoryResourceItem *> *_mapItems;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];
        
        settingsScreen = EMapSettingsScreenTerrain;
        
        vwController = viewController;
        tblView = tableView;
        
        _dataLock = [[NSObject alloc] init];
        
        [self setupView];
        [self generateData];
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
}

- (void) generateData
{
    EOATerrainType type = _app.data.terrainType;
    switch (type) {
        case EOATerrainTypeHillshade:
        {
            _minZoomHillshade = _app.data.hillshadeMinZoom;
            _maxZoomHillshade = _app.data.hillshadeMaxZoom;
            break;
        }
        case EOATerrainTypeSlope:
        {
            _minZoomSlope = _app.data.slopeMinZoom;
            _maxZoomSlope = _app.data.slopeMaxZoom;
            break;
        }
        default:
            break;
    }
    
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
    
    NSMutableArray *slopeLegendArr = [NSMutableArray new];
    if (_app.data.terrainType == EOATerrainTypeSlope)
    {
        [slopeLegendArr addObject:@{
            @"type" : [OAImageTextViewCell getCellIdentifier],
            @"descr" : OALocalizedString(@"map_settings_slopes_legend"),
            @"img" : @"img_legend_slope",
            @"url" : @"https://en.wikipedia.org/wiki/Grade_(slope)",
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

    [result addObject:switchArr];
    [result addObject:transparencyArr];
    [result addObject:zoomArr];
    if (slopeLegendArr.count > 0)
        [result addObject:slopeLegendArr];
    if (availableMapsArr.count > 0)
        [result addObject: availableMapsArr];

    _data = [NSArray arrayWithArray:result];

    EOATerrainType terrainType = _app.data.terrainType;
    NSString *availableSectionFooter =  @"";
    if (terrainType == EOATerrainTypeHillshade)
        availableSectionFooter = OALocalizedString(@"map_settings_add_maps_hillshade");
    else if (terrainType == EOATerrainTypeSlope)
        availableSectionFooter = OALocalizedString(@"map_settings_add_maps_slopes");
    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{}];
    [sectionArr addObject:@{}];
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"res_zoom_levels"),
        @"footer" : OALocalizedString(@"map_settings_zoom_level_description")
    }];
    if (terrainType == EOATerrainTypeSlope)
    {
        [sectionArr addObject:@{
            @"header" : OALocalizedString(@"map_settings_legend"),
        }];
    }
    
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"osmand_live_available_maps"),
        @"footer" : availableSectionFooter
    }];
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
}

- (void) setupDisabledData:(NSMutableArray *)result
{
    NSMutableArray *imageArr = [NSMutableArray array];
    [imageArr addObject:@{
        @"type" : [OAImageDescTableViewCell getCellIdentifier],
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

- (NSArray<NSString *> *) getPossibleZoomValues
{
    NSMutableArray *res = [NSMutableArray new];
    OsmAnd::ZoomLevel maxZoom = OARootViewController.instance.mapPanel.mapViewController.mapLayers.terrainMapLayer.getMaxZoom;
    int maxVisivleZoom = maxZoom + kMaxMissingDataZoomShift;
    for (int i = 1; i <= maxVisivleZoom; i++)
    {
        [res addObject:[NSString stringWithFormat:@"%d", i]];
    }
    return res;
}

- (void) setupView
{
    title = OALocalizedString(@"shared_string_terrain");

    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    _possibleZoomValues = [self getPossibleZoomValues];
    
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
    if ([self isTerrainOn])
        [self updateAvailableMaps];
}

- (void)onRotation
{
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    [tblView reloadData];
}

- (void)initData {
}

- (void) updateAvailableMaps
{
    CLLocationCoordinate2D loc = [OAResourcesUIHelper getMapLocation];
    OsmAnd::ResourcesManager::ResourceType resType = OsmAnd::ResourcesManager::ResourceType::HillshadeRegion;
    if (_app.data.terrainType == EOATerrainTypeSlope)
        resType = OsmAnd::ResourcesManager::ResourceType::SlopeRegion;
    else if (_app.data.terrainType == EOATerrainTypeHillshade)
        resType = OsmAnd::ResourcesManager::ResourceType::HillshadeRegion;
    
    [OAResourcesUIHelper getMapsForType:resType latLon:loc onComplete:^(NSArray<OARepositoryResourceItem *>* res) {
        @synchronized(_dataLock)
        {
            _mapItems = res;
            
            if (![self isTerrainOn])
                return;
            
            BOOL hasDownloads = [_data.lastObject.firstObject[@"type"] isEqualToString:kCellTypeMap];
            if (_mapItems.count > 0 && !hasDownloads)
            {
                [tblView beginUpdates];
                [tblView insertSections:[[NSIndexSet alloc] initWithIndex:tblView.numberOfSections] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self generateData];
                [tblView endUpdates];
            }
            else if (hasDownloads)
            {
                
                [self generateData];
                if (_mapItems.count > 0)
                    [tblView reloadSections:[[NSIndexSet alloc] initWithIndex:tblView.numberOfSections - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
                else
                    [tblView deleteSections:[[NSIndexSet alloc] initWithIndex:tblView.numberOfSections - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }];
}

- (void) linkButtonPressed
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
    return nil;
}

- (NSString *) getSwitchSectionFooter
{
    if (_app.data.terrainType == EOATerrainTypeHillshade)
        return OALocalizedString(@"map_settings_hillshade_description");
    else if (_app.data.terrainType == EOATerrainTypeSlope)
        return OALocalizedString(@"map_settings_slopes_description");
    else
        return @"";
}

- (NSInteger) getMinZoom
{
    EOATerrainType terrainType = _app.data.terrainType;
    if (terrainType == EOATerrainTypeHillshade)
        return _minZoomHillshade;
    else if (terrainType == EOATerrainTypeSlope)
        return _minZoomSlope;
    return 0;
}

- (NSInteger) getMaxZoom
{
    EOATerrainType terrainType = _app.data.terrainType;
    if (terrainType == EOATerrainTypeHillshade)
        return _maxZoomHillshade;
    else if (terrainType == EOATerrainTypeSlope)
        return _maxZoomSlope;
    return 0;
}

- (void) setMinZoom:(NSInteger)zoom
{
    EOATerrainType terrainType = _app.data.terrainType;
    if (terrainType == EOATerrainTypeHillshade)
        _minZoomHillshade = zoom;
    else if (terrainType == EOATerrainTypeSlope)
        _minZoomSlope = zoom;
}

- (void) setMaxZoom:(NSInteger)zoom
{
    EOATerrainType terrainType = _app.data.terrainType;
    if (terrainType == EOATerrainTypeHillshade)
        _maxZoomHillshade = zoom;
    else if (terrainType == EOATerrainTypeSlope)
        _maxZoomSlope = zoom;
}

- (BOOL) isTerrainOn
{
    return [OsmAndApp instance].data.terrainType != EOATerrainTypeDisabled;
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
            cell.textView.text = [self isTerrainOn] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = [self isTerrainOn] ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
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
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lbTitle.text = item[@"title"];
        if ([item[@"key"] isEqualToString:@"minZoom"])
            cell.lbTime.text = [NSString stringWithFormat:@"%ld", [self getMinZoom]];
        else if ([item[@"key"] isEqualToString:@"maxZoom"])
            cell.lbTime.text = [NSString stringWithFormat:@"%ld", [self getMaxZoom]];
        else
            cell.lbTime.text = @"";
        cell.lbTime.textColor = [UIColor blackColor];
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
    else if ([item[@"type"] isEqualToString:kCellTypePicker])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        NSInteger minZoom = [self getMinZoom] >= kMinAllowedZoom && [self getMinZoom] <= kMaxAllowedZoom ? [self getMinZoom] : 1;
        NSInteger maxZoom = [self getMaxZoom] >= kMinAllowedZoom && [self getMaxZoom] <= kMaxAllowedZoom ? [self getMaxZoom] : 1;
        [cell.picker selectRow:indexPath.row == 1 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSlider])
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = item[@"name"];
            if ([self isTerrainOn])
                cell.sliderView.value = _app.data.terrainType == EOATerrainTypeSlope ? _app.data.slopeAlpha : _app.data.hillshadeAlpha;
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", cell.sliderView.value * 100, @"%"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSegment])
    {
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.segmentControl removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
            [cell.segmentControl setSelectedSegmentIndex:_app.data.terrainType == EOATerrainTypeHillshade ? 0 : 1];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAImageDescTableViewCell getCellIdentifier]])
    {
        OAImageDescTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAImageDescTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageDescTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageDescTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.descView.text = item[@"desc"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAImageTextViewCell getCellIdentifier]])
    {
        OAImageTextViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAImageTextViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageTextViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageTextViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showExtraDesc:NO];
        }
        if (cell)
        {
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];

            NSString *descr = item[@"descr"];
            if (descr && descr.length > 0)
            {
                NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:descr attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]}];
                NSRange range = [descr rangeOfString:@" " options:NSBackwardsSearch];
                if (range.location != NSNotFound)
                {
                    NSDictionary *linkAttributes = @{NSLinkAttributeName: item[@"url"], NSFontAttributeName: [UIFont systemFontOfSize:15]};
                    [str setAttributes:linkAttributes range:NSMakeRange(range.location + 1, descr.length - range.location - 1)];
                }
                cell.descView.attributedText = str;
            }
            else
            {
                cell.descView.attributedText = nil;
            }
            
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
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
        NSString *subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:mapItem.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

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

                UIImage* iconImage = [UIImage imageNamed:@"ic_custom_download"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
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
                UIImage* iconImage = [UIImage imageNamed:@"ic_custom_download"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
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
        
        cell.imageView.image = [UIImage templateImageNamed:(_app.data.terrainType == EOATerrainTypeHillshade ? @"ic_custom_hillshade" : @"ic_action_slope")];
        cell.imageView.tintColor = UIColorFromRGB(color_tint_gray);
        cell.textLabel.text = title;
        if (cell.detailTextLabel != nil)
            cell.detailTextLabel.text = subtitle;
        
        if ([cellTypeId isEqualToString:downloadingResourceCell])
            [self updateDownloadingCell:cell indexPath:indexPath];

        return cell;
    }
    
    return nil;
}

- (void) accessoryButtonPressed:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [tblView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:tblView]];
    if (!indexPath)
        return;
    
    [tblView.delegate tableView:tblView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
}

- (void) onItemClicked:(NSIndexPath *)indexPath
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

#pragma mark - UITableViewDelegate


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
    [tblView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)updatePickerCell:(NSInteger) value
{
    UITableViewCell *cell = [tblView cellForRowAtIndexPath:_pickerIndexPath];
    if ([cell isKindOfClass:OACustomPickerTableViewCell.class])
    {
        OACustomPickerTableViewCell *cellRes = (OACustomPickerTableViewCell *) cell;
        [cellRes.picker selectRow:[self getMinZoom] - 1 inComponent:0 animated:NO];
    }
}

- (void)zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag
{
    NSInteger value = [zoom integerValue];
    EOATerrainType type = _app.data.terrainType;
    if (pickerTag == 1)
    {
        if (value <= [self getMaxZoom])
        {
            [self setMinZoom:value];
            if (type == EOATerrainTypeHillshade)
            {
                _app.data.hillshadeMinZoom = [self getMinZoom];
            }
            else if (type == EOATerrainTypeSlope)
            {
                _app.data.slopeMinZoom = [self getMinZoom];
            }
        }
        else
        {
            [self setMinZoom:[self getMaxZoom]];
            [self updatePickerCell:[self getMaxZoom] - 1];
        }
    }
    else if (pickerTag == 2)
    {
        if (value >= [self getMinZoom])
        {
            [self setMaxZoom:value];
            if (type == EOATerrainTypeHillshade)
            {
                _app.data.hillshadeMaxZoom = [self getMaxZoom];
            }
            else if (type == EOATerrainTypeSlope)
            {
                _app.data.slopeMaxZoom = [self getMaxZoom];
            }
        }
        else
        {
            [self setMaxZoom:[self getMinZoom]];
            [self updatePickerCell:[self getMinZoom] - 1];
        }
    }
    [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Selectors

- (void) sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    EOATerrainType type = _app.data.terrainType;
    if (type == EOATerrainTypeHillshade)
    {
        _app.data.hillshadeAlpha = slider.value;
    }
    else if (type == EOATerrainTypeSlope)
    {
        _app.data.slopeAlpha = slider.value;
    }
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        if (switchView.isOn)
        {
            EOATerrainType prevType = _app.data.lastTerrainType;
            [_app.data setTerrainType:prevType != EOATerrainTypeDisabled ? prevType : EOATerrainTypeHillshade];
            [self updateAvailableMaps];
        }
        else
        {
            _app.data.lastTerrainType = _app.data.terrainType;
            [_app.data setTerrainType:EOATerrainTypeDisabled];
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
            [_app.data setTerrainType: EOATerrainTypeHillshade];
        }
        else if (segment.selectedSegmentIndex == 1)
        {
            [_app.data setTerrainType: EOATerrainTypeSlope];
        }
        [self generateData];
        [tblView reloadData];
        [self updateAvailableMaps];
    }
}

#pragma mark - Downloading cell progress methods

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
        [self updateDownloadingCell:cell indexPath:indexPath];
    });
}

- (void) updateDownloadingCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if (_mapItems && _mapItems.count > 0)
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
}

- (void) refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        for (int i = 0; i < _mapItems.count; i++)
        {
            OAResourceItem *item = (OAResourceItem *)_mapItems[i];
            if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:(tblView.numberOfSections - 1)]];
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
