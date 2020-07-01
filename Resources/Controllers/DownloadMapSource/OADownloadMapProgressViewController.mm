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
    
    NSArray *_data;
    NSInteger _numberOfTiles;
    CGFloat _downloadSize;
    NSInteger _minZoom;
    NSInteger _maxZoom;
    CALayer *_horizontalLine;
    CGFloat _downloadedNumberOfTiles;
    CGFloat _downloadedOfTotalSize;
    BOOL _downloaded;
}

- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
    [self.cancelButton setTitle: OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (instancetype) initWithGeneralData:(NSInteger)numberOfTiles size:(CGFloat)downloadSize minZoom:(NSInteger)minZoom maxZoom:(NSInteger)maxZoom 
{
    self = [super init];
    _numberOfTiles = numberOfTiles;
    _downloadSize = downloadSize;
    _minZoom = minZoom;
    _maxZoom = maxZoom;
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
    [self setupView];
    [self getTileIds];
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

#pragma mark - Downloading process

- (void) getTileIds
{
    OsmAnd::AreaI bbox = [_mapView getVisibleBBox31];
    QVector<OsmAnd::TileId> tileIds;
    int x1 = OsmAnd::Utilities::getTileNumberX(_minZoom, OsmAnd::Utilities::get31LongitudeX(bbox.left()));
    int x2 = OsmAnd::Utilities::getTileNumberX(_minZoom, OsmAnd::Utilities::get31LongitudeX(bbox.right()));
    int y1 = OsmAnd::Utilities::getTileNumberY(_minZoom, OsmAnd::Utilities::get31LatitudeY(bbox.top()));
    int y2 = OsmAnd::Utilities::getTileNumberY(_minZoom, OsmAnd::Utilities::get31LatitudeY(bbox.bottom()));
    for (int x = x1; x <= x2; x++)
    {
        for (int y = y1; y <= y2; y++)
        {
            const auto tileId = OsmAnd::TileId::fromXY(x, y);
            for (int i = 1; i < _maxZoom - _minZoom; i++)
            {
                QVector<OsmAnd::TileId> tmpTileIds = OsmAnd::Utilities::getTileIdsUnderscaledByZoomShift(tileId, (unsigned int)i);
                for (const auto& tile : tmpTileIds)
                    tileIds.push_back(tile);
            }
        }
    }
}

#pragma mark - TableView

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
        cell.progressStatusLabel.text = OALocalizedString(@"downloading");
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
