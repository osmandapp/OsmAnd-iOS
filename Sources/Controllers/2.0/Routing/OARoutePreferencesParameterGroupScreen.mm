//
//  OARoutePreferencesParameterGroupScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesParameterGroupScreen.h"
#import "OARoutePreferencesViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OARoutingHelper.h"
#import "OASettingsTitleTableViewCell.h"

@interface OARoutePreferencesParameterGroupScreen ()

@end

@implementation OARoutePreferencesParameterGroupScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
}

@synthesize preferencesScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OARoutePreferencesViewController *)viewController group:(OALocalRoutingParameterGroup *)group
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _routingHelper = [OARoutingHelper sharedInstance];
        
        _group = group;
        title = [group getText];
        
        preferencesScreen = ERoutePreferencesScreenParameterGroup;
        
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
}

- (void) setupView
{
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_group getRoutingParameters].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
    OASettingsTitleTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OALocalRoutingParameter *p = [_group getRoutingParameters][indexPath.row];
        
        [cell.textView setText:[p getText]];
        
        if ([p isSelected])
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *p = [_group getRoutingParameters][indexPath.row];
    return [OASettingsTitleTableViewCell getHeight:[p getText] cellWidth:tableView.bounds.size.width];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *selected = [_group getRoutingParameters][indexPath.row];
    NSArray<OALocalRoutingParameter *> *params = [_group getRoutingParameters];
    for (OALocalRoutingParameter *p in params)
    {
        [p setSelected:p == selected];
    }
    
    [tableView reloadData];
    if (_group.delegate)
        [_group.delegate updateParameters];
    
    [_routingHelper recalculateRouteDueToSettingsChange];
}

@end
