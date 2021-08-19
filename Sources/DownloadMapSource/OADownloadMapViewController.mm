//
//  OADownloadMapViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OASelectMapSourceViewController.h"
#import "OAMapRendererView.h"
#import "OAMapCreatorHelper.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesUIHelper.h"
#import "OADownloadMapProgressViewController.h"
#import "OAAutoObserverProxy.h"

#include "Localization.h"
#include "OAColors.h"
#include "OASizes.h"

#import "OASettingsTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OAPreviewZoomLevelsCell.h"
#import "OACustomPickerTableViewCell.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>

#define kMapTypeSection 0
#define kZoomSection 1
#define kZoomTilesRow 0
#define kMinZoomRow 1
#define kMinZoomPickerRow 2
#define kMaxZoomRow 3
#define kMaxZoomPickerRow 4
#define kZoomPickerRow 3
#define kDownloadInfoSection 2
#define kNumberOfTilesRow 0
#define kDownloadSizeRow 1

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OADownloadMapViewController() <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate, OAMapSourceSelectionDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (nonatomic) UIImage *minZoomTileImage;
@property (nonatomic) UIImage *maxZoomTileImage;

@end

@interface OADownloadMapViewController () <OAPreviewZoomLevelsCellDelegate>
@end

@implementation OADownloadMapViewController
{
    OsmAndAppInstance _app;
    OAMapRendererView *_mapView;
    NSArray *_data;
    
    int _currentZoom;
    int _minZoom;
    int _maxZoom;
    NSInteger _numberOfTiles;
    CGFloat _downloadSize;
    NSArray<NSString *> *_possibleZoomValues;
    BOOL _minZoomPickerIsShown;
    BOOL _maxZoomPickerIsShown;
    
    NSDictionary<OAMapSource *, OAResourceItem *> *_onlineMapSources;
    OAAutoObserverProxy* _framePreparedObserver;
}

- (UIView *) getMiddleView
{
    return self.contentView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportFullScreen
{
    return NO;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL)offerMapDownload
{
    return NO;
}

- (UIView *) getBottomView
{
    return self.bottomToolBarView;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL) disableScroll
{
    return YES;
}

- (BOOL) hasBottomToolbar
{
    return YES;
}

- (BOOL) isMapFrameNeeded
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (BOOL) isLandscape
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;;
}

- (CGFloat) contentHeight
{
    return DeviceScreenHeight * kOATargetPointViewFullHeightKoef;
}

- (CGFloat) mapHeightKoef
{
    return 0.7;
}

- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.downloadButton setTitle:OALocalizedString(@"download") forState:UIControlStateNormal];
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSString *) getTypeStr
{
    return nil;
}

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onMapRendererFramePrepared)
                                                        andObserve:[OARootViewController instance].mapPanel.mapViewController.framePreparedObservable];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.bottomToolBarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self updateToolBar];
    _cancelButton.layer.cornerRadius = 9.0;
    _downloadButton.layer.cornerRadius = 9.0;
    _onlineMapSources = [OAResourcesUIHelper getOnlineRasterMapSourcesBySource];
    _mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    _currentZoom = _mapView.zoom;
    _minZoomPickerIsShown = NO;
    _maxZoomPickerIsShown = NO;
    [self setZoomValues];
    [self calculateDownloadInfo];
    [self setupView];
    self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, self.bottomToolBarView.bounds.size.height, 0.0);
}

- (void) dealloc
{
    if (_framePreparedObserver && [_framePreparedObserver isAttached])
        [_framePreparedObserver detach];
}

- (void) setZoomValues
{
    _minZoom = (int)[self getDefaultItemMinZoom];
    _maxZoom = (int)[self getItemMaxZoom];
    _possibleZoomValues = [self getPossibleZoomValues];
    [self downloadZoomedTiles];
}

- (OAResourceItem *) getCurrentItem
{
    return _onlineMapSources[_app.data.lastMapSource];
}

- (NSInteger) getDefaultItemMinZoom
{
    if (_currentZoom > [self getItemMaxZoom])
        return [self getItemMaxZoom];
    else if (_currentZoom < [self getItemMinZoom])
        return [self getItemMinZoom];
    else
        return _currentZoom;
}

- (NSInteger) getItemMinZoom
{
    OAResourceItem *item = [self getCurrentItem];
    if (item)
    {
        if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem *onlineSource = (OAOnlineTilesResourceItem *) item;
            return onlineSource.onlineTileSource->minZoom;
        }
        else if ([item isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *) item;
            OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:sqliteItem.path];
            return ts.minimumZoomSupported > 0;
        }
    }
    return 1;
}

- (NSInteger) getItemMaxZoom
{
    OAResourceItem *item = [self getCurrentItem];
    if (item)
    {
        if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem *onlineSource = (OAOnlineTilesResourceItem *) item;
            return onlineSource.onlineTileSource->maxZoom;
        }
        else if ([item isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *) item;
            OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:sqliteItem.path];
            return ts.maximumZoomSupported;
        }
    }
    return 1;
}

- (NSMutableArray<NSString *> *) getPossibleZoomValues
{
    NSMutableArray<NSString *> *zoomArray = [[NSMutableArray alloc] init];
    for (NSInteger i = [self getItemMinZoom]; i <= [self getItemMaxZoom]; i++)
        [zoomArray addObject:[NSString stringWithFormat: @"%ld", i]];
    return zoomArray;
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *mapTypeArr = [NSMutableArray array];
    NSMutableArray *zoomLevelArr = [NSMutableArray array];
    NSMutableArray *generalInfoArr = [NSMutableArray array];
    NSString *mapSourceName;
    mapSourceName = _app.data.lastMapSource.name;
    [mapTypeArr addObject:@{
        @"type" : [OASettingsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"map_settings_type"),
        @"value" : mapSourceName,
    }];
    [zoomLevelArr addObject:@{
        @"type" : [OAPreviewZoomLevelsCell getCellIdentifier],
        @"value" : OALocalizedString(@"preview_of_selected_zoom_levels"),
    }];
    [zoomLevelArr addObject:@{
        @"title" : OALocalizedString(@"rec_interval_minimum"),
        @"value" : [NSString stringWithFormat:@"%d", _minZoom],
        @"type"  : [OATimeTableViewCell getCellIdentifier],
        @"clickable" : @(YES)
    }];
    [zoomLevelArr addObject:@{
        @"type" : [OACustomPickerTableViewCell getCellIdentifier],
        @"isVisible" : @(_minZoomPickerIsShown),
    }];
    [zoomLevelArr addObject:@{
        @"title" : OALocalizedString(@"shared_string_maximum"),
        @"value" : [NSString stringWithFormat:@"%d", _maxZoom],
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"clickable" : @(YES)
    }];
    [zoomLevelArr addObject:@{
        @"type" : [OACustomPickerTableViewCell getCellIdentifier],
        @"isVisible" : @(_maxZoomPickerIsShown),
    }];
    [generalInfoArr addObject:@{
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"number_of_tiles"),
        @"value" : [NSString stringWithFormat:@"%ld", _numberOfTiles],
        @"clickable" : @(NO)
    }];
    [generalInfoArr addObject:@{
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"download_size"),
        @"value" : [NSString stringWithFormat:@"~ %@", [NSByteCountFormatter stringFromByteCount:_downloadSize countStyle:NSByteCountFormatterCountStyleFile]],
        @"clickable" : @(NO)
    }];
    [tableData addObject:mapTypeArr];
    [tableData addObject:zoomLevelArr];
    [tableData addObject:generalInfoArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) cancelPressed
{
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (IBAction) cancelButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (IBAction) downloadButtonPressed:(id)sender {
    OADownloadMapProgressViewController *downloadMapProgressVC = [[OADownloadMapProgressViewController alloc] initWithResource:[self getCurrentItem] minZoom:_minZoom maxZoom:_maxZoom numberOfTiles:_numberOfTiles];
    [[OARootViewController instance].navigationController pushViewController:downloadMapProgressVC animated:YES];
}

- (void) calculateDownloadInfo
{
    OsmAnd::AreaI bbox = [_mapView getVisibleBBox31];
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(bbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(bbox.bottomRight);
    _numberOfTiles = 0;
    for (NSInteger z = _minZoom; z <= _maxZoom; z++)
    {
        NSInteger x1 = OsmAnd::Utilities::getTileNumberX(z, topLeft.longitude);
        NSInteger x2 = OsmAnd::Utilities::getTileNumberX(z, bottomRight.longitude);
        NSInteger y1 = OsmAnd::Utilities::getTileNumberY(z, topLeft.latitude);
        NSInteger y2 = OsmAnd::Utilities::getTileNumberY(z, bottomRight.latitude);
        _numberOfTiles += (x2 - x1 + 1) * (y2 - y1 + 1);
    }
    _downloadSize = _numberOfTiles * 12000;
}

- (void) onMapRendererFramePrepared
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self calculateDownloadInfo];
        [self setupView];
        [self.tableView reloadData];
    });
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, self.bottomToolBarView.bounds.size.height, 0.0);
        if (self.delegate)
           [self.delegate requestFullMode];
        if (self.delegate && self.isLandscape)
            [self.delegate contentChanged];
        [self updateToolBar];
    } completion:nil];
}

- (void) updateToolBar
{
    CGRect frame = self.bottomToolBarView.frame;
    frame.size.height = twoButtonsBottmomSheetHeight + [OAUtilities getBottomMargin];
    frame.origin.y = [self contentHeight] - frame.size.height;
    self.bottomToolBarView.frame = frame;
}

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    CGFloat w = width - 32.0 - OAUtilities.getLeftMargin;
    CGRect leftBtnFrame = _cancelButton.frame;
    CGRect rightBtnFrame = _downloadButton.frame;
    if (_downloadButton.isDirectionRTL)
    {
        rightBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        rightBtnFrame.size.width = w / 2 - 8;
        
        leftBtnFrame.origin.x = CGRectGetMaxX(rightBtnFrame) + 16.;
        leftBtnFrame.size.width = rightBtnFrame.size.width;

        _cancelButton.frame = leftBtnFrame;
        _downloadButton.frame = rightBtnFrame;
    }
    else
    {
        leftBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        leftBtnFrame.size.width = w / 2 - 8;
        _cancelButton.frame = leftBtnFrame;

        rightBtnFrame.origin.x = CGRectGetMaxX(leftBtnFrame) + 16.;
        rightBtnFrame.size.width = leftBtnFrame.size.width;
        _downloadButton.frame = rightBtnFrame;
    }
}

- (void) downloadZoomedTiles
{
    NSString *minZoomTileUrl = [self getZoomTileUrl:_minZoom];;
    NSString *maxZoomTileUrl = [self getZoomTileUrl:_maxZoom];
    if (!minZoomTileUrl || !maxZoomTileUrl)
        return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSData *minZoomData = [NSData dataWithContentsOfURL:[NSURL URLWithString:minZoomTileUrl]];
        NSData *maxZoomData = [NSData dataWithContentsOfURL:[NSURL URLWithString:maxZoomTileUrl]];
        if (minZoomData && maxZoomData)
        {
            _minZoomTileImage = [[UIImage alloc] initWithData:minZoomData];
            _maxZoomTileImage = [[UIImage alloc] initWithData:maxZoomData];
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kZoomTilesRow inSection:kZoomSection]] withRowAnimation:UITableViewRowAnimationFade];
        });
    });
}

- (NSString *) getZoomTileUrl:(NSInteger)zoom
{
    OAResourceItem *item = [self getCurrentItem];
    const auto point = OsmAnd::Utilities::convert31ToLatLon(_mapView.target31);
    const auto tileId = OsmAnd::TileId::fromXY(OsmAnd::Utilities::getTileNumberX(zoom, point.longitude), OsmAnd::Utilities::getTileNumberY(zoom, point.latitude));
    NSString *url = [[NSString alloc] init];
    if (item)
    {
        if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem *onlineSource = (OAOnlineTilesResourceItem *) item;
            NSString *urlToLoad = onlineSource.onlineTileSource->urlToLoad.toNSString();
            QList<QString> randomsArray;
            url = OsmAnd::OnlineRasterMapLayerProvider::buildUrlToLoad(QString::fromNSString(urlToLoad), randomsArray, tileId.x, tileId.y, OsmAnd::ZoomLevel(zoom)).toNSString();
        }
        else if ([item isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *sqliteSource = (OASqliteDbResourceItem *) item;
            OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:sqliteSource.path];
            url = [ts getUrlToLoad:tileId.x y:tileId.y zoom:(int)zoom];
        }
    }
    return url;
}

#pragma mark - TableView

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data count];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data[section] count];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAPreviewZoomLevelsCell getCellIdentifier]])
    {
        OAPreviewZoomLevelsCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAPreviewZoomLevelsCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPreviewZoomLevelsCell getCellIdentifier] owner:self options:nil];
            cell = (OAPreviewZoomLevelsCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.delegate = self;
            [cell.minLevelZoomButton setImage:(_minZoomTileImage == nil ? [UIImage imageNamed:@"img_placeholder_online_source"] : _minZoomTileImage) forState:UIControlStateNormal];
            [cell.maxLevelZoomButton setImage:(_maxZoomTileImage == nil ? [UIImage imageNamed:@"img_placeholder_online_source"] : _maxZoomTileImage) forState:UIControlStateNormal];
            cell.minZoomPropertyLabel.text = [NSString stringWithFormat:@"%d",_minZoom];
            cell.maxZoomPropertyLabel.text = [NSString stringWithFormat:@"%d",_maxZoom];
            cell.descriptionLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OATimeTableViewCell getCellIdentifier]])
    {
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        cell.lbTime.textColor = [item[@"clickable"] boolValue] ? [UIColor blackColor] : [UIColor grayColor];
        if (indexPath.row == kMaxZoomRow && !_maxZoomPickerIsShown)
            cell.separatorInset = UIEdgeInsetsZero;
        else
            cell.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
        return cell;
    }
    else if ([cellType isEqualToString:[OACustomPickerTableViewCell getCellIdentifier]])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        [cell.picker selectRow:indexPath.row == kMinZoomPickerRow ? _minZoom - 1 : _maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        cell.hidden = ![item[@"isVisible"] boolValue];
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == kMapTypeSection)
        return 0.01;
    else if (section == kZoomSection)
        return 38;
    else
        return 8.0;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == kZoomSection ? OALocalizedString(@"res_zoom_levels") : @"";
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == kZoomSection ? UITableViewAutomaticDimension : 1.0;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == kZoomSection ? OALocalizedString(@"size_of_downloaded_data") : @"";
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kZoomSection && (indexPath.row == kMinZoomPickerRow || indexPath.row == kMaxZoomPickerRow))
    {
        if ((indexPath.row == kMinZoomPickerRow && _minZoomPickerIsShown) || (indexPath.row == kMaxZoomPickerRow && _maxZoomPickerIsShown))
            return UITableViewAutomaticDimension;
        else
            return 0.01;
    }
    return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone && indexPath != [NSIndexPath indexPathForRow:kMinZoomRow inSection:kZoomSection] && indexPath != [NSIndexPath indexPathForRow:kMaxZoomRow inSection:kZoomSection] && indexPath != [NSIndexPath indexPathForRow:kZoomPickerRow inSection:kZoomSection] ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kZoomSection)
    {
        if (indexPath.row == kMinZoomRow)
            [self toggleZoomPickerForRow:kMinZoomPickerRow];
        else
            [self toggleZoomPickerForRow:kMaxZoomPickerRow];
    }
    if (indexPath.section == kMapTypeSection)
    {
        OASelectMapSourceViewController *mapSource = [[OASelectMapSourceViewController alloc] init];
        mapSource.delegate = self;
        [OARootViewController.instance.mapPanel presentViewController:mapSource animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) toggleZoomPickerForRow:(NSInteger)rowIndex
{
    if (rowIndex == kMinZoomPickerRow)
    {
        if (_maxZoomPickerIsShown)
            _maxZoomPickerIsShown = !_maxZoomPickerIsShown;
        _minZoomPickerIsShown = !_minZoomPickerIsShown;
    }
    else if (rowIndex == kMaxZoomPickerRow)
    {
        if (_minZoomPickerIsShown)
            _minZoomPickerIsShown = !_minZoomPickerIsShown;
        _maxZoomPickerIsShown = !_maxZoomPickerIsShown;
    }
    else
    {
        return;
    }
    [self.tableView beginUpdates];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowIndex inSection:kZoomSection],
                                            [NSIndexPath indexPathForRow:kMaxZoomRow inSection:kZoomSection]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

#pragma mark - Picker

- (void) updatePickerCell:(NSInteger)value zoomRow:(NSInteger)zoomPickerRow
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:zoomPickerRow inSection:kZoomSection]];
    if ([cell isKindOfClass:OACustomPickerTableViewCell.class])
    {
        OACustomPickerTableViewCell *cellRes = (OACustomPickerTableViewCell *) cell;
        [cellRes.picker selectRow:value inComponent:0 animated:NO];
    }
}

- (void) zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag
{
    int value = [zoom intValue];
    NSInteger zoomRow = 0;
    if (pickerTag == kMinZoomPickerRow)
    {
        if (value <= _maxZoom)
        {
            _minZoom = value;
        }
        else
        {
            _minZoom = _maxZoom;
            [self updatePickerCell:_minZoom - 1 zoomRow:kMinZoomPickerRow];
        }
        zoomRow = kMinZoomRow;
        [self downloadZoomedTiles];
    }
    else if (pickerTag == kMaxZoomPickerRow)
    {
        if (value >= _minZoom)
        {
            _maxZoom = value;
        }
        else
        {
            _maxZoom = _minZoom;
            [self updatePickerCell:_maxZoom - 1 zoomRow:kMaxZoomPickerRow];
        }
        zoomRow = kMaxZoomRow;
        [self downloadZoomedTiles];
    }
    [self calculateDownloadInfo];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:zoomRow inSection:kZoomSection],
                                             [NSIndexPath indexPathForRow:kNumberOfTilesRow inSection:kDownloadInfoSection],
                                             [NSIndexPath indexPathForRow:kDownloadSizeRow inSection:kDownloadInfoSection]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Map Frame

- (void) addMapFrameLayer:(CGRect)mapFrame view:(UIView *)view
{
    UIBezierPath *backgroundViewPath = [UIBezierPath bezierPathWithRect: mapFrame];
    CGFloat bottomSafeArea = ([self isLandscape] ? OAUtilities.getBottomMargin : 0.0);
    CGFloat statusBarHeight = ([self isLandscape] ? OAUtilities.getStatusBarHeight : 0.0);
    UIBezierPath *mapBorderPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(mapFrame.origin.x + 8, mapFrame.origin.y + 8 + statusBarHeight, mapFrame.size.width - 16 - OAUtilities.getLeftMargin, mapFrame.size.height - 26 - bottomSafeArea - statusBarHeight) cornerRadius: 4];
    
    [backgroundViewPath appendPath:mapBorderPath];
    [backgroundViewPath setUsesEvenOddFillRule:YES];
    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    backgroundLayer.path = backgroundViewPath.CGPath;
    backgroundLayer.fillRule = kCAFillRuleEvenOdd;
    backgroundLayer.fillColor = [UIColor blackColor].CGColor;
    backgroundLayer.opacity = 0.5;
    backgroundLayer.name = @"backgroundLayer";
    [view.layer addSublayer:backgroundLayer];
    
    CAShapeLayer *frameLayer = [CAShapeLayer layer];
    frameLayer.path = mapBorderPath.CGPath;
    frameLayer.fillColor = nil;
    frameLayer.strokeColor = [UIColorFromRGB(color_chart_orange) CGColor];
    frameLayer.lineWidth = 2.0;
    frameLayer.name = @"frameLayer";
    [view.layer addSublayer:frameLayer];
    
    CATextLayer *captionLayer = [CATextLayer layer];
    captionLayer.frame = CGRectMake(mapFrame.origin.x, mapFrame.origin.y + mapFrame.size.height - 17 - bottomSafeArea, mapFrame.size.width, 17);
    captionLayer.fontSize = 13;
    [captionLayer setContentsScale:[[UIScreen mainScreen] scale]];
    captionLayer.foregroundColor = [UIColor whiteColor].CGColor;
    captionLayer.alignmentMode = kCAAlignmentCenter;
    captionLayer.string = OALocalizedString(@"move_map_to_select_area");
    captionLayer.name = @"captionLayer";
    [view.layer addSublayer:captionLayer];
}

- (void) removeMapFrameLayer:(UIView *)view
{
    NSMutableArray<CALayer *> *layersToRemove = [NSMutableArray array];
    for (CALayer *subLayer in view.layer.sublayers)
        if([subLayer.name isEqual: @"backgroundLayer"] || [subLayer.name isEqual: @"frameLayer"] || [subLayer.name isEqual: @"captionLayer"])
            [layersToRemove addObject:subLayer];
    for (CALayer *subLayer in layersToRemove)
        [subLayer removeFromSuperlayer];
}

- (BOOL) isBottomsControlVisible
{
    return NO;
}

#pragma mark - OAMapSourceSelectionDelegate

- (void) onNewSourceSelected
{
    [self setZoomValues];
    [self calculateDownloadInfo];
    [self setupView];
    [self.tableView reloadData];
}

#pragma mark - OAPreviewZoomLevelsCellDelegate

- (void) toggleMinZoomPickerRow
{
    [self toggleZoomPickerForRow:kMinZoomPickerRow];
}

- (void) toggleMaxZoomPickerRow
{
    [self toggleZoomPickerForRow:kMaxZoomPickerRow];
}

@end
