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

#include "Localization.h"
#include "OASizes.h"

#include <OsmAndCore/Utilities.h>

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
    OAMapRendererView *_mapView;
    QVector<OsmAnd::TileId> _tileIds;
    NSArray *_data;
    NSInteger _numberOfTiles;
    CGFloat _downloadSize;
    NSInteger _minZoom;
    NSInteger _maxZoom;
    CALayer *_horizontalLine;
    CGFloat _downloadedNumberOfTiles;
    CGFloat _downloadedOfTotalSize;
    BOOL _downloaded;
    BOOL _cancelled;
}

- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
    [self.cancelButton setTitle: OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (instancetype) initWithMinZoom:(NSInteger)minZoom maxZoom:(NSInteger)maxZoom 
{
    self = [super init];
    if (self) {
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
    _numberOfTiles = _tileIds.count();
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
    }];
    
    [tableData addObject:@{
        @"type" : kGeneralInfoCell,
        @"title" : OALocalizedString(@"download_size"),
        @"value" : [NSString stringWithFormat:@"/ ~ %@", [NSByteCountFormatter stringFromByteCount:_downloadSize countStyle:NSByteCountFormatterCountStyleFile]],
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (IBAction) cancelButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) navBarCancelButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) startDownload
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _tileIds = [self getTileIds];
    });
}

#pragma mark - Downloading process

- (QVector<OsmAnd::TileId>) getTileIds
{
    OsmAnd::AreaI bbox = [_mapView getVisibleBBox31];
    
    QVector<OsmAnd::TileId> tileIds;
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
                tileIds.push_back(tileId);
            }
        }
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
        cell.progressValueLabel.text = @"0%";
        
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
        cell.titleLabel.text = item[@"title"];
        cell.doneLabel.text = @"0";
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
