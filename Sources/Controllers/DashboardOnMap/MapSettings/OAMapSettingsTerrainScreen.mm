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
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OARightIconTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OATitleSliderTableViewCell.h"
#import "OASegmentTableViewCell.h"
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
#import "OALinks.h"
#import "OASizes.h"
#import "OADownloadingCellHelper.h"
#import <SafariServices/SafariServices.h>

#define kMinAllowedZoom 1
#define kMaxAllowedZoom 22
#define kMaxMissingDataZoomShift 5

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAMapSettingsTerrainScreen() <OACustomPickerTableViewCellDelegate, SFSafariViewControllerDelegate, UITextViewDelegate>

@end

@implementation OAMapSettingsTerrainScreen
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;

    OATableDataModel *_data;
    NSIndexPath *_minValueIndexPath;
    NSIndexPath *_maxValueIndexPath;
    NSIndexPath *_pickerIndexPath;
    NSInteger _availableMapsSection;

    NSInteger _minZoom;
    NSInteger _maxZoom;
    NSArray<NSString *> *_possibleZoomValues;

    NSObject *_dataLock;
    NSArray<OARepositoryResourceItem *> *_mapItems;
    OADownloadingCellHelper *_downloadingCellHelper;
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
        [self initData];
        [self setupDownloadingCellHelper];
    }
    return self;
}

- (void) initData
{
    _data = [OATableDataModel model];

    EOATerrainType type = _app.data.terrainType;
    _minZoom = type == EOATerrainTypeHillshade ? _app.data.hillshadeMinZoom : _app.data.slopeMinZoom;
    _maxZoom = type == EOATerrainTypeHillshade ? _app.data.hillshadeMaxZoom : _app.data.slopeMaxZoom;

    OATableSectionData *switchSection = [_data createNewSection];
    [switchSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        @"value" : @(type != EOATerrainTypeDisabled)
    }];

    if (type == EOATerrainTypeDisabled)
    {
        OATableSectionData *disabledSection = [_data createNewSection];
        [disabledSection addRowFromDictionary:@{
            kCellKeyKey : @"disabledImage",
            kCellTypeKey : [OAImageTextViewCell getCellIdentifier],
            kCellDescrKey : OALocalizedString(@"enable_hillshade"),
            kCellIconNameKey : @"img_empty_state_terrain"
        }];
        [disabledSection addRowFromDictionary:@{
            kCellKeyKey : @"readMore",
            kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_read_more"),
            kCellIconNameKey : @"ic_custom_safari",
            @"link" : kOsmAndFeaturesContourLinesPlugin
        }];
    }
    else
    {
        switchSection.footerText = type == EOATerrainTypeHillshade
            ? OALocalizedString(@"map_settings_hillshade_description")
            : OALocalizedString(@"map_settings_slopes_description");

        [switchSection addRowFromDictionary:@{
            kCellTypeKey : [OASegmentTableViewCell getCellIdentifier],
            @"title0" : OALocalizedString(@"shared_string_hillshade"),
            @"title1" : OALocalizedString(@"shared_string_slope")
        }];

        OATableSectionData *transparencySection = [_data createNewSection];
        [transparencySection addRowFromDictionary:@{
            kCellTypeKey : [OATitleSliderTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"map_settings_layer_transparency")
        }];

        OATableSectionData *zoomSection = [_data createNewSection];
        zoomSection.headerText = OALocalizedString(@"shared_string_zoom_levels");
        zoomSection.footerText = OALocalizedString(@"map_settings_zoom_level_description");
        [zoomSection addRowFromDictionary:@{
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey: OALocalizedString(@"rec_interval_minimum"),
            @"value" : @(_minZoom)
        }];
        _minValueIndexPath = [NSIndexPath indexPathForRow:[_data rowCount:[_data sectionCount] - 1] - 1 inSection:[_data sectionCount] - 1];
        if (_pickerIndexPath && _pickerIndexPath.row == _minValueIndexPath.row + 1)
            [zoomSection addRowFromDictionary:@{ kCellTypeKey : [OACustomPickerTableViewCell getCellIdentifier] }];

        [zoomSection addRowFromDictionary:@{
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_maximum"),
            @"value" : @(_maxZoom)
        }];
        _maxValueIndexPath = [NSIndexPath indexPathForRow:[_data rowCount:[_data sectionCount] - 1] - 1 inSection:[_data sectionCount] - 1];
        if (_pickerIndexPath && _pickerIndexPath.row == _maxValueIndexPath.row + 1)
            [zoomSection addRowFromDictionary:@{ kCellTypeKey : [OACustomPickerTableViewCell getCellIdentifier] }];

        if (_app.data.terrainType == EOATerrainTypeSlope)
        {
            OATableSectionData *slopeLegendSection = [_data createNewSection];
            slopeLegendSection.headerText = OALocalizedString(@"shared_string_legend");
            [slopeLegendSection addRowFromDictionary:@{
                kCellTypeKey : [OAImageTextViewCell getCellIdentifier],
                kCellDescrKey : OALocalizedString(@"map_settings_slopes_legend"),
                kCellIconNameKey : @"img_legend_slope",
                @"link" : kUrlWikipediaSlope
            }];
        }

        if (_mapItems.count > 0)
        {
            OATableSectionData *availableMapsSection = [_data createNewSection];
            _availableMapsSection = [_data sectionCount] - 1;
            availableMapsSection.headerText = OALocalizedString(@"available_maps");
            availableMapsSection.footerText = type == EOATerrainTypeHillshade ? OALocalizedString(@"map_settings_add_maps_hillshade") : OALocalizedString(@"map_settings_add_maps_slopes");
            for (NSInteger i = 0; i < _mapItems.count; i++)
            {
                [availableMapsSection addRowFromDictionary:@{
                    kCellKeyKey : @"mapItem",
                    kCellTypeKey : @"mapItem"
                }];
            }
        }
        else
        {
            _availableMapsSection = -1;
        }
    }
}

- (void)setupDownloadingCellHelper
{
    __weak OAMapSettingsTerrainScreen *weakself = self;
    _downloadingCellHelper = [[OADownloadingCellHelper alloc] init];
    _downloadingCellHelper.hostViewController = self.vwController;
    _downloadingCellHelper.hostTableView = self.tblView;
    _downloadingCellHelper.hostDataLock = _dataLock;
    
    _downloadingCellHelper.fetchResourcesBlock = ^(){
        
        CLLocationCoordinate2D coordinate = [OAResourcesUIHelper getMapLocation];
        OsmAnd::ResourcesManager::ResourceType resType = _app.data.terrainType == EOATerrainTypeHillshade ? OsmAndResourceType::HillshadeRegion : OsmAndResourceType::SlopeRegion;
        _mapItems = (NSArray<OARepositoryResourceItem *> *) [OAResourcesUIHelper findIndexItemsAt:coordinate type:resType includeDownloaded:NO limit:-1 skipIfOneDownloaded:YES];
        [weakself initData];
    };
    
    _downloadingCellHelper.getResourceByIndexBlock = ^OAResourceItem *(NSIndexPath *indexPath){
        
        OATableRowData *row = [[weakself data] itemForIndexPath:indexPath];
        if (row && [row.key isEqualToString:@"mapItem"])
        {
            OAResourceItem *mapItem = [weakself mapItems][indexPath.row];
            if (mapItem)
                return mapItem;
        }
        
        return nil;
    };
    
    _downloadingCellHelper.getTableDataModelBlock = ^OATableDataModel *{
        return [weakself data];
    };
}

- (OATableDataModel *)data
{
    return _data;
}

- (NSArray<OAResourceItem *> *)mapItems
{
    return _mapItems;
}

- (void)generateValueForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == _minValueIndexPath)
        [[_data itemForIndexPath:indexPath] setObj:@(_minZoom) forKey:@"value"];
    else if (indexPath == _maxValueIndexPath)
        [[_data itemForIndexPath:indexPath] setObj:@(_maxZoom) forKey:@"value"];
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
    _possibleZoomValues = [self getPossibleZoomValues];

    [_downloadingCellHelper updateAvailableMaps];
}

- (void)onRotation
{
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    [tblView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell setCustomLeftSeparatorInset:YES];
        }
        if (cell)
        {
            BOOL isOn = [item boolForKey:@"value"];
            cell.titleLabel.text = isOn ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            cell.separatorInset = UIEdgeInsetsMake(0., (isOn ? DBL_MAX : 0.), 0., 0.);

            NSString *imgName = isOn ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.leftIconView.image = [UIImage templateImageNamed:imgName];
            cell.leftIconView.tintColor = isOn ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:isOn];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = UIColor.blackColor;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.accessoryView = nil;
            BOOL isReadMore = [item.key isEqualToString:@"readMore"];
            [cell leftIconVisibility:!isReadMore];
            [cell descriptionVisibility:!isReadMore];
            cell.titleLabel.textColor = isReadMore ? UIColorFromRGB(color_primary_purple) : UIColor.blackColor;
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:isReadMore ? UIFontWeightSemibold : UIFontWeightRegular];
            cell.rightIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.titleLabel.text = item.title;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:@"mapItem"])
    {
        OAResourceItem *mapItem = _mapItems[indexPath.row];
        return [_downloadingCellHelper setupCell:mapItem indexPath:indexPath];
    }
    else if ([item.cellType isEqualToString:[OACustomPickerTableViewCell getCellIdentifier]])
    {
        OACustomPickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0, 0);
            cell.dataArray = _possibleZoomValues;
            NSInteger minZoom = _minZoom >= kMinAllowedZoom && _minZoom <= kMaxAllowedZoom ? _minZoom : 1;
            NSInteger maxZoom = _maxZoom >= kMinAllowedZoom && _maxZoom <= kMaxAllowedZoom ? _maxZoom : 1;
            [cell.picker selectRow:indexPath.row == 1 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
            cell.picker.tag = indexPath.row;
            cell.delegate = self;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OATitleSliderTableViewCell getCellIdentifier]])
    {
        OATitleSliderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;

            cell.sliderView.value = _app.data.terrainType == EOATerrainTypeSlope ? _app.data.slopeAlpha : _app.data.hillshadeAlpha;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", cell.sliderView.value * 100, @"%"];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OASegmentTableViewCell getCellIdentifier]])
    {
        OASegmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            UIFont *font = [UIFont scaledSystemFontOfSize:14.];
            [cell.segmentControl setTitleTextAttributes:@{ NSFontAttributeName : font } forState:UIControlStateSelected];
            [cell.segmentControl setTitleTextAttributes:@{ NSFontAttributeName : font } forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.segmentControl removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:[item stringForKey:@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:[item stringForKey:@"title1"] forSegmentAtIndex:1];
            [cell.segmentControl setSelectedSegmentIndex:_app.data.terrainType == EOATerrainTypeHillshade ? 0 : 1];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAImageTextViewCell getCellIdentifier]])
    {
        OAImageTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAImageTextViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageTextViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageTextViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showExtraDesc:NO];
            cell.descView.delegate = self;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0, 0);
            cell.iconView.image = [UIImage rtlImageNamed:item.iconName];

            BOOL isDisabled = [item.key isEqualToString:@"disabledImage"];
            NSString *descr = item.descr;
            if (isDisabled)
            {
                cell.descView.attributedText = nil;
                cell.descView.text = descr;
            }
            else if (descr && descr.length > 0)
            {
                NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:descr attributes:@{
                    NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                }];
                NSRange range = [descr rangeOfString:@" " options:NSBackwardsSearch];
                if (range.location != NSNotFound)
                {
                    NSDictionary *linkAttributes = @{ NSLinkAttributeName : [item stringForKey:@"link"] };
                    [str setAttributes:linkAttributes range:NSMakeRange(range.location + 1, descr.length - range.location - 1)];
                }
                cell.descView.text = nil;
                cell.descView.attributedText = str;
            }
            else
            {
                cell.descView.text = nil;
                cell.descView.attributedText = nil;
            }

            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tblView deselectRowAtIndexPath:indexPath animated:YES];

    OATableRowData *item =  [_data itemForIndexPath:indexPath];
    if (indexPath == _minValueIndexPath || indexPath == _maxValueIndexPath)
    {
        [tblView beginUpdates];
        NSIndexPath *newPickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        BOOL isThisPicker = _pickerIndexPath == newPickerIndexPath;
        if (_pickerIndexPath != nil)
            [tblView deleteRowsAtIndexPaths:@[_pickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        _pickerIndexPath = isThisPicker ? nil : newPickerIndexPath;
        [self initData];
        if (!isThisPicker)
            [tblView insertRowsAtIndexPaths:@[_pickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
        [tblView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if ([item.key isEqualToString:@"readMore"])
    {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[item stringForKey:@"link"]]];
        [self.vwController presentViewController:safariViewController animated:YES completion:nil];
    }
    else if ([item.key isEqualToString:@"mapItem"])
    {
        [_downloadingCellHelper onItemClicked:indexPath];
    }
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)resetPickerValue:(NSInteger)zoomValue
{
    if (_pickerIndexPath)
    {
        UITableViewCell *cell = [tblView cellForRowAtIndexPath:_pickerIndexPath];
        if ([cell isKindOfClass:OACustomPickerTableViewCell.class])
        {
            OACustomPickerTableViewCell *pickerCell = (OACustomPickerTableViewCell *) cell;
            [pickerCell.picker selectRow:zoomValue - 1 inComponent:0 animated:YES];
        }
    }
}

- (void)customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag
{
    NSIndexPath *zoomValueIndexPath;
    NSInteger intValue = [value integerValue];
    EOATerrainType type = _app.data.terrainType;
    if (pickerTag == 1)
    {
        zoomValueIndexPath = _minValueIndexPath;
        if (intValue <= _maxZoom)
        {
            _minZoom = intValue;
            if (type == EOATerrainTypeHillshade)
                _app.data.hillshadeMinZoom = _minZoom;
            else if (type == EOATerrainTypeSlope)
                _app.data.slopeMinZoom = _minZoom;
        }
        else
        {
            _minZoom = _maxZoom;
            [self resetPickerValue:_maxZoom];
        }
    }
    else if (pickerTag == 2)
    {
        zoomValueIndexPath = _maxValueIndexPath;
        if (intValue >= _minZoom)
        {
            _maxZoom = intValue;
            if (type == EOATerrainTypeHillshade)
                _app.data.hillshadeMaxZoom = _maxZoom;
            else if (type == EOATerrainTypeSlope)
                _app.data.slopeMaxZoom = _maxZoom;
        }
        else
        {
            _maxZoom = _minZoom;
            [self resetPickerValue:_minZoom];
        }
    }

    if (zoomValueIndexPath)
    {
        [self generateValueForIndexPath:zoomValueIndexPath];
        [tblView reloadRowsAtIndexPaths:@[zoomValueIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:URL];
    [self.vwController presentViewController:safariViewController animated:YES completion:nil];
    return NO;
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Selectors

- (void)mapSettingSwitchChanged:(UISwitch *)switchView
{
    if (switchView.isOn)
    {
        EOATerrainType prevType = _app.data.lastTerrainType;
        [_app.data setTerrainType:prevType != EOATerrainTypeDisabled ? prevType : EOATerrainTypeHillshade];
    }
    else
    {
        _pickerIndexPath = nil;
        _minValueIndexPath = nil;
        _maxValueIndexPath = nil;
        _availableMapsSection = -1;
        _app.data.lastTerrainType = _app.data.terrainType;
        [_app.data setTerrainType:EOATerrainTypeDisabled];
    }
    [_downloadingCellHelper updateAvailableMaps];
    [UIView transitionWithView:tblView
                      duration:.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [tblView reloadData];
                    }
                    completion:nil];
}

- (void) sliderValueChanged:(UISlider *)slider
{
    EOATerrainType type = _app.data.terrainType;
    if (type == EOATerrainTypeHillshade)
        _app.data.hillshadeAlpha = slider.value;
    else if (type == EOATerrainTypeSlope)
        _app.data.slopeAlpha = slider.value;
}

- (void) segmentChanged:(UISegmentedControl *)segment
{
    _pickerIndexPath = nil;
    _minValueIndexPath = nil;
    _maxValueIndexPath = nil;
    _availableMapsSection = -1;
    if (segment.selectedSegmentIndex == 0)
        [_app.data setTerrainType: EOATerrainTypeHillshade];
    else if (segment.selectedSegmentIndex == 1)
        [_app.data setTerrainType: EOATerrainTypeSlope];

    [_downloadingCellHelper updateAvailableMaps];
    [UIView transitionWithView:tblView
                      duration:.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [tblView reloadData];
                    }
                    completion:nil];
}

@end
