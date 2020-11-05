//
//  OAPointOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPointOptionsBottomSheetViewController.h"
#import "OATitleIconRoundCell.h"
#import "Localization.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAColors.h"

#define kIconTitleIconRoundCell @"OATitleIconRoundCell"

@interface OAPointOptionsBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAPointOptionsBottomSheetViewController
{
    OAGpxTrkPt *_point;
    NSInteger _pointIndex;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) initWithPoint:(OAGpxTrkPt *)point index:(NSInteger)pointIndex
{
    self = [super init];
    if (self) {
        _point = point;
        _pointIndex = pointIndex;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = 16.;
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
}

- (void) applyLocalization
{
    self.titleView.text = [NSString stringWithFormat:OALocalizedString(@"point_num"), _pointIndex];
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"move_point"),
            @"img" : @"ic_custom_change_object_position",
            @"key" : @"move_point"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"add_before"),
            @"img" : @"ic_custom_add_point_before"
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"add_after"),
            @"img" : @"ic_custom_add_point_after"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"trim_before"),
            @"img" : @"ic_custom_trim_before"
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"trim_after"),
            @"img" : @"ic_custom_trim_after"
        }
    ]];
    
//    [data addObject:@[
//        @{
//            @"type" : kIconTitleIconRoundCell,
//            @"title" : OALocalizedString(@"change_route_type_before"),
//            @"img" : @"ic_custom_straight_line"
//        },
//        @{
//            @"type" : kIconTitleIconRoundCell,
//            @"title" : OALocalizedString(@"change_route_type_after"),
//            @"img" : @"ic_custom_straight_line"
//        }
//    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"delete_point"),
            @"img" : @"ic_custom_remove_outlined",
            @"custom_color" : UIColorFromRGB(color_primary_red)
        }
    ]];
    _data = data;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:kIconTitleIconRoundCell])
    {
        static NSString* const identifierCell = kIconTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            
            
            UIColor *tintColor = item[@"custom_color"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.textColorNormal = tintColor;
                cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.textColorNormal = nil;
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
                cell.titleView.textColor = UIColor.blackColor;
                cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            }
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
    if ([item[@"key"] isEqualToString:@"move_point"])
    {
        if (self.delegate)
            [self.delegate onMovePoint:_pointIndex];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
