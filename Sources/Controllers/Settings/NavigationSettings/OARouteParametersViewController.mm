//
//  OARouteParametersViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParametersViewController.h"
#import "OADeviceScreenTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAvoidPreferParametersViewController.h"
#import "OARecalculateRouteViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OARouteSettingsBaseViewController.h"
#import "OARouteParameterValuesViewController.h"
#import "OARoutingHelper.h"
#import "OARoadSpeedsViewController.h"
#import "OAAngleStraightLineViewController.h"
#import "OAOsmAndFormatter.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAColors.h"

@interface OARouteParametersViewController () <UITableViewDelegate, UITableViewDataSource, OARoutePreferencesParametersDelegate>

@end

@implementation OARouteParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    NSInteger _iconColor;
    vector<RoutingParameter> _otherParameters;
    vector<RoutingParameter> _avoidParameters;
    vector<RoutingParameter> _preferParameters;
    vector<RoutingParameter> _reliefFactorParameters;
    vector<RoutingParameter> _drivingStyleParameters;
    RoutingParameter _fastRouteParameter;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"route_parameters");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _iconColor = self.appMode.getIconColor;
    [self setupView];
}

- (void)populateGroup:(OALocalRoutingParameterGroup *)group params:(vector<RoutingParameter>&)params
{
    for (const auto& p : params)
    {
        [group addRoutingParameter:p];
    }
}

- (void)addParameterGroupRow:(OALocalRoutingParameterGroup *)group parametersArr:(NSMutableArray *)parametersArr
{
    if (group && group.getText && group.getValue)
    {
        [parametersArr addObject:@{
            @"type" : [OAIconTitleValueCell getCellIdentifier],
            @"title" : [group getText],
            @"icon" : [[group getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
            @"value" : [group getValue],
            @"param" : group,
            @"key" : @"paramGroup"
        }];
    }
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    [otherArr addObject:@{
        @"type" : [OADeviceScreenTableViewCell getCellIdentifier],
        @"foregroundImage" : @"img_settings_sreen_route_parameters@3x.png",
        @"backgroundImage" : @"img_settings_device_bottom_light@3x.png",
    }];

    if ([_settings.routerService get:self.appMode] == EOARouteService::STRAIGHT)
    {
        [parametersArr addObject:
         @{
             @"key" : @"angleStraight",
             @"title" : OALocalizedString(@"recalc_angle_dialog_title"),
             @"icon" : [UIImage templateImageNamed:@"ic_custom_minimal_distance"],
             @"value" : [NSString stringWithFormat:OALocalizedString(@"shared_string_angle_param"), @((int) [_settings.routeStraightAngle get:self.appMode]).stringValue],
             @"type" : [OAIconTitleValueCell getCellIdentifier] }
         ];
    }

    double recalcDist = [_settings.routeRecalculationDistance get:self.appMode];
    recalcDist = recalcDist == 0 ? [OARoutingHelper getDefaultAllowedDeviation:self.appMode posTolerance:[OARoutingHelper getPosTolerance:0]] : recalcDist;
    NSString *descr = recalcDist == -1
            ? OALocalizedString(@"rendering_value_disabled_name")
            : [OAOsmAndFormatter getFormattedDistance:recalcDist forceTrailingZeroes:NO];
    [parametersArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"recalculate_route"),
        @"value" : descr,
        @"icon" : [UIImage templateImageNamed:@"ic_custom_minimal_distance"],
        @"key" : @"recalculateRoute",
    }];
    
    [parametersArr addObject:
     @{
         @"key" : @"reverseDir",
         @"title" : OALocalizedString(@"recalculate_wrong_dir"),
         @"icon" : @"ic_custom_reverse_direction",
         @"value" : @([_settings.disableWrongDirectionRecalc get:self.appMode]),
         @"type" : [OASwitchTableViewCell getCellIdentifier] }
     ];
    
    auto router = [OsmAndApp.instance getRouter:self.appMode];
    [self clearParameters];
    if (router)
    {
        const auto parameters = router->getParameters(string(self.appMode.getDerivedProfile.UTF8String));
        for (auto it = parameters.begin(); it != parameters.end(); ++it)
        {
            const auto &p = it->second;
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *group = [NSString stringWithUTF8String:p.group.c_str()];
            if ([param hasPrefix:@"avoid_"])
                _avoidParameters.push_back(p);
            else if ([param hasPrefix:@"prefer_"])
                _preferParameters.push_back(p);
            else if ([group isEqualToString:kRouteParamGroupReliefSmoothnessFactor])
                _reliefFactorParameters.push_back(p);
            else if ([param isEqualToString:kRouteParamIdHeightObstacles])
                _reliefFactorParameters.insert(_reliefFactorParameters.begin(), p);
            else if ([group isEqualToString:kRouteParamGroupDrivingStyle])
                _drivingStyleParameters.push_back(p);
            else if ([param isEqualToString:kRouteParamShortWay])
                _fastRouteParameter = p;
            else if ("weight" != p.id && "height" != p.id && "length" != p.id && "width" != p.id && "motor_type" != p.id)
                _otherParameters.push_back(p);
        }
    
        if ([[NSString stringWithUTF8String:_fastRouteParameter.id.c_str()] isEqualToString:kRouteParamShortWay])
        {
            OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
            rp.routingParameter = _fastRouteParameter;
            
            NSString *paramId = [NSString stringWithUTF8String:_fastRouteParameter.id.c_str()];
            NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:_fastRouteParameter.name.c_str()]];
            NSString *icon = [self getParameterIcon:paramId isSelected:YES];
            if (![self.appMode isDerivedRoutingFrom:OAApplicationMode.CAR])
            {
                title = OALocalizedString(@"fast_route_mode");
                icon = @"ic_action_play_dark";
            }
            [parametersArr addObject:
                 @{
                    @"name" : paramId,
                    @"title" : title,
                    @"icon" : icon,
                    @"value" : rp,
                    @"type" : [OASwitchTableViewCell getCellIdentifier]
                }
            ];
        }
        
        if (_drivingStyleParameters.size() > 0)
        {
            OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode
                                                                                              groupName:kRouteParamGroupDrivingStyle];
            group.delegate = self;
            [self populateGroup:group params:_drivingStyleParameters];
            [self addParameterGroupRow:group parametersArr:parametersArr];
        }
        if (_avoidParameters.size() > 0)
        {
            [parametersArr addObject:@{
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
                @"title" : OALocalizedString(@"impassable_road"),
                @"icon" : @"ic_custom_alert",
                @"value" : @([self checkIfAnyParameterIsSelected:_avoidParameters]),
                @"key" : @"avoidRoads"
            }];
        }
        if (_reliefFactorParameters.size() > 0)
        {
            OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode
                                                                                              groupName:kRouteParamGroupReliefSmoothnessFactor];
            group.delegate = self;
            [self populateGroup:group params:_reliefFactorParameters];
            [self addParameterGroupRow:group parametersArr:parametersArr];
        }
        NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
        for (NSInteger i = 0; i < _otherParameters.size(); i++)
        {
            const auto& p = _otherParameters[i];
            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                if (!p.group.empty())
                {
                    OALocalRoutingParameterGroup *rpg = [self getLocalRoutingParameterGroup:list groupName:[NSString stringWithUTF8String:p.group.c_str()]];
                    if (!rpg)
                    {
                        rpg = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode groupName:[NSString stringWithUTF8String:p.group.c_str()]];
                        [list addObject:rpg];
                    }
                    rpg.delegate = self;
                    [rpg addRoutingParameter:p];
                }
                else
                {
                    OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
                    rp.routingParameter = p;
                    [list addObject:rp];
                    
                    BOOL isGoodsRestrictions = [paramId isEqualToString:kRouteParamIdGoodsRestrictions];
                    if (isGoodsRestrictions)
                    {
                        NSMutableDictionary *parameterDict = [NSMutableDictionary dictionary];
                        parameterDict[@"ind"] = @(i);
                        parameterDict[@"key"] = @"multiValuePref";
                        OAGoodsDeliveryRoutingParameter *goodsParameter = [[OAGoodsDeliveryRoutingParameter alloc] initWithAppMode:self.appMode];
                        goodsParameter.routingParameter = p;
                        parameterDict[@"param"] = goodsParameter;
                        [parametersArr addObject:parameterDict];
                    }
                    else
                    {
                        [parametersArr addObject:
                             @{
                            @"name" : paramId,
                            @"title" : title,
                            @"icon" : [self getParameterIcon:paramId isSelected:rp.isSelected],
                            @"value" : rp,
                            @"type" : [OASwitchTableViewCell getCellIdentifier] }
                        ];
                    }
                }
            }
            else
            {
                NSMutableDictionary *parameterDict = [NSMutableDictionary dictionary];
                parameterDict[@"ind"] = @(i);
                parameterDict[@"key"] = @"multiValuePref";
                if ([paramId isEqualToString:kRouteParamIdHazmatCategory])
                {
                    OAHazmatRoutingParameter *hazmatCategory = [[OAHazmatRoutingParameter alloc] initWithAppMode:self.appMode];
                    hazmatCategory.routingParameter = p;
                    parameterDict[@"param"] = hazmatCategory;
                }
                else
                {
                    NSString *defaultValue = p.type == RoutingParameterType::NUMERIC ? kDefaultNumericValue : kDefaultSymbolicValue;
                    OACommonString *setting = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()]
                                                                     defaultValue:defaultValue];
                    parameterDict[@"type"] = [OAIconTitleValueCell getCellIdentifier];
                    parameterDict[@"title"] = title;
                    NSString *value = [NSString stringWithUTF8String:p.possibleValueDescriptions[[setting get:self.appMode].intValue].c_str()];
                    parameterDict[@"value"] = value;
                }
                [parametersArr addObject:parameterDict];
            }
        }
        for (OALocalRoutingParameter *p in list)
        {
            if ([p isKindOfClass:OALocalRoutingParameterGroup.class])
            {
                [parametersArr addObject:@{
                    @"type" : [OAIconTitleValueCell getCellIdentifier],
                    @"title" : [p getText],
                    @"icon" : [UIImage templateImageNamed:[self getParameterIcon:[NSString stringWithUTF8String:p.routingParameter.id.c_str()] isSelected:[p isSelected]]],
                    @"value" : [p getValue],
                    @"param" : p,
                    @"key" : @"paramGroup"
                }];
            }
        }
        if (_preferParameters.size() > 0)
        {
            [parametersArr addObject:@{
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
                @"title" : OALocalizedString(@"prefer_in_routing_title"),
                @"icon" : @"ic_custom_alert",
                @"value" : @([self checkIfAnyParameterIsSelected:_preferParameters]),
                @"key" : @"preferRoads"
            }];
        }
        [parametersArr addObject:
        @{
            @"key" : @"temp_limitation",
            @"title" : OALocalizedString(@"consider_limitations_param"),
            @"icon" : @"ic_custom_alert",
            @"value" : @([_settings.enableTimeConditionalRouting get:self.appMode]),
            @"type" : [OASwitchTableViewCell getCellIdentifier] }
        ];
        [parametersArr addObject:@{
            @"type" : [OAIconTextTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"road_speeds"),
            @"icon" : @"ic_custom_alert",
            @"value" : @(YES),
            @"key" : @"roadSpeeds"
        }];
    }
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (OALocalRoutingParameterGroup *) getLocalRoutingParameterGroup:(NSMutableArray<OALocalRoutingParameter *> *)list groupName:(NSString *)groupName
{
    for (OALocalRoutingParameter *p in list)
    {
        if ([p isKindOfClass:[OALocalRoutingParameterGroup class]] && [groupName isEqualToString:[((OALocalRoutingParameterGroup *) p) getGroupName]])
        {
            return (OALocalRoutingParameterGroup *) p;
        }
    }
    return nil;
}

- (BOOL) checkIfAnyParameterIsSelected:(vector <RoutingParameter>)routingParameters
{
    for (const auto& p : routingParameters)
    {
        OALocalRoutingParameter *rp = [[OALocalRoutingParameter alloc] initWithAppMode:self.appMode];
        rp.routingParameter = p;
        if (rp.isSelected)
            return YES;
    }
    return NO;
}

- (NSString *) getParameterIcon:(NSString *)parameterName isSelected:(BOOL)isSelected
{
    if ([parameterName isEqualToString:kRouteParamIdShortWay])
        return @"ic_custom_fuel";
    else if ([parameterName isEqualToString:kRouteParamIdAllowPrivate] || [parameterName isEqualToString:kRouteParamIdAllowPrivateTruck])
        return isSelected ? @"ic_custom_allow_private_access" : @"ic_custom_forbid_private_access";
    else if ([parameterName isEqualToString:kRouteParamIdAllowMotorway])
        return isSelected ? @"ic_custom_motorways" : @"ic_custom_avoid_motorways";
    else if ([parameterName isEqualToString:kRouteParamIdHeightObstacles])
        return @"ic_custom_ascent";
    return @"ic_custom_alert";
}

- (void) clearParameters
{
    _otherParameters.clear();
    _avoidParameters.clear();
    _preferParameters.clear();
    _reliefFactorParameters.clear();
    _drivingStyleParameters.clear();
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OALocalRoutingParameter *param = item[@"param"];
    NSString *cellType = param ? [param getCellType] : item[@"type"];
    if ([cellType isEqualToString:[OADeviceScreenTableViewCell getCellIdentifier]])
    {
        OADeviceScreenTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADeviceScreenTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADeviceScreenTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADeviceScreenTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundImageView.image = [UIImage imageNamed:item[@"backgroundImage"]];
            cell.foregroundImageView.image = [UIImage imageNamed:item[@"foregroundImage"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.hidden = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.leftIconView.image = param && ![item.allKeys containsObject:@"icon"] ? [param getIcon] : item[@"icon"];
            if (param && ![param isSelected] && ![item.allKeys containsObject:@"icon"])
                cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            else
                cell.leftIconView.tintColor = UIColorFromRGB(_iconColor);

            if ([item[@"key"] isEqualToString:@"recalculateRoute"])
                cell.leftIconView.tintColor = [_settings.routeRecalculationDistance get:self.appMode] == -1 ? UIColorFromRGB(color_icon_inactive) : UIColorFromRGB(_iconColor);

            cell.textView.text = param ? [param getText] : item[@"title"];
            cell.descriptionView.text = param
                    ? [param isKindOfClass:OAHazmatRoutingParameter.class]
                            ? OALocalizedString([param isSelected] ? @"shared_string_yes" : @"shared_string_no")
                            : [param getValue]
                    : item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.arrowIconView.hidden = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.iconView.tintColor = [item[@"value"] boolValue] ? UIColorFromRGB(_iconColor) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingToLeftOfContentWithIcon, 0., 0.);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            id v = item[@"value"];

            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OALocalRoutingParameter class]])
            {
                OALocalRoutingParameter *value = v;
                cell.switchView.on = [value isSelected];
                [value setControlAction:cell.switchView];
                value.delegate = self;
            }
            else
            {
                cell.switchView.on = [v boolValue];
                [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
            }
            cell.leftIconView.tintColor = cell.switchView.on ? UIColorFromRGB(_iconColor) : UIColorFromRGB(color_icon_inactive);
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.01 : 19.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OALocalRoutingParameter *parameter = item[@"param"];
    NSString *itemKey = item[@"key"];
    if ([itemKey isEqualToString:@"paramGroup"])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [parameter rowSelectAction:tableView indexPath:indexPath];
        return;
    }

    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"recalculateRoute"])
        settingsViewController = [[OARecalculateRouteViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"avoidRoads"])
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:YES];
    else if ([itemKey isEqualToString:@"multiValuePref"] && parameter)
        settingsViewController = [[OARouteParameterValuesViewController alloc] initWithRoutingParameter:parameter appMode:self.appMode];
    else if ([itemKey isEqualToString:@"multiValuePref"])
        settingsViewController = [[OARouteParameterValuesViewController alloc] initWithParameter:_otherParameters[[item[@"ind"] intValue]] appMode:self.appMode];
    else if ([itemKey isEqualToString:@"preferRoads"])
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:NO];
    else if ([itemKey isEqualToString:@"roadSpeeds"])
        settingsViewController = [[OARoadSpeedsViewController alloc] initWithApplicationMode:self.appMode speedParameters:item];
    else if ([itemKey isEqualToString:@"angleStraight"])
        settingsViewController = [[OAAngleStraightLineViewController alloc] initWithAppMode:self.appMode];

    settingsViewController.delegate = self;
    [self presentViewController:settingsViewController animated:YES completion:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        BOOL isChecked = ((UISwitch *) sender).on;
        if ([item[@"key"] isEqualToString:@"reverseDir"])
        {
            [_settings.disableWrongDirectionRecalc set:isChecked mode:self.appMode];
        }
        else if ([item[@"key"] isEqualToString:@"temp_limitation"])
        {
            [_settings.enableTimeConditionalRouting set:isChecked mode:self.appMode];
        }
        if (self.delegate)
            [self.delegate onSettingsChanged];
        
        [self setSwitchValue:isChecked forIndexPath:indexPath];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) setSwitchValue:(BOOL)isChecked forIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *newData = [NSMutableArray arrayWithArray:_data];
    NSMutableDictionary *newItem= [NSMutableDictionary dictionaryWithDictionary:_data[indexPath.section][indexPath.row]];
    newItem[@"value"] = [NSNumber numberWithBool:isChecked];
    newData[indexPath.section][indexPath.row] = [NSDictionary dictionaryWithDictionary:newItem];;
    _data = [NSArray arrayWithArray:newData];
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged;
{
    if (self.delegate)
        [self.delegate onSettingsChanged];
    
    [self setupView];
    [self.tableView reloadData];
}

#pragma mark - OARoutePreferencesParametersDelegate

- (void)showParameterGroupScreen:(OALocalRoutingParameterGroup *)group
{
    OARouteParameterValuesViewController *settingsViewController = [[OARouteParameterValuesViewController alloc] initWithRoutingParameterGroup:group appMode:self.appMode];
    settingsViewController.delegate = self;
    [self showViewController:settingsViewController];
}

- (void)updateParameters
{
    [self onSettingsChanged];
}

- (void) openNavigationSettings
{
}

- (void) selectVoiceGuidance:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
}

- (void) showAvoidRoadsScreen
{
}

- (void) showTripSettingsScreen
{
}

- (void) showAvoidTransportScreen
{
}

@end
