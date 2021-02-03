//
//  InitialRoutePlanningBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "InitialRoutePlanningBottomSheetViewController.h"
#import "OARootViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OATitleIconRoundCell.h"
#import "OAGPXRouteRoundCell.h"
#import "OAHeaderRoundCell.h"
#import "OAGPXDatabase.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"

#import "Localization.h"
#import "OAColors.h"

#define kIconTitleIconRoundCell @"OATitleIconRoundCell"
#define kGPXRouteRoundCell @"OAGPXRouteRoundCell"
#define kHeaderRoundCell @"OAHeaderRoundCell"

#define kVerticalMargin 16.
#define kHorizontalMargin 20.
#define kApproximateEmptyMenuHeight 250.
#define kApproximateGpxHeaderHeight 38.
#define kApproximateGpxCellHeight 70.

@interface InitialRoutePlanningBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource, OAOpenAddTrackDelegate>

@end

@implementation InitialRoutePlanningBottomSheetViewController
{
    NSArray<NSArray *> *_data;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self generateData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.tableView.sectionHeaderHeight = 16.;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"plan_route");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    int tracksCount = (int)[OAGPXDatabase sharedDb].gpxList.count;
    int maxHeight = DeviceScreenHeight / 3 * 2;
    
    int estimatedHeight = kApproximateEmptyMenuHeight + OAUtilities.getBottomMargin;
    if (tracksCount > 0)
        estimatedHeight += (kApproximateGpxHeaderHeight + tracksCount * kApproximateGpxCellHeight + kVerticalMargin);
    
    if (estimatedHeight > maxHeight)
        estimatedHeight = maxHeight;
    
    return estimatedHeight;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSMutableArray *actionSection = [NSMutableArray new];
    NSMutableArray *existingTracksSection = [NSMutableArray new];
    
    [actionSection addObject: @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"plan_route_create_new_route"),
            @"img" : @"ic_custom_trip",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"create_new_route"
        }];
    [actionSection addObject:@{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"plan_route_open_existing_track"),
            @"img" : @"ic_custom_folder_outlined",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"open_track"
        }];
    
    [data addObject:actionSection];

    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    NSArray *gpxList = [db.gpxList sortedArrayUsingComparator:^NSComparisonResult(OAGPX *obj1, OAGPX *obj2) {
        NSDate *time1 = [OAUtilities getFileLastModificationDate:obj1.gpxFileName];
        NSDate *time2 = [OAUtilities getFileLastModificationDate:obj2.gpxFileName];
        return [time2 compare:time1];
    }];
    
    NSArray *gpxTopList = [gpxList subarrayWithRange:NSMakeRange(0, min(5, (int) gpxList.count))];

    if (gpxTopList.count > 0)
    {
        [existingTracksSection addObject:@{
            @"type" : kHeaderRoundCell,
            @"title" : OALocalizedString(@"plan_route_last_modified"),
            @"key" : @"header"
        }];

        OsmAndAppInstance app = OsmAndApp.instance;
        for (OAGPX *gpx in gpxTopList)
        {
            [existingTracksSection addObject:@{
                    @"type" : kGPXRouteRoundCell,
                    @"track" : gpx,
                    @"title" : [gpx getNiceTitle],
                    @"distance" : [app getFormattedDistance:gpx.totalDistance],
                    @"time" : [app getFormattedTimeInterval:gpx.timeSpan shortFormat:YES],
                    @"wpt" : [NSString stringWithFormat:@"%d", gpx.wptPoints],
                    @"key" : @"gpx_route"
                }];
        }
        [data addObject:existingTracksSection];
    }
    
    _data = data;
}

- (void) onRightButtonPressed
{
    [super onRightButtonPressed];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kIconTitleIconRoundCell])
    {
        static NSString* const identifierCell = kIconTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            UIColor *tintColor = item[@"tintColor"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            }
            cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    else if ([type isEqualToString:kHeaderRoundCell])
    {
        static NSString* const identifierCell = kHeaderRoundCell;
        OAHeaderRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kHeaderRoundCell owner:self options:nil];
            cell = (OAHeaderRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = [item[@"title"] uppercaseString];
        }
        return cell;
    }
    else if ([type isEqualToString:kGPXRouteRoundCell])
    {
        static NSString* const identifierCell = kGPXRouteRoundCell;
        OAGPXRouteRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kGPXRouteRoundCell owner:self options:nil];
            cell = (OAGPXRouteRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.fileName.text = item[@"title"];
            cell.distanceLabel.text = item[@"distance"];
            cell.timeLabel.text = item[@"time"];
            cell.wptLabel.text = item[@"wpt"];
            cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

#pragma mark - UItableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"create_new_route"])
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] init]];
        return;
    }
    else if ([key isEqualToString:@"open_track"])
    {
        OAOpenAddTrackViewController *openExistingTrackViewController = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOAOpenExistingTrack];
        openExistingTrackViewController.delegate = self;
        [self presentViewController:openExistingTrackViewController animated:YES completion:nil];
        return;
    }
    else if ([key isEqualToString:@"gpx_route"])
    {
        OAGPX* track = item[@"track"];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] initWithFileName:track.gpxFileName]];
        return;
    }
}

#pragma mark - OAOpenExistingTrackDelegate

- (void) closeBottomSheet
{
    [self onRightButtonPressed];
}

- (void)onFileSelected:(NSString *)gpxFileName
{
}

@end
