//
//  OADownloadMapProgressViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapProgressViewController.h"
#import "OADownloadProgressBarCell.h"
#import "OADownloadInfoTableViewCell.h"
#import "OAResourcesUIHelper.h"
#import "OASQLiteTileSource.h"
#import "OAMapTileDownloader.h"
#import "OARootViewController.h"
#import "OATimeTableViewCell.h"

#include "Localization.h"
#include "OASizes.h"
#include "OAColors.h"

@interface OADownloadMapProgressViewController() <UITableViewDelegate, UITableViewDataSource, OATileDownloadDelegate>

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
    OAMapTileDownloader *_tileDownloader;
    NSArray *_data;
    NSInteger _numberOfTiles;
    CGFloat _downloadSize;
    int _minZoom;
    int _maxZoom;
    CALayer *_horizontalLine;
    NSInteger _downloadedNumberOfTiles;
    BOOL _downloaded;
}

- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
    [self.cancelButton setTitle: OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (instancetype) initWithResource:(OAResourceItem *)item minZoom:(int)minZoom maxZoom:(int)maxZoom numberOfTiles:(NSInteger)numOfTiles
{
    self = [super init];
    if (self) {
        _item = item;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _numberOfTiles = numOfTiles;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    _tileDownloader = [[OAMapTileDownloader alloc] initWithItem:_item minZoom:_minZoom maxZoom:_maxZoom];
    _tileDownloader.delegate = self;
    _downloaded = NO;
    _horizontalLine = [CALayer layer];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 0.5);
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    _bottomToolBarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [_bottomToolBarView.layer addSublayer:_horizontalLine];
    _cancelButton.layer.cornerRadius = 9.0;
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
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"number_of_tiles"),
        @"value" : [NSString stringWithFormat:@"/ %@", [NSString stringWithFormat:@"%ld", _numberOfTiles]],
        @"key" : @"num_of_tiles"
    }];
    [tableData addObject:@{
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"download_size"),
        @"value" : [NSString stringWithFormat:@"/ ~ %@", [NSByteCountFormatter stringFromByteCount:_downloadSize countStyle:NSByteCountFormatterCountStyleFile]],
        @"key" : @"download_size"
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _horizontalLine.frame = CGRectMake(0.0, 0.0, size.width, 0.5);
    } completion:nil];
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
    [_tileDownloader cancellAllRequests];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) startDownload
{
    [_tileDownloader startDownload];
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


#pragma mark - UITableViewDelegate

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.row];
    
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OADownloadProgressBarCell getCellIdentifier]])
    {
        OADownloadProgressBarCell* cell;
        cell = (OADownloadProgressBarCell *)[tableView dequeueReusableCellWithIdentifier:[OADownloadProgressBarCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADownloadProgressBarCell getCellIdentifier] owner:self options:nil];
            cell = (OADownloadProgressBarCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.progressStatusLabel.text = OALocalizedString(@"downloading");
        cell.progressValueLabel.text = [NSString stringWithFormat:@"%ld%%", (NSInteger) (((double)_downloadedNumberOfTiles / (double)_numberOfTiles * 100.))];
        [cell.progressBarView setProgress:(double)_downloadedNumberOfTiles / (double)_numberOfTiles];
        
        return cell;
    }
    else if ([cellType isEqualToString:[OATimeTableViewCell getCellIdentifier]])
    {
        OADownloadInfoTableViewCell* cell;
        cell = (OADownloadInfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADownloadInfoTableViewCell getCellIdentifier] owner:self options:nil];
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

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

#pragma mark - OATileDownloadDelegate

- (void) onTileDownloaded:(BOOL)updateUI
{
    _downloadedNumberOfTiles++;
    if (updateUI || _downloadedNumberOfTiles == _numberOfTiles)
        [self updateProgress];
}

@end
