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
#import "OAMapViewController.h"
#import "OASettingSwitchCell.h"
#import "OAColors.h"
#import "OAColorsTableViewCell.h"
#import "OAIconTextDescButtonTableViewCell.h"
#import "OAResourcesBaseViewController.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import <FFCircularProgressView.h>
#import <MBProgressHUD.h>
#import "FFCircularProgressView+isSpinning.h"
#import "OAAutoObserverProxy.h"

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


@interface OAMapSettingsContourLinesScreen() <OACustomPickerTableViewCellDelegate, OAColorsTableViewCellDelegate, OAIconTextDescButtonCellDelegate>

@end

@implementation OAMapSettingsContourLinesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;

    OAMapStyleSettings *_styleSettings;

    NSArray<NSArray *> *_data;
    BOOL _availableMaps;
    NSArray<NSString *> *_visibleZoomValues;
    NSArray<NSString *> *_visibleWidthValues;
    NSArray<NSString *> *_visibleDensityValues;
    NSArray<NSString *> *_visibleColorValues;
    NSMutableArray *_colors;
    NSArray<NSDictionary *> *_sectionHeaderFooterTitles;
    NSString *_minZoom;
    NSInteger _currentColor;
    NSIndexPath *_mapIndexPath;
    NSArray<RepositoryResourceItem *> *_mapItems;
    RepositoryResourceItem *_mapItem;
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
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    _styleSettings = [OAMapStyleSettings sharedInstance];
    title = OALocalizedString(@"product_title_srtm");
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    
    _visibleZoomValues = @[@"11", @"12", @"13", @"14", @"15", @"16"];
    _visibleColorValues = @[@"white", @"yellow", @"green", @"light_brown", @"brown", @"dark_brown", @"red"];
    _visibleWidthValues = @[@"thin", @"medium", @"thick"];
    _visibleDensityValues = @[@"low", @"medium_w", @"high"];
    
    _colors = [NSMutableArray new];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_white]];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_yellow]];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_green]];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_light_brown]];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_brown]];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_dark_brown]];
    [_colors addObject: [NSNumber numberWithInt:color_contour_lines_red]];
    
    OAMapStyleParameter *p1 = [_styleSettings getParameter:kContourLinesColorScheme];
    if ([p1.value isEqualToString:@""])
    {
        p1.value = kDefaultColorScheme;
        [_styleSettings save:p1];
    }
    _currentColor = [_visibleColorValues indexOfObject:p1.value];
    
    OAMapStyleParameter *p2 = [_styleSettings getParameter:kContourLinesDensity];
    if ([p2.value isEqualToString:@""])
    {
        p2.value = kDefaultDensity;
        [_styleSettings save:p2];
    }
    
    OAMapStyleParameter *p3 = [_styleSettings getParameter:kContourLinesWidth];
    if ([p3.value isEqualToString:@""])
    {
        p3.value = kDefaultWidth;
        [_styleSettings save:p3];
    }
    
    OAMapStyleParameter *p4 = [_styleSettings getParameter:kContourLinesZoomLevel];
    if ([p4.value isEqualToString:@""])
    {
        p4.value = kDefaultZoomLevel;
        [_styleSettings save:p4];
        [[OAAppSettings sharedManager].contourLinesZoom set:p4.value];
    }
    [self updateAvailableMaps];
    
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *switchArr = [NSMutableArray array];
    [switchArr addObject:@{
        @"type" : kCellTypeSwitch
    }];
    
    NSMutableArray *zoomArr = [NSMutableArray array];
    [zoomArr addObject:@{
        @"type" : kCellTypeValue,
        @"title" : OALocalizedString(@"display_starting_at_zoom_level"),
        @"parameter" : [_styleSettings getParameter:kContourLinesZoomLevel]
    }];
    [zoomArr addObject:@{
        @"type" : kCellTypePicker,
        @"value" : _visibleZoomValues,
        @"parameter" : [_styleSettings getParameter:kContourLinesZoomLevel]
    }];
    
    NSMutableArray *linesArr = [NSMutableArray array];
    [linesArr addObject:@{
        @"type" : kCellTypeCollection,
        @"title" : OALocalizedString(@"map_settings_color_scheme"),
        @"parameter" : [_styleSettings getParameter:kContourLinesColorScheme]
    }];
    [linesArr addObject:@{
        @"type" : kCellTypeSlider,
        @"parameter" : [_styleSettings getParameter:kContourLinesWidth],
        @"name" : OALocalizedString(@"map_settings_line_width")
    }];
    [linesArr addObject:@{
        @"type" : kCellTypeSlider,
        @"parameter" : [_styleSettings getParameter:kContourLinesDensity],
        @"name" : OALocalizedString(@"map_settings_line_density")
    }];
    
    NSMutableArray *availableMapsArr = [NSMutableArray array];
    if (_availableMaps)
    {
        for (RepositoryResourceItem* item in _mapItems)
        {
            [availableMapsArr addObject:@{
                @"type" : kCellTypeMap,
                @"title" : item.title,
                @"size" : [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]
            }];
        }
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
                        @"footer" : OALocalizedString(@"map_settings_contour_zoom_level_descr")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"map_settings_appearance"),
                        @"footer" : OALocalizedString(@"map_settings_line_density_slowdown_warning")
                        }];
    if (_availableMaps)
    {
        [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"osmand_live_available_maps"),
                        @"footer" : OALocalizedString(@"map_settings_available_srtm_maps_descr")
                        }];
    }
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
}

- (void) updateAvailableMaps
{
    CLLocation *loc = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
    CLLocationCoordinate2D loca = loc.coordinate;
    [OAResourcesBaseViewController requestMapDownloadInfo:loca resourceType:OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion onComplete:^(NSArray<ResourceItem *>* res) {
        NSMutableArray<RepositoryResourceItem *> *availableItems;
        availableItems = [NSMutableArray new];
        if (res.count > 0)
        {
            for (ResourceItem * item in res)
            {
                if ([item isKindOfClass:RepositoryResourceItem.class])
                {
                    RepositoryResourceItem *resource = (RepositoryResourceItem*)item;
                    [availableItems addObject:resource];
                }
            }
            
            _mapItems = availableItems.count > 0 ? [availableItems copy] : NULL;
        }
        _availableMaps = _mapItems.count > 0 ? YES : NO;
        
        [self generateData];
        [tblView reloadData];
    }];
    
    
}

- (void) downloadMap:(NSIndexPath*)indexPath
{
    RepositoryResourceItem *localMapIndexItem = _mapItems[indexPath.row];
    if (localMapIndexItem)
    {
        _mapItem = localMapIndexItem;
//       if (localMapIndexItem.resourceType == OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion &&
//           ![OAResourcesBaseViewController checkIfDownloadAvailable:localMapIndexItem.worldRegion])
//       {
//           UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"res_free_exp") preferredStyle:UIAlertControllerStyleAlert];
//           [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
//           [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
//           return;
//       }
       
       NSString *resourceName = [OAResourcesBaseViewController titleOfResource:localMapIndexItem.resource
                                                                      inRegion:localMapIndexItem.worldRegion
                                                                withRegionName:YES
                                                              withResourceType:YES];
       
       if (![OAResourcesBaseViewController verifySpaceAvailableDownloadAndUnpackResource:localMapIndexItem.resource
                                                     withResourceName:resourceName
                                                             asUpdate:YES])
       {
           UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"res_install_no_space") preferredStyle:UIAlertControllerStyleAlert];
           [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
           [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
           return;
       }
       
       [OAResourcesBaseViewController startBackgroundDownloadOf:localMapIndexItem.resource resourceName:resourceName];
    }

    OAIconTextDescButtonCell* cell = [tblView cellForRowAtIndexPath:indexPath];
    cell.checkButton.hidden = YES;
    FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
    progressView.iconView = [[UIView alloc] init];
    cell.accessoryView = progressView;
    progressView.tintColor = UIColorFromRGB(color_primary_purple);
    _mapIndexPath = indexPath;
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

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self isContourLinesOn] ? _data.count : 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
            cell.textView.text = [self isContourLinesOn] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = [self isContourLinesOn] ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [[UIImage imageNamed:imgName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = [self isContourLinesOn] ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:[self isContourLinesOn]];
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
        cell.dataArray = _visibleZoomValues;
        OAMapStyleParameter *p = item[@"parameter"];
        NSInteger index = [_visibleZoomValues indexOfObject:p.value];
        [cell.picker selectRow:index inComponent:0 animated:NO];
        cell.delegate = self;
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString: kCellTypeCollection])
    {
        static NSString* const identifierCell = @"OAColorsTableViewCell";
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorsTableViewCell" owner:self options:nil];
            cell = (OAColorsTableViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _colors;
        }
        if (cell)
        {
            cell.delegate = self;
            cell.titleLabel.text = item[@"title"];
            OAMapStyleParameter *p = item[@"parameter"];
            cell.valueLabel.text = [p getValueTitle];
            cell.currentColor = _currentColor;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
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
            cell.titleLabel.text = item[@"name"];
            cell.valueLabel.text = [p getValueTitle];            
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpOutside];
            if ([p.name  isEqualToString:kContourLinesDensity])
            {
                [cell.sliderView addTarget:self action:@selector(densityChanged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
                cell.sliderView.value = (CGFloat)[_visibleDensityValues indexOfObject:p.value]/(CGFloat)(_visibleDensityValues.count - 1);
            }
            else if ([p.name isEqualToString:kContourLinesWidth])
            {
                [cell.sliderView addTarget:self action:@selector(widthChanged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
                cell.sliderView.value = (CGFloat)[_visibleWidthValues indexOfObject:p.value]/(CGFloat)(_visibleWidthValues.count - 1);
            }
            [cell setupSeparators];
        }
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString: kCellTypeMap])
    {
        static NSString* const identifierCell = @"OAIconTextDescButtonCell";
        OAIconTextDescButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescButtonTableViewCell" owner:self options:nil];
            cell = (OAIconTextDescButtonCell *)[nib objectAtIndex:0];
            cell.leftIconView.image = [UIImage imageNamed:@"ic_custom_contour_lines"];
            cell.dividerIcon.backgroundColor = [UIColor clearColor];
//            cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }

        
        NSString *description = OALocalizedString(@"map_settings_SRTM");

        cell.titleLabel.text = item[@"title"];
        cell.descLabel.text = [[description stringByAppendingString:@" • "] stringByAppendingString:item[@"size"]];

        [cell.checkButton setImage:[UIImage imageNamed:@"ic_custom_download.png"] forState:UIControlStateNormal];

        cell.delegate = self;
        cell.checkButton.tag = indexPath.row;
        return cell;
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
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString: kCellTypeMap])
    {
        [self downloadMap:indexPath];
    }
    [tblView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Selectors

- (void) widthChanged:(UISlider*)sender
{
    if (sender)
    {
        NSInteger index;
        if (sender.value < 0.25)
            index = 0;
        else if (sender.value < 0.75)
            index = 1;
        else
            index = 2;
        OAMapStyleParameter *p = [_styleSettings getParameter:kContourLinesWidth];
        p.value = _visibleWidthValues[index];
        [_styleSettings save:p];
    }
    [tblView beginUpdates];
    [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tblView endUpdates];
}

- (void) densityChanged:(UISlider*)sender
{
    if (sender)
    {
        NSInteger index;
        if (sender.value < 0.25)
            index = 0;
        else if (sender.value < 0.75)
            index = 1;
        else
            index = 2;
        OAMapStyleParameter *p = [_styleSettings getParameter:kContourLinesDensity];
        p.value = _visibleDensityValues[index];
        [_styleSettings save:p];
    }
    [tblView beginUpdates];
    [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tblView endUpdates];
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;

     if (switchView)
       {
           OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
           parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
           [_styleSettings save:parameter];
           [tblView beginUpdates];
           if (switchView.isOn)
               [tblView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
           else
               [tblView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
           [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
           [tblView endUpdates];
       }
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

#pragma mark - OAColorsTableViewCellDelegate

- (void) colorChanged:(NSInteger)row
{
    _currentColor = row;
    OAMapStyleParameter *parameter = [_styleSettings getParameter:kContourLinesColorScheme];
    parameter.value = _visibleColorValues[row];
    [_styleSettings save:parameter];
    [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - OAIconTextDescButtonCellDelegate

- (void) onButtonPressed:(NSInteger)tag
{
    [self downloadMap:[NSIndexPath indexPathForRow:tag inSection:3]];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"] || task.state != OADownloadTaskStateRunning)
        return;
    
    if (!task.silentInstall)
        task.silentInstall = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_mapItem && [_mapItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            OAIconTextDescButtonCell* cell = [tblView cellForRowAtIndexPath:_mapIndexPath];
            FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
            progressView.progress = task.progressCompleted;
        }
        
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAvailableMaps];

        if (_mapItem && [_mapItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {

        }
        
    });
}

@end
