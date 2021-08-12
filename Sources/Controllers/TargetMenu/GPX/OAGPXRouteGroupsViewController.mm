//
//  OAGPXRouteGroupsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteGroupsViewController.h"
#import "Localization.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxRouteWptItem.h"
#import "OAIconTextDescCell.h"

typedef enum
{
    kSelectedNone = 0,
    kSelectedHalf,
    kSelectedAll,
    
} OARouteGroupSelection;

@interface OARouteGroup : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic, assign) BOOL modified;
@property (nonatomic, assign) OARouteGroupSelection selection;
@property (nonatomic) NSString *waypointsStr;

@end

@implementation OARouteGroup

@end

@interface OAGPXRouteGroupsViewController ()

@end

@implementation OAGPXRouteGroupsViewController
{
    NSMutableArray *_groups;
}


- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"gpx_group_select");
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self generateData];
    [self setupView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)generateData
{
    OAGPXRouteDocument *doc = [OAGPXRouter sharedInstance].routeDoc;
    
    _groups = [NSMutableArray array];
    for (NSString *name in doc.groups)
    {
        OARouteGroup *group = [[OARouteGroup alloc] init];
        group.name = name;
        group.modified = NO;
        
        NSArray *activeWaypoints = [doc getWaypointsByGroup:name activeOnly:YES];
        NSArray *allWaypoints = [doc getWaypointsByGroup:name activeOnly:NO];
        
        if (activeWaypoints.count == 0)
            group.selection = kSelectedNone;
        else if (activeWaypoints.count < allWaypoints.count)
            group.selection = kSelectedHalf;
        else
            group.selection = kSelectedAll;
        
        NSMutableString *wptsStr = [NSMutableString string];
        NSArray *source;
        if (activeWaypoints.count == 0)
            source = allWaypoints;
        else
            source = activeWaypoints;
        
        int i = 0;
        for (OAGpxRouteWptItem *item in source)
        {
            if (wptsStr.length > 0)
                [wptsStr appendString:@", "];
            
            [wptsStr appendString:item.point.name];
            
            i++;
            if (i > 10)
                break;
        }
        
        group.waypointsStr = wptsStr;
        
        [_groups addObject:group];
    }
    
}

-(void)setupView
{
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
}

- (IBAction)saveButtonClicked:(id)sender
{
    for (OARouteGroup *group in _groups)
    {
        if (group.modified)
        {
            OAGPXRouteDocument *doc = [OAGPXRouter sharedInstance].routeDoc;

            if (group.selection == kSelectedNone)
                [doc excludeGroupFromRouting:group.name];
            else
                [doc includeGroupToRouting:group.name];
        }
    }
    
    if (self.delegate)
        [self.delegate routeGroupsChanged];
    
    [self backButtonClicked:nil];
}

- (void)updateSelectionImage:(OAIconTextDescCell *)cell group:(OARouteGroup *)group
{
    switch (group.selection)
    {
        case kSelectedNone:
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selection_unchecked"]];
            break;
        case kSelectedHalf:
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selection_disabled"]];
            break;
        case kSelectedAll:
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selection_checked"]];
            break;
            
        default:
            cell.accessoryView = nil;
            break;
    }
}

#pragma mark - UITableViewDataSource

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"gpx_trip_groups");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAIconTextDescCell* cell;
    cell = (OAIconTextDescCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAIconTextDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OARouteGroup* group = _groups[indexPath.row];
        
        CGRect f = cell.textView.frame;
        f.origin.y = 8.0;
        cell.textView.frame = f;
        
        [cell.textView setText:group.name];
        if (group.waypointsStr.length == 0)
        {
            cell.descView.hidden = YES;
        }
        else
        {
            [cell.descView setText:group.waypointsStr];
            cell.descView.hidden = NO;
        }
        [cell.iconView setImage:[UIImage imageNamed:@"ic_group"]];
        cell.arrowIconView.hidden = YES;

        [self updateSelectionImage:cell group:group];
    }
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARouteGroup *group = _groups[indexPath.row];
    group.modified = YES;
    group.selection = (group.selection == kSelectedHalf | group.selection == kSelectedNone ? kSelectedAll : kSelectedNone);
    
    [self updateSelectionImage:(OAIconTextDescCell *)[tableView cellForRowAtIndexPath:indexPath] group:group];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
