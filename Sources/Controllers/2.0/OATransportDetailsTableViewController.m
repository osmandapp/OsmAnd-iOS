//
//  OATransportDetailsTableViewController.m
//  OsmAnd
//
//  Created by Paul on 20.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATransportDetailsTableViewController.h"
#import "OAPublicTransportRouteCell.h"
#import "OAPublicTransportShieldCell.h"
#import "OAPublicTransportPointCell.h"
#import "Localization.h"

@interface OATransportDetailsTableViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OATransportDetailsTableViewController
{
    NSArray<NSDictionary *> *_data;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _data = @[@{@"cell" : @"OAPublicTransportShieldCell"},
                  @{@"cell" : @"OAPublicTransportRouteCell"},
                  @{@"cell" : @"OAPublicTransportPointCell", @"img" : @"ic_custom_start_point", @"title" : @"Start", @"time" : @"0:00", @"top_route_line" : @(NO), @"bottom_route_line" : @(NO)},
                  @{@"cell" : @"OAPublicTransportPointCell", @"img" : @"ic_profile_pedestrian", @"title" : @"By foot", @"time" : @"0:05", @"top_route_line" : @(NO), @"bottom_route_line" : @(NO)},
                  @{@"cell" : @"OAPublicTransportPointCell", @"title" : @"Hotel ABC", @"descr" : @"Board at stop", @"time" : @"0:10", @"top_route_line" : @(YES), @"bottom_route_line" : @(YES)},
                  @{@"cell" : @"OAPublicTransportPointCell", @"img" : @"ic_custom_destination", @"title" : @"Independence Square", @"descr" : @"Exit at", @"time" : @"0:10", @"top_route_line" : @(YES), @"bottom_route_line" : @(NO), @"small_icon" : @(YES)}];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (NSDictionary *) getItem:(NSIndexPath *) indexPath
{
    return _data[indexPath.row];
}

- (CGFloat) getMinimizedContentHeight
{
    CGFloat res = 0;
    for (NSInteger i = 0; i < 2; i++)
    {
        res += [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].frame.size.height;
    }
    return res;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:@"OAPublicTransportRouteCell"])
    {
        NSString* identifierCell = item[@"cell"];
        OAPublicTransportRouteCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAPublicTransportRouteCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            // TODO: set route labels and correct data
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.detailsButton setTitle:OALocalizedString(@"res_details") forState:UIControlStateNormal];
            [cell.showOnMapButton setTitle:OALocalizedString(@"sett_show") forState:UIControlStateNormal];
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAPublicTransportShieldCell"])
    {
        NSString* identifierCell = item[@"cell"];
        OAPublicTransportShieldCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAPublicTransportShieldCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell needsSafeAreaInsets:NO];
            [cell setData:@(4)];
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAPublicTransportPointCell"])
    {
        NSString* identifierCell = item[@"cell"];
        OAPublicTransportPointCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAPublicTransportPointCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSString *imageName = item[@"img"];
            if (imageName)
            {
                cell.iconView.hidden = NO;
                [cell.iconView setImage:[UIImage imageNamed:imageName]];
            }
            else
            {
                cell.iconView.hidden = YES;
            }
            cell.descView.text = item[@"descr"];
            cell.textView.text = item[@"title"];
            
            cell.topRouteLineView.hidden = ![item[@"top_route_line"] boolValue];
            cell.bottomRouteLineView.hidden = ![item[@"bottom_route_line"] boolValue];
            
            cell.timeLabel.text = item[@"time"];
            
            [cell showSmallIcon:[item[@"small_icon"] boolValue]];
        }
        
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"cell"] isEqualToString:@"OAPublicTransportRouteCell"] || [item[@"cell"] isEqualToString:@"OAPublicTransportPointCell"])
        return UITableViewAutomaticDimension;
    else if ([item[@"cell"] isEqualToString:@"OAPublicTransportShieldCell"])
        return [OAPublicTransportShieldCell getCellHeight:tableView.frame.size.width shields:@[@"abcdefg", @"abcdefg", @"abcdefg", @"abcdefg"] needsSafeArea:NO];
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return 118.;
    return 44.;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
