//
//  OAAddWaypointBottomSheetViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAAddWaypointBottomSheetViewController.h"
#import "Localization.h"
#import "OATargetPoint.h"
#import "OARTargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OAMenuSimpleCell.h"
#import "OAWaypointHeaderCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OAAddWaypointBottomSheetScreen
{
    OsmAndAppInstance _app;
    OATargetPointsHelper *_targetPointsHelper;
    
    OATargetPoint *_targetPoint;
    NSArray* _data;
}

@synthesize tableData, vwController, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAAddWaypointBottomSheetViewController *)viewController
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (id) initWithTable:(UITableView *)tableView viewController:(OAAddWaypointBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _targetPoint = param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAAddWaypointBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    _targetPointsHelper = [OATargetPointsHelper sharedInstance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{ @"title" : OALocalizedString(@"new_destination_point_dialog"),
                      @"type" : @"OAWaypointHeaderCell" } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"replace_destination_point"),
                      @"key" : @"replace_destination_point",
                      @"description" : [self getCurrentPointName:[_targetPointsHelper getPointToNavigate] start:NO],
                      @"img" : @"ic_list_destination",
                      @"type" : @"OAMenuSimpleCell" } ];

    [arr addObject:@{ @"title" : OALocalizedString(@"make_as_start_point"),
                      @"key" : @"make_as_start_point",
                      @"description" : [self getCurrentPointName:[_targetPointsHelper getPointToStart] start:YES],
                      @"img" : @"ic_list_startpoint",
                      @"type" : @"OAMenuSimpleCell" } ];

    [arr addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];

    [arr addObject:@{ @"title" : OALocalizedString(@"keep_and_add_destination_point"),
                      @"key" : @"keep_and_add_destination_point",
                      @"description" : OALocalizedString(@"subsequent_dest_description"),
                      @"img" : @"ic_action_route_subsequent_destination",
                      @"type" : @"OAMenuSimpleCell" } ];

    [arr addObject:@{ @"title" : OALocalizedString(@"add_as_first_destination_point"),
                      @"key" : @"add_as_first_destination_point",
                      @"description" : OALocalizedString(@"first_intermediate_dest_description"),
                      @"img" : @"ic_action_route_first_intermediate",
                      @"type" : @"OAMenuSimpleCell" } ];

    [arr addObject:@{ @"title" : OALocalizedString(@"add_as_last_destination_point"),
                      @"key" : @"add_as_last_destination_point",
                      @"description" : OALocalizedString(@"last_intermediate_dest_description"),
                      @"img" : @"ic_action_route_last_intermediate",
                      @"type" : @"OAMenuSimpleCell" } ];
    
    _data = [NSArray arrayWithArray:arr];
}

- (NSString *) getCurrentPointName:(OARTargetPoint *)point start:(BOOL)start
{
    NSMutableString *builder = [NSMutableString stringWithString:OALocalizedString(@"shared_string_current")];
    [builder appendString:@": "];
    if (point)
    {
        NSString *pointName = [point getOnlyName].length > 0 ? [point getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"map_settings_map"), [NSString stringWithFormat:@"%@ %.3f %@ %.3f", OALocalizedString(@"Lat"), [point getLatitude], OALocalizedString(@"Lon"), [point getLongitude]]];

        [builder appendString:pointName];
    }
    else if (start)
    {
        [builder appendString:OALocalizedString(@"shared_string_my_location")];
    }
    return [NSString stringWithString:builder];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OAMenuSimpleCell"])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:@"OAWaypointHeaderCell"])
    {
        return 44.0;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0)];
    }
    else
    {
        return 44.0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OAMenuSimpleCell"])
    {
        static NSString* const identifierCell = @"OAMenuSimpleCell";
        OAMenuSimpleCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMenuSimpleCell" owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.textView.textColor = UIColorFromRGB(color_menu_button);
            cell.descriptionView.textColor = UIColorFromRGB(color_secondary_text_blur);
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage imageNamed:imgName];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            cell.imgView.image = img;
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OAWaypointHeaderCell"])
    {
        static NSString* const identifierCell = @"OAWaypointHeaderCell";
        OAWaypointHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWaypointHeaderCell" owner:self options:nil];
            cell = (OAWaypointHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.progressView.hidden = YES;
            cell.switchView.hidden = YES;
            cell.imageButton.hidden = YES;
            cell.textButton.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OAMenuSimpleCell"])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *key = item[@"key"];
    if (_targetPoint)
    {
        CLLocation *menuLocation = [[CLLocation alloc] initWithLatitude:_targetPoint.location.latitude longitude:_targetPoint.location.longitude];
        OAPointDescription *menuName = _targetPoint.pointDescription;

        if ([key isEqualToString:@"replace_destination_point"])
        {
            [_targetPointsHelper navigateToPoint:menuLocation updateRoute:YES intermediate:-1 historyName:menuName];
            [vwController dismiss];
        }
        else if ([key isEqualToString:@"make_as_start_point"])
        {
            OARTargetPoint *start = [_targetPointsHelper getPointToStart];
            if (start)
            {
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[start getLatitude] longitude:[start getLongitude]];
                [_targetPointsHelper navigateToPoint:location updateRoute:NO intermediate:0 historyName:[start getPointDescription]];
            }
            [_targetPointsHelper setStartPoint:menuLocation updateRoute:YES name:menuName];
            [vwController dismiss];
        }
        else if ([key isEqualToString:@"keep_and_add_destination_point"])
        {
            [_targetPointsHelper navigateToPoint:menuLocation updateRoute:YES intermediate:(int)([_targetPointsHelper getIntermediatePoints].count + 1) historyName:menuName];
            [vwController dismiss];
        }
        else if ([key isEqualToString:@"add_as_first_destination_point"])
        {
            [_targetPointsHelper navigateToPoint:menuLocation updateRoute:YES intermediate:0 historyName:menuName];
            [vwController dismiss];
        }
        else if ([key isEqualToString:@"add_as_last_destination_point"])
        {
            [_targetPointsHelper navigateToPoint:menuLocation updateRoute:YES intermediate:(int)[_targetPointsHelper getIntermediatePoints].count historyName:menuName];
            [vwController dismiss];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [vwController dismiss];
}

@end

@interface OAAddWaypointBottomSheetViewController ()

@end

@implementation OAAddWaypointBottomSheetViewController

- (instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint
{
    return [super initWithParam:targetPoint];
}

- (OATargetPoint *)targetPoint
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAAddWaypointBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.targetPoint];
    
    [super setupView];
}

@end
