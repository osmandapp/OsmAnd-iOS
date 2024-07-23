//
//  OARouteParameterValuesViewController.m
//  OsmAnd
//
//  Created by Paul on 21.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParameterValuesViewController.h"
#import "OAAppSettings.h"
#import "OARightIconTableViewCell.h"
#import "OARoutingHelper.h"
#import "OAApplicationMode.h"
#import "OARoutePreferencesParameters.h"
#import "OATableViewCustomHeaderView.h"
#import "OATableViewCustomFooterView.h"
#import "OAColors.h"
#import "Localization.h"
#import "OASizes.h"

#include <generalRouter.h>

typedef NS_ENUM(NSInteger, EOARouteParamType) {
    EOARouteParamTypeGroup = 0,
    EOARouteParamTypeNumeric
};

@implementation OARouteParameterValuesViewController
{
    RoutingParameter _param;
    OALocalRoutingParameterGroup *_group;
    OALocalRoutingParameter *_parameter;
    OACommonString *_setting;

    OAAppSettings *_settings;
    
    EOARouteParamType _type;
    NSInteger _indexSelected;
    BOOL _isHazmatCategory;
    BOOL _isAnyCategorySelected;
    BOOL _isGoodsRestrictionsCategory;
    
    UIView *_tableHeaderView;
}

#pragma mark - Initialization

- (instancetype) initWithRoutingParameterGroup:(OALocalRoutingParameterGroup *)group appMode:(OAApplicationMode *)mode
{
    self = [super initWithAppMode:mode];
    if (self)
    {
        _group = group;
        _type = EOARouteParamTypeGroup;
        [self postInit];
    }
    return self;
}

- (instancetype) initWithRoutingParameter:(OALocalRoutingParameter *)parameter appMode:(OAApplicationMode *)mode
{
    self = [super initWithAppMode:mode];
    if (self)
    {
        _parameter = parameter;
        _type = EOARouteParamTypeNumeric;
        [self postInit];
    }
    return self;
}

- (instancetype)initWithParameter:(RoutingParameter &)parameter appMode:(OAApplicationMode *)mode
{
    self = [super initWithAppMode:mode];
    if (self)
    {
        _param = parameter;
        _setting = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:_param.id.c_str()]
                                          defaultValue:_param.type == RoutingParameterType::NUMERIC ? kDefaultNumericValue : kDefaultSymbolicValue];
        _type = EOARouteParamTypeNumeric;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    if (_parameter)
    {
        _isHazmatCategory = [_parameter isKindOfClass:OAHazmatRoutingParameter.class];
        _isGoodsRestrictionsCategory = [_parameter isKindOfClass:OAGoodsDeliveryRoutingParameter.class];
        _isAnyCategorySelected = (_isHazmatCategory || _isGoodsRestrictionsCategory) && [_parameter isSelected];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _type == EOARouteParamTypeNumeric
        ? _parameter != nil ? [_parameter getText] : [NSString stringWithUTF8String:_param.name.c_str()]
        : [_group getText];
}

- (NSString *)getLeftNavbarButtonTitle
{
    return _type != EOARouteParamTypeGroup ? OALocalizedString(@"shared_string_cancel") : nil;
}

- (NSString *)getTableHeaderDescription
{
    return _isGoodsRestrictionsCategory ? OALocalizedString(@"road_speeds_descr") : @"";
}

#pragma mark - Table data

- (BOOL)hideFirstHeader
{
    return _isGoodsRestrictionsCategory;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (_isHazmatCategory && section == 1)
        return OALocalizedString(@"rendering_value_category_name");

    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (_type == EOARouteParamTypeGroup)
        return [_group getRoutingParameters].count;
    else if ((_isHazmatCategory || _isGoodsRestrictionsCategory) && section == 0)
        return 2;

    return _parameter ? _parameter.routingParameter.possibleValues.size() : _param.possibleValues.size();
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSString *text;
    BOOL isSelected = NO;

    if (_type == EOARouteParamTypeNumeric)
    {
        if (_isHazmatCategory || _isGoodsRestrictionsCategory)
        {
            if (indexPath.section == 0)
            {
                isSelected = (indexPath.row == 0 && !_isAnyCategorySelected) || (indexPath.row == 1 && _isAnyCategorySelected);
                text = OALocalizedString(indexPath.row == 0 ? @"shared_string_no" : @"shared_string_yes");
            }
            else
            {
                OAHazmatRoutingParameter *parameter = (OAHazmatRoutingParameter *) _parameter;
                NSString *value = [parameter getValue:indexPath.row];
                isSelected = [[_parameter getValue] isEqualToString:value];
                text = value;
            }
        }
        else
        {
            isSelected = [[NSString stringWithFormat:@"%.1f", _param.possibleValues[indexPath.row]] isEqualToString:[_setting get:self.appMode]];
            text = [NSString stringWithUTF8String:_param.possibleValueDescriptions[indexPath.row].c_str()];
        }
    }
    else if (_type == EOARouteParamTypeGroup)
    {
        OALocalRoutingParameter *routeParam = _group.getRoutingParameters[indexPath.row];
        text = [routeParam getText];
        isSelected = _group.getSelected == _group.getRoutingParameters[indexPath.row];
    }

    OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OARightIconTableViewCell *) nib[0];
        [cell descriptionVisibility:NO];
        [cell leftIconVisibility:NO];
    }
    if (cell)
    {
        cell.titleLabel.text = text;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        if (isSelected)
        {
            _indexSelected = indexPath.row;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            if (_isGoodsRestrictionsCategory && _indexSelected == 1)
            {
                [cell descriptionVisibility:YES];
                cell.descriptionLabel.text = OALocalizedString(@"routing_attr_goods_restrictions_yes_desc");
            }
            else
            {
                [cell descriptionVisibility:NO];
                cell.descriptionLabel.text = nil;
            }
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return _isAnyCategorySelected ? 2 : 1;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    NSString *title = [self getTitleForHeader:section];
    return [OATableViewCustomHeaderView getHeight:title width:self.tableView.bounds.size.width] + kPaddingOnSideOfContent;
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    if (!(_type == EOARouteParamTypeGroup || ((_isHazmatCategory || _isGoodsRestrictionsCategory) && section == 0)))
        return 0.001;

    NSString *footer = @"";
    if (_type == EOARouteParamTypeGroup)
    {
        OALocalRoutingParameter *param = _group.getRoutingParameters[_indexSelected];
        footer = [param getDescription];
    }
    else if (_isHazmatCategory || _isGoodsRestrictionsCategory)
    {
        footer = [_parameter getDescription];
    }

    return [OATableViewCustomFooterView getHeight:footer width:self.tableView.bounds.size.width];
}

- (UIView *)getCustomViewForFooter:(NSInteger)section
{
    if (!(_type == EOARouteParamTypeGroup || ((_isHazmatCategory || _isGoodsRestrictionsCategory) && section == 0)))
        return nil;

    NSString *footer = @"";
    if (_type == EOARouteParamTypeGroup)
    {
        OALocalRoutingParameter *param = _group.getRoutingParameters[_indexSelected];
        footer = [param getDescription];
        if (!footer || footer.length == 0)
            return nil;
    }
    else if (_isHazmatCategory || _isGoodsRestrictionsCategory)
    {
        footer = [_parameter getDescription];
    }

    OATableViewCustomFooterView *vw =
            [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:footer attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    }];
    vw.label.attributedText = textStr;
    return vw;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (_type == EOARouteParamTypeNumeric)
    {
        if ((_isHazmatCategory || _isGoodsRestrictionsCategory) && indexPath.section == 0)
        {
            BOOL isAnyCategorySelected = _isAnyCategorySelected;
            _isAnyCategorySelected = indexPath.row == 1;
            if (isAnyCategorySelected == _isAnyCategorySelected)
                return;
            else
                [_parameter setSelected:_isAnyCategorySelected];
        }
        else
        {
            if (_isHazmatCategory)
                [(OAHazmatRoutingParameter *) _parameter setValue:indexPath.row];
            else
                [_setting set:[NSString stringWithFormat:@"%.1f", _param.possibleValues[indexPath.row]] mode:self.appMode];
        }
    }
    else if (_type == EOARouteParamTypeGroup)
    {
        OALocalRoutingParameter *useElevation = nil;
        if (_group.getRoutingParameters.count > 0
                && ([[NSString stringWithUTF8String:_group.getRoutingParameters.firstObject.routingParameter.id.c_str()] isEqualToString:kRouteParamHeightObstacles]))
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
    if ((_isHazmatCategory && indexPath.section == 0) || (_isGoodsRestrictionsCategory && indexPath.section == 0))
        [self.tableView reloadData];
    else
        [self dismissViewController];
}

@end
