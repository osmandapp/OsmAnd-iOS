//
//  OARouteParameterValuesViewController.m
//  OsmAnd
//
//  Created by Paul on 21.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParameterValuesViewController.h"
#import "OAAppSettings.h"
#import "OASettingsTitleTableViewCell.h"
#import "OARoutingHelper.h"
#import "OARoutePreferencesParameters.h"

#include <generalRouter.h>

typedef NS_ENUM(NSInteger, EOARouteParamType) {
    EOARouteParamTypeGroup = 0,
    EOARouteParamTypeNumeric
};

@interface OARouteParameterValuesViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OARouteParameterValuesViewController
{
    RoutingParameter _param;
    OALocalRoutingParameterGroup *_group;
    OAProfileString *_setting;

    OAAppSettings *_settings;
    
    EOARouteParamType _type;
}

- (instancetype) initWithRoutingParameterGroup:(OALocalRoutingParameterGroup *)group appMode:(OAApplicationMode *)mode
{
    self = [super initWithAppMode:mode];
    if (self) {
        [self commonInit];
        _group = group;
        _type = EOARouteParamTypeGroup;
    }
    return self;
}

- (instancetype) initWithRoutingParameter:(RoutingParameter &)parameter appMode:(OAApplicationMode *)mode
{
    self = [super initWithAppMode:mode];
    if (self) {
        [self commonInit];
        _param = parameter;
        _setting = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:_param.id.c_str()] defaultValue:_param.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
        _type = EOARouteParamTypeNumeric;
    }
    return self;
}

- (void) commonInit
{
    _settings = OAAppSettings.sharedManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = _type == EOARouteParamTypeNumeric ? [NSString stringWithUTF8String:_param.name.c_str()] : [_group getText];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _type == EOARouteParamTypeGroup ? _group.getRoutingParameters.count : _param.possibleValues.size();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = _type == EOARouteParamTypeGroup ? [_group.getRoutingParameters[indexPath.row] getText] : [NSString stringWithUTF8String:_param.possibleValueDescriptions[indexPath.row].c_str()];
    
    OASettingsTitleTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:text];
        BOOL isSelected = NO;
        if (_type == EOARouteParamTypeNumeric)
            isSelected = [[NSString stringWithFormat:@"%.1f", _param.possibleValues[indexPath.row]] isEqualToString:[_setting get:self.appMode]];
        else if (_type == EOARouteParamTypeGroup)
            isSelected = _group.getSelected == _group.getRoutingParameters[indexPath.row];
        
        if (isSelected)
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_type == EOARouteParamTypeNumeric)
    {
        [_setting set:[NSString stringWithFormat:@"%.1f", _param.possibleValues[indexPath.row]] mode:self.appMode];
    }
    else
    {
        for (NSInteger i = 0; i < _group.getRoutingParameters.count; i++)
        {
            OALocalRoutingParameter *param = _group.getRoutingParameters[i];
            [param setSelected:i == indexPath.row];
        }
    }
    [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
    
    [self dismissViewController];
}

@end
