//
//  OADownloadMapProgressViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapProgressViewController.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OADownloadProgressBarCell.h"
#import "OADownloadInfoTableViewCell.h"
#import "OAResourcesUIHelper.h"
#import "OASQLiteTileSource.h"

#include "Localization.h"
#include "OASizes.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>

#define kDownloadProgressCell @"OADownloadProgressBarCell"
#define kGeneralInfoCell @"time_cell"

@interface OADownloadMapProgressViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *navBarCancelButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OADownloadMapProgressViewController
{
    OAResourceItem *_item;
    OAMapRendererView *_mapView;
    QHash<OsmAnd::ZoomLevel, QVector<OsmAnd::TileId>> _tileIds;
    NSArray *_data;
    NSInteger _numberOfTiles;
    CGFloat _downloadSize;
    NSInteger _minZoom;
    NSInteger _maxZoom;
    CALayer *_horizontalLine;
    NSInteger _downloadedNumberOfTiles;
    BOOL _downloaded;
    BOOL _cancelled;
}

- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
    [self.cancelButton setTitle: OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (instancetype) initWithResource:(OAResourceItem *)item minZoom:(NSInteger)minZoom maxZoom:(NSInteger)maxZoom
{
    self = [super init];
    if (self) {
        _item = item;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    _mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    _downloaded = NO;
    _horizontalLine = [CALayer layer];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 0.5);
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    _bottomToolBarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [_bottomToolBarView.layer addSublayer:_horizontalLine];
    _cancelButton.layer.cornerRadius = 9.0;
    _numberOfTiles = 0;
    _tileIds = [self getTileIds:_numberOfTiles];
    _downloadSize = _numberOfTiles * 12000;
    [self setupView];
    [self startDownload];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    [tableData addObject:@{
        @"type" : @"OADownloadProgressBarCell",
    }];
    [tableData addObject:@{
        @"type" : kGeneralInfoCell,
        @"title" : OALocalizedString(@"number_of_tiles"),
        @"value" : [NSString stringWithFormat:@"/ %@", [NSString stringWithFormat:@"%ld", _numberOfTiles]],
        @"key" : @"num_of_tiles"
    }];
    [tableData addObject:@{
        @"type" : kGeneralInfoCell,
        @"title" : OALocalizedString(@"download_size"),
        @"value" : [NSString stringWithFormat:@"/ ~ %@", [NSByteCountFormatter stringFromByteCount:_downloadSize countStyle:NSByteCountFormatterCountStyleFile]],
        @"key" : @"download_size"
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (IBAction) cancelButtonPressed:(id)sender {
    if (_downloaded)
        [OARootViewController.instance.mapPanel targetHide];
    [self cancelDownload];
}

- (IBAction) navBarCancelButtonPressed:(id)sender {
    if (_downloaded)
        [OARootViewController.instance.mapPanel targetHide];
    [self cancelDownload];
}

- (void) cancelDownload
{
    _cancelled = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)skipCurrentTile {
    _downloadedNumberOfTiles++;
    [self updateProgress];
}

- (void) startDownload
{
    if (!_item)
        return;
    
    if (![_item isKindOfClass:OASqliteDbResourceItem.class] && ![_item isKindOfClass:OAOnlineTilesResourceItem.class])
        return;
    
    BOOL isSqlite = [_item isKindOfClass:OASqliteDbResourceItem.class];
    OASQLiteTileSource *sqliteSource = nil;
    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineSource = nullptr;
    
    NSString *downloadPath = nil;
    if (isSqlite)
    {
        OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *) _item;
        sqliteSource = [[OASQLiteTileSource alloc] initWithFilePath:sqliteItem.path];
    }
    else
    {
        OAOnlineTilesResourceItem *onlineItem = (OAOnlineTilesResourceItem *) _item;
        onlineSource = onlineItem.onlineTileSource;
        downloadPath = [OsmAndApp.instance.cachePath stringByAppendingPathComponent:onlineSource->name.toNSString()];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSInteger requests = 0;
        NSInteger reqLimit = 50;
        NSFileManager *fileManager = NSFileManager.defaultManager;
        for (const auto zoomLevel : _tileIds.keys())
        {
            for (const auto& tileId : _tileIds.value(zoomLevel))
            {
                if (_cancelled)
                    break;
                
                if (isSqlite && sqliteSource)
                {
                    if ([sqliteSource getBytes:tileId.x y:tileId.y zoom:zoomLevel])
                    {
                        [self skipCurrentTile];
                    }
                    else
                    {
                        NSString *url = [sqliteSource getUrlToLoad:tileId.x y:tileId.y zoom:zoomLevel];
                        if (url)
                        {
                            requests++;
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
                                if (data)
                                {
                                    [sqliteSource insertImage:tileId.x y:tileId.y zoom:zoomLevel data:data];
                                }
                                requests--;
                                _downloadedNumberOfTiles++;
                                [self updateProgress];
                            });
                            if (_cancelled)
                                break;
                        }
                        else
                        {
                            [self skipCurrentTile];
                        }
                    }
                }
                else if (!isSqlite && onlineSource != nullptr && downloadPath)
                {
                    NSString *tilePath = [NSString stringWithFormat:@"%@/%@/%@/%@.tile", downloadPath, @(zoomLevel).stringValue, @(tileId.x).stringValue, @(tileId.y).stringValue];
                    if ([fileManager fileExistsAtPath:tilePath])
                    {
                        [self skipCurrentTile];
                    }
                    else
                    {
                        NSString *urlToLoad = onlineSource->urlToLoad.toNSString();
                        QList<QString> randomsArray;
                        NSString *url = OsmAnd::OnlineRasterMapLayerProvider::buildUrlToLoad(QString::fromNSString(urlToLoad), randomsArray, tileId.x, tileId.y, zoomLevel).toNSString();
                        if (url)
                        {
                            requests++;
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
                                if (data)
                                {
                                    NSString *dir = [tilePath stringByDeletingLastPathComponent];
                                    if (![fileManager fileExistsAtPath:dir isDirectory:nil])
                                        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
                                    [data writeToFile:tilePath atomically:YES];
                                }
                                requests--;
                                _downloadedNumberOfTiles++;
                                [self updateProgress];
                            });
                            if (_cancelled)
                                break;
                        }
                        else
                        {
                            [self skipCurrentTile];
                        }
                    }
                }
                if (requests >= reqLimit)
                {
                    while (requests != 0)
                    {
                        [NSThread sleepForTimeInterval:0.5];
                    }
                }
            }
        }
    });
}

- (void) updateProgress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        if (_downloadedNumberOfTiles == _numberOfTiles)
            [self onDownloadFinished];
    });
}

- (void) onDownloadFinished
{
    [OsmAndApp.instance.mapSettingsChangeObservable notifyEvent];
    _downloaded = YES;
    [self.cancelButton setTitle: OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [_tableView reloadData];
}

#pragma mark - Downloading process

- (QHash<OsmAnd::ZoomLevel, QVector<OsmAnd::TileId>>) getTileIds:(NSInteger &)tileCount
{
    OsmAnd::AreaI bbox = [_mapView getVisibleBBox31];
    QHash<OsmAnd::ZoomLevel, QVector<OsmAnd::TileId>> tileIds;
    QVector<OsmAnd::TileId> currentZoomIds;
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(bbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(bbox.bottomRight);
    for (NSInteger zoom = _minZoom; zoom <= _maxZoom; zoom++)
    {
        int x1 = OsmAnd::Utilities::getTileNumberX(zoom, topLeft.longitude);
        int x2 = OsmAnd::Utilities::getTileNumberX(zoom, bottomRight.longitude);
        int y1 = OsmAnd::Utilities::getTileNumberY(zoom, topLeft.latitude);
        int y2 = OsmAnd::Utilities::getTileNumberY(zoom, bottomRight.latitude);
        for (int x = x1; x <= x2; x++)
        {
            for (int y = y1; y <= y2; y++)
            {
                const auto tileId = OsmAnd::TileId::fromXY(x, y);
                currentZoomIds.push_back(tileId);
                tileCount++;
            }
        }
        tileIds.insert(OsmAnd::ZoomLevel(zoom), currentZoomIds);
        currentZoomIds.clear();
    }
    return tileIds;
}


#pragma mark - UITableViewDelegate

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.row];
    
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kDownloadProgressCell])
    {
        static NSString* const identifierCell = @"OADownloadProgressBarCell";
        OADownloadProgressBarCell* cell;
        cell = (OADownloadProgressBarCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADownloadProgressBarCell" owner:self options:nil];
            cell = (OADownloadProgressBarCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.progressStatusLabel.text = @"Downloading";
        cell.progressValueLabel.text = [NSString stringWithFormat:@"%ld%%", (NSInteger) (((double)_downloadedNumberOfTiles / (double)_numberOfTiles * 100.))];
        [cell.progressBarView setProgress:(double)_downloadedNumberOfTiles / (double)_numberOfTiles];
        
        return cell;
    }
    else if ([cellType isEqualToString:kGeneralInfoCell])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OADownloadInfoTableViewCell* cell;
        cell = (OADownloadInfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADownloadInfoTableViewCell" owner:self options:nil];
            cell = (OADownloadInfoTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSString *progressText = @"";
        if ([item[@"key"] isEqualToString:@"num_of_tiles"])
        {
            progressText = [NSString stringWithFormat:@"%ld", _downloadedNumberOfTiles];
        }
        else if ([item[@"key"] isEqualToString:@"download_size"])
        {
            progressText = [NSByteCountFormatter stringFromByteCount:_downloadedNumberOfTiles * 12000 countStyle:NSByteCountFormatterCountStyleFile];
        }
        cell.titleLabel.text = item[@"title"];
        cell.doneLabel.text = progressText;
        cell.totalLabel.text = item[@"value"];
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _downloaded ? OALocalizedString(@"use_of_downloaded_map") : @"";
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

@end
