//
//  OARouteParameterValuesViewController.m
//  OsmAnd
//
//  Created by Paul on 21.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParameterValuesViewController.h"
#import "OAAppSettings.h"
#import "OAIconTextTableViewCell.h"
#import "OARoutingHelper.h"
#import "OARoutePreferencesParameters.h"
#import "OATableViewCustomFooterView.h"
#import "OAColors.h"

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
    OACommonString *_setting;

    OAAppSettings *_settings;
    
    EOARouteParamType _type;
    NSInteger _indexSelected;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
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
    NSString *text;
    UIImage *icon;
    UIColor *color;
    if (_type == EOARouteParamTypeGroup)
    {
        OALocalRoutingParameter *routeParam = _group.getRoutingParameters[indexPath.row];
        text = [routeParam getText];
        icon = [[routeParam getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        color = [routeParam getTintColor];
    }
    else
    {
        text = [NSString stringWithUTF8String:_param.possibleValueDescriptions[indexPath.row].c_str()];
    }

    OAIconTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextTableViewCell *) nib[0];
    }
    if (cell)
    {
        [cell.textView setText:text];
        cell.iconView.image = icon;
        [cell showImage:icon != nil];

        BOOL isSelected = NO;
        if (_type == EOARouteParamTypeNumeric)
            isSelected = [[NSString stringWithFormat:@"%.1f", _param.possibleValues[indexPath.row]] isEqualToString:[_setting get:self.appMode]];
        else if (_type == EOARouteParamTypeGroup)
            isSelected = _group.getSelected == _group.getRoutingParameters[indexPath.row];

        if (isSelected)
        {
            _indexSelected = indexPath.row;
            [cell.arrowIconView setImage:color
                    ? [UIImage templateImageNamed:@"menu_cell_selected"]
                    : [UIImage imageNamed:@"menu_cell_selected"]];

            if (color)
                cell.iconView.tintColor = color;
        }
        else
        {
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
            [cell.arrowIconView setImage:nil];
        }

        if (color)
            cell.arrowIconView.tintColor = color;
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
    else if (_type == EOARouteParamTypeGroup)
    {
        OALocalRoutingParameter *useElevation = nil;
        if (_group.getRoutingParameters.count > 0
                && ([[NSString stringWithUTF8String:_group.getRoutingParameters.firstObject.routingParameter.id.c_str()] isEqualToString:kRouteParamIdHeightObstacles]))
            useElevation = _group.getRoutingParameters.firstObject;
        BOOL anySelected = NO;

        for (NSInteger i = 0; i < _group.getRoutingParameters.count; i++)
        {
            OALocalRoutingParameter *param = _group.getRoutingParameters[i];
            if (i == indexPath.row && param == useElevation)
                anySelected = YES;

            [param setSelected:i == indexPath.row && !anySelected];
        }
        if (useElevation)
            [useElevation setSelected:!anySelected];
    }
    [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
    
    [self dismissViewController];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (_type != EOARouteParamTypeGroup)
        return 0.001;

    OALocalRoutingParameter *param = _group.getRoutingParameters[_indexSelected];
    NSString *footer = [param getDescription];
    return [OATableViewCustomFooterView getHeight:footer ? footer : @"" width:self.tableView.bounds.size.width];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (_type != EOARouteParamTypeGroup)
        return nil;

    OALocalRoutingParameter *param = _group.getRoutingParameters[_indexSelected];
    NSString *footer = [param getDescription];
    if (!footer || footer.length == 0)
        return nil;

    OATableViewCustomFooterView *vw =
            [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:footer attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    }];
    vw.label.attributedText = textStr;
    return vw;
}

@end
