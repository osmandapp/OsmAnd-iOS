//
//  OARouteParametersViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParametersViewController.h"
#import "OADeviceScreenTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OARouteParametersViewController () <OARoutePreferencesParametersDelegate>

@end

@implementation OARouteParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    NSInteger _iconColor;
    vector<RoutingParameter> _otherRoutingParameters;
    vector<RoutingParameter> _avoidParameters;
    vector<RoutingParameter> _preferParameters;
    vector<RoutingParameter> _reliefFactorParameters;
    vector<RoutingParameter> _drivingStyleParameters;
    vector<RoutingParameter> _hazmatCategoryUSAParameters;
    RoutingParameter _fastRouteParameter;
    BOOL _isDisplyedHazmatCategoryUSAParameters;
}

static NSString *paramKey = @"param";
static NSString *typeKey = @"type";
static NSString *iconKey = @"icon";
static NSString *nameKey = @"name";
static NSString *descriptionKey = @"description";
static NSString *titleKey = @"title";
static NSString *keyKey = @"key";
static NSString *valueKey = @"value";
static NSString *paramGroupKey = @"paramGroup";
static NSString *avoidRoadsKey = @"avoidRoads";
static NSString *preferRoadsKey = @"preferRoads";
static NSString *dangerousGoodsUsaKey = @"dangerous_goods_usa";
static NSString *multiValuePrefKey = @"multiValuePref";
static NSString *tempLimitationKey = @"temp_limitation";
static NSString *recalculateRouteKey = @"recalculateRoute";
static NSString *roadSpeedsKey = @"roadSpeeds";
static NSString *angleStraightKey = @"angleStraight";
static NSString *routingAlgorithmKey = @"routing_algorithm";
static NSString *autoZoomKey = @"auto_zoom";
static NSString *paramsIdsKey = @"paramsIds";
static NSString *paramsNamesKey = @"paramsNames";
static NSString *reverseDirKey = @"reverseDir";
static NSString *enabledKey = @"enabled";
static NSString *backgroundImageKey = @"backgroundImage";
static NSString *foregroundImageKey = @"foregroundImage";

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    _iconColor = [self.appMode getIconColor];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"route_parameters");
}

#pragma mark - Table data

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
            typeKey : [OAValueTableViewCell getCellIdentifier],
            titleKey : [group getText],
            iconKey : [[group getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
            valueKey : [group getValue],
            paramKey : group,
            keyKey : paramGroupKey
        }];
    }
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
    if ([parameterName isEqualToString:kRouteParamShortWay])
        return @"ic_custom_fuel";
    else if ([parameterName isEqualToString:kRouteParamAllowPrivate] || [parameterName isEqualToString:kRouteParamAllowPrivateTruck])
        return isSelected ? @"ic_custom_allow_private_access" : @"ic_custom_forbid_private_access";
    else if ([parameterName isEqualToString:kRouteParamAllowMotorway])
        return isSelected ? @"ic_custom_motorways" : @"ic_custom_avoid_motorways";
    else if ([parameterName isEqualToString:kRouteParamHeightObstacles])
        return @"ic_custom_ascent";
    return @"ic_custom_alert";
}

- (void) clearParameters
{
    _otherRoutingParameters.clear();
    _avoidParameters.clear();
    _preferParameters.clear();
    _reliefFactorParameters.clear();
    _drivingStyleParameters.clear();
    _hazmatCategoryUSAParameters.clear();
}

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSMutableArray *headerImageSection = [NSMutableArray array];
    [tableData addObject:headerImageSection];
    [headerImageSection addObject:@{
        typeKey : [OADeviceScreenTableViewCell getCellIdentifier],
        foregroundImageKey : @"img_settings_sreen_route_parameters@3x.png",
        backgroundImageKey : @"img_settings_device_bottom_light@3x.png",
    }];
    
    NSMutableArray *parametersSection = [NSMutableArray array];
    [tableData addObject:parametersSection];
    
    if ([self.appMode getRouterService] == EOARouteService::OSMAND)
    {
        [self setupOsmAndRouteServicePrefs:parametersSection];
    }
    else if ([self.appMode getRouterService] == EOARouteService::STRAIGHT)
    {
        // TODO: Implement
    }
    
    
    
    NSMutableArray *bottomSection = [NSMutableArray array];
    
    // TODO: Implement bottom sections
    
    if (bottomSection.count > 0)
        [tableData addObject:bottomSection];
    
    _data = [NSArray arrayWithArray:tableData];
    
    
    // TODO: delete old code after test ========================================
    
    
//    NSMutableArray *otherArr = [NSMutableArray array];
//    NSMutableArray *parametersArr = [NSMutableArray array];
//    NSMutableArray *developmentArr = [NSMutableArray array];
//    
//    auto router = [OsmAndApp.instance getRouter:self.appMode];
//    [self clearParameters];
//    
//    if (router)
//    {
//        const auto parameters = router->getParameters(string(self.appMode.getDerivedProfile.UTF8String));
//        auto useShortestWayIterator = parameters.find(std::string(kRouteParamShortWay.UTF8String));
//        
//        if (![self.appMode isDerivedRoutingFrom:OAApplicationMode.CAR] && useShortestWayIterator != parameters.end())
//        {
//            _fastRouteParameter = useShortestWayIterator->second;
//            if ([[NSString stringWithUTF8String:_fastRouteParameter.id.c_str()] isEqualToString:kRouteParamShortWay])
//            {
//                OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
//                rp.routingParameter = _fastRouteParameter;
//                
//                NSString *paramId = [NSString stringWithUTF8String:_fastRouteParameter.id.c_str()];
//                NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:_fastRouteParameter.name.c_str()]];
//                NSString *icon = [self getParameterIcon:paramId isSelected:YES];
//                if (![self.appMode isDerivedRoutingFrom:OAApplicationMode.CAR])
//                {
//                    title = OALocalizedString(@"fast_route_mode");
//                    icon = @"ic_action_play_dark";
//                }
//                [parametersArr addObject:
//                     @{
//                    @"name" : paramId,
//                    @"title" : title,
//                    @"icon" : icon,
//                    @"value" : rp,
//                    @"type" : [OASwitchTableViewCell getCellIdentifier]
//                }
//                ];
//            }
//        }
//        
//        for (auto it = parameters.begin(); it != parameters.end(); ++it)
//        {
//            const auto &routingParameter = it->second;
//            NSString *param = [NSString stringWithUTF8String:routingParameter.id.c_str()];
//            NSString *group = [NSString stringWithUTF8String:routingParameter.group.c_str()];
//            
//            if ([param hasPrefix:kRouteParamAvoidParameterPrefix])
//                _avoidParameters.push_back(routingParameter);
//            else if ([param hasPrefix:kRouteParamPreferParameterPrefix])
//                _preferParameters.push_back(routingParameter);
//            else if ([group isEqualToString:kRouteParamReliefSmoothnessFactor])
//                _reliefFactorParameters.push_back(routingParameter);
//            else if ([group isEqualToString:kRouteParamGroupDrivingStyle])
//                _drivingStyleParameters.push_back(routingParameter);
//            else if ([param hasPrefix:kRouteParamHazmatCategoryUsaPrefix])
//                _hazmatCategoryUSAParameters.push_back(routingParameter);
//            else if ((![param isEqualToString:kRouteParamShortWay] || [appMode isDerivedRoutingFrom:OAApplicationMode.CAR]) &&
//                     ![param isEqualToString:kRouteParamVehicleHeight] &&
//                     ![param isEqualToString:kRouteParamVehicleWeight] &&
//                     ![param isEqualToString:kRouteParamVehicleWidth] &&
//                     ![param isEqualToString:kRouteParamVehicleMotorType] &&
//                     ![param isEqualToString:kRouteParamVehicleMaxAxleLoad] &&
//                     ![param isEqualToString:kRouteParamVehicleWeightRating] &&
//                     ![param isEqualToString:kRouteParamVehicleLength])
//                _otherRoutingParameters.push_back(routingParameter);
//            
//            
////            else if ([param isEqualToString:kRouteParamHeightObstacles])
////                _reliefFactorParameters.insert(_reliefFactorParameters.begin(), routingParameter);
////            else if ([param isEqualToString:kRouteParamShortWay])
////                _fastRouteParameter = routingParameter;
////            else if ("weight" != routingParameter.id && "height" != routingParameter.id && "length" != routingParameter.id && "width" != routingParameter.id && kRouteParamMotorType.UTF8String != routingParameter.id)
////                _otherParameters.push_back(routingParameter);
//        }
//        
//        if (_drivingStyleParameters.size() > 0)
//        {
//            OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode
//                                                                                              groupName:kRouteParamGroupDrivingStyle];
//            group.delegate = self;
//            [self populateGroup:group params:_drivingStyleParameters];
//            [self addParameterGroupRow:group parametersArr:parametersArr];
//        }
//        if (_avoidParameters.size() > 0)
//        {
//            NSString *title;
//            NSString *description
//            if ([appMode isDerivedRoutingFrom:OAApplicationMode.CAR])
//            {
//                title = OALocalizedString(@"avoid_pt_types");
//                description = OALocalizedString(@"avoid_pt_types_descr");
//            }
//            else
//            {
//                title = OALocalizedString(@"impassable_road");
//                description = OALocalizedString(@"avoid_in_routing_descr_");
//            }
//            [parametersArr addObject:@{
//                @"type" : [OASimpleTableViewCell getCellIdentifier],
//                @"title" : title,
//                @"description" : description,
//                @"icon" : @"ic_custom_alert",
//                @"value" : @([self checkIfAnyParameterIsSelected:_avoidParameters]),
//                @"key" : @"avoidRoads"
//            }];
//        }
//        
//        if (_preferParameters.size() > 0)
//        {
//            [parametersArr addObject:@{
//                @"type" : [OASimpleTableViewCell getCellIdentifier],
//                @"title" : OALocalizedString(@"prefer_in_routing_title"),
//                @"icon" : @"ic_custom_alert",
//                @"value" : @([self checkIfAnyParameterIsSelected:_preferParameters]),
//                @"key" : @"preferRoads"
//            }];
//        }
//        
//        if (_hazmatCategoryUSAParameters.size() > 0)
//        {
//            [self setupHazmatUSACategoryPreference];
//        }
//        
//        NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
//        for (NSInteger i = 0; i < _otherRoutingParameters.size(); i++)
//        {
//            const auto& p = _otherRoutingParameters[i];
//            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
//            NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
//            
//            if ([paramId isEqualToString:kRouteParamAllowViaFerrata])
//            {
//                [self setupViaFerrataPreference];
//            }
//            else if ([paramId isEqualToString:kRouteParamHazmatCategory])
//            {
//                [self setupHazmatCategoryPreference];
//            }
//            else if ([paramId isEqualToString:kRouteParamGoodsRestrictions])
//            {
//                [self setupGoodsRestrictionsPreference];
//            }
//            else
//            {
//                [self setupOtherBooleanParameterSummary];
//            }
//            
//            
////            if (p.type == RoutingParameterType::BOOLEAN)
////            {
////                if (!p.group.empty())
////                {
////                    OALocalRoutingParameterGroup *rpg = [self getLocalRoutingParameterGroup:list groupName:[NSString stringWithUTF8String:p.group.c_str()]];
////                    if (!rpg)
////                    {
////                        rpg = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode groupName:[NSString stringWithUTF8String:p.group.c_str()]];
////                        [list addObject:rpg];
////                    }
////                    rpg.delegate = self;
////                    [rpg addRoutingParameter:p];
////                }
////                else
////                {
////                    OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
////                    rp.routingParameter = p;
////                    [list addObject:rp];
////                    
////                    BOOL isGoodsRestrictions = [paramId isEqualToString:kRouteParamGoodsRestrictions];
////                    if (isGoodsRestrictions)
////                    {
////                        NSMutableDictionary *parameterDict = [NSMutableDictionary dictionary];
////                        parameterDict[@"ind"] = @(i);
////                        parameterDict[@"key"] = @"multiValuePref";
////                        OAGoodsDeliveryRoutingParameter *goodsParameter = [[OAGoodsDeliveryRoutingParameter alloc] initWithAppMode:self.appMode];
////                        goodsParameter.routingParameter = p;
////                        parameterDict[@"param"] = goodsParameter;
////                        [parametersArr addObject:parameterDict];
////                    }
////                    else
////                    {
////                        [parametersArr addObject:
////                             @{
////                            @"name" : paramId,
////                            @"title" : title,
////                            @"icon" : [self getParameterIcon:paramId isSelected:rp.isSelected],
////                            @"value" : rp,
////                            @"type" : [OASwitchTableViewCell getCellIdentifier] }
////                        ];
////                    }
////                }
////            }
////            else
////            {
////                NSMutableDictionary *parameterDict = [NSMutableDictionary dictionary];
////                parameterDict[@"ind"] = @(i);
////                parameterDict[@"key"] = @"multiValuePref";
////                if ([paramId isEqualToString:kRouteParamHazmatCategory])
////                {
////                    OAHazmatRoutingParameter *hazmatCategory = [[OAHazmatRoutingParameter alloc] initWithAppMode:self.appMode];
////                    hazmatCategory.routingParameter = p;
////                    parameterDict[@"param"] = hazmatCategory;
////                }
////                else
////                {
////                    NSString *defaultValue = p.type == RoutingParameterType::NUMERIC ? kDefaultNumericValue : kDefaultSymbolicValue;
////                    OACommonString *setting = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()]
////                                                                     defaultValue:defaultValue];
////                    parameterDict[@"type"] = [OAValueTableViewCell getCellIdentifier];
////                    parameterDict[@"title"] = title;
////                    NSString *value = [NSString stringWithUTF8String:p.possibleValueDescriptions[[setting get:self.appMode].intValue].c_str()];
////                    parameterDict[@"value"] = value;
////                }
////                [parametersArr addObject:parameterDict];
////            }
//        }
//        
////        for (OALocalRoutingParameter *p in list)
////        {
////            if ([p isKindOfClass:OALocalRoutingParameterGroup.class])
////            {
////                [parametersArr addObject:@{
////                    @"type" : [OAValueTableViewCell getCellIdentifier],
////                    @"title" : [p getText],
////                    @"icon" : [UIImage templateImageNamed:[self getParameterIcon:[NSString stringWithUTF8String:p.routingParameter.id.c_str()] isSelected:[p isSelected]]],
////                    @"value" : [p getValue],
////                    @"param" : p,
////                    @"key" : @"paramGroup"
////                }];
////            }
////        }
////        
////        
////        if (_reliefFactorParameters.size() > 0)
////        {
////            OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode
////                                                                                              groupName:kRouteParamReliefSmoothnessFactor];
////            group.delegate = self;
////            [self populateGroup:group params:_reliefFactorParameters];
////            [self addParameterGroupRow:group parametersArr:parametersArr];
////        }
//        
//        
//        
////        [parametersArr addObject:
////        @{
////            @"key" : @"temp_limitation",
////            @"title" : OALocalizedString(@"temporary_conditional_routing"),
////            @"icon" : @"ic_custom_alert",
////            @"value" : @([_settings.enableTimeConditionalRouting get:self.appMode]),
////            @"type" : [OASwitchTableViewCell getCellIdentifier] }
////        ];
////        [parametersArr addObject:@{
////            @"type" : [OASimpleTableViewCell getCellIdentifier],
////            @"title" : OALocalizedString(@"road_speeds"),
////            @"icon" : @"ic_custom_alert",
////            @"value" : @(YES),
////            @"key" : @"roadSpeeds"
////        }];
//    }
    
    
    
    
    
    
    
////    [otherArr addObject:@{
////        @"type" : [OADeviceScreenTableViewCell getCellIdentifier],
////        @"foregroundImage" : @"img_settings_sreen_route_parameters@3x.png",
////        @"backgroundImage" : @"img_settings_device_bottom_light@3x.png",
////    }];
////
////    if ([_settings.routerService get:self.appMode] == EOARouteService::STRAIGHT)
////    {
////        [parametersArr addObject:
////         @{
////             @"key" : @"angleStraight",
////             @"title" : OALocalizedString(@"recalc_angle_dialog_title"),
////             @"icon" : [UIImage templateImageNamed:@"ic_custom_minimal_distance"],
////             @"value" : [NSString stringWithFormat:OALocalizedString(@"shared_string_angle_param"), @((int) [_settings.routeStraightAngle get:self.appMode]).stringValue],
////             @"type" : [OAValueTableViewCell getCellIdentifier] }
////         ];
////    }
////
////    double recalcDist = [_settings.routeRecalculationDistance get:self.appMode];
////    recalcDist = recalcDist == 0 ? [OARoutingHelper getDefaultAllowedDeviation:self.appMode posTolerance:[OARoutingHelper getPosTolerance:0]] : recalcDist;
////    NSString *descr = recalcDist == -1
////            ? OALocalizedString(@"rendering_value_disabled_name")
////            : [OAOsmAndFormatter getFormattedDistance:recalcDist forceTrailingZeroes:NO];
////    [parametersArr addObject:@{
////        @"type" : [OAValueTableViewCell getCellIdentifier],
////        @"title" : OALocalizedString(@"recalculate_route"),
////        @"value" : descr,
////        @"icon" : [UIImage templateImageNamed:@"ic_custom_minimal_distance"],
////        @"key" : @"recalculateRoute",
////    }];
////    
////    [parametersArr addObject:
////     @{
////         @"key" : @"reverseDir",
////         @"title" : OALocalizedString(@"recalculate_wrong_dir"),
////         @"icon" : @"ic_custom_reverse_direction",
////         @"value" : @(![_settings.disableWrongDirectionRecalc get:self.appMode]),
////         @"type" : [OASwitchTableViewCell getCellIdentifier] }
////     ];
////    
////    
////    
////    if ([OAPluginsHelper getPlugin:OAOsmandDevelopmentPlugin.class].isEnabled)
////    {
////        [developmentArr addObject:
////         @{
////            @"key" : @"routing_algorithm",
////            @"title" : OALocalizedString(@"routing_algorithm"),
////            @"icon" : [UIImage templateImageNamed:@"ic_custom_route_points"],
////            @"value" : OALocalizedString([_settings.useOldRouting get] ? @"routing_algorithm_a" : @"routing_algorithm_highway_hierarchies"),
////            @"type" : [OAValueTableViewCell getCellIdentifier]
////        }];
////        [developmentArr addObject:
////         @{
////            @"key" : @"auto_zoom",
////            @"title" : OALocalizedString(@"auto_zoom"),
////            @"icon" : [UIImage templateImageNamed:@"ic_custom_zoom_level"],
////            @"value" : OALocalizedString([_settings.useV1AutoZoom get] ? @"auto_zoom_discrete" : @"auto_zoom_smooth"),
////            @"type" : [OAValueTableViewCell getCellIdentifier]
////        }];
////    }
////    [tableData addObject:otherArr];
//    [tableData addObject:parametersArr];
////    [tableData addObject:developmentArr];
//    _data = [NSArray arrayWithArray:tableData];
}

- (void) setupOsmAndRouteServicePrefs:(NSMutableArray *)tableSection
{
    auto router = [OsmAndApp.instance getRouter:self.appMode];
    [self clearParameters];
    _isDisplyedHazmatCategoryUSAParameters = NO;
    
    if (router)
    {
        const auto parameters = router->getParameters(string(self.appMode.getDerivedProfile.UTF8String));
        auto useShortestWayIterator = parameters.find(std::string(kRouteParamShortWay.UTF8String));
        
        if (![self.appMode isDerivedRoutingFrom:OAApplicationMode.CAR] && useShortestWayIterator != parameters.end())
        {
            _fastRouteParameter = useShortestWayIterator->second;
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
                [tableSection addObject: @{
                    typeKey : [OASwitchTableViewCell getCellIdentifier],
                    nameKey : paramId,
                    iconKey : icon,
                    titleKey : title,
                    valueKey : rp
                }];
            }
        }
        
        for (auto it = parameters.begin(); it != parameters.end(); ++it)
        {
            const auto &routingParameter = it->second;
            NSString *param = [NSString stringWithUTF8String:routingParameter.id.c_str()];
            NSString *group = [NSString stringWithUTF8String:routingParameter.group.c_str()];

            if ([param hasPrefix:kRouteParamAvoidParameterPrefix])
                _avoidParameters.push_back(routingParameter);
            else if ([param hasPrefix:kRouteParamPreferParameterPrefix])
                _preferParameters.push_back(routingParameter);
            else if ([group isEqualToString:kRouteParamReliefSmoothnessFactor])
                _reliefFactorParameters.push_back(routingParameter);
            else if ([group isEqualToString:kRouteParamGroupDrivingStyle])
                _drivingStyleParameters.push_back(routingParameter);
            else if ([param hasPrefix:kRouteParamHazmatCategoryUsaPrefix])
                _hazmatCategoryUSAParameters.push_back(routingParameter);
            else if ((![param isEqualToString:kRouteParamShortWay] || [self.appMode isDerivedRoutingFrom:OAApplicationMode.CAR]) &&
                     ![param isEqualToString:kRouteParamVehicleHeight] &&
                     ![param isEqualToString:kRouteParamVehicleWeight] &&
                     ![param isEqualToString:kRouteParamVehicleWidth] &&
                     ![param isEqualToString:kRouteParamVehicleMotorType] &&
                     ![param isEqualToString:kRouteParamVehicleMaxAxleLoad] &&
                     ![param isEqualToString:kRouteParamVehicleWeightRating] &&
                     ![param isEqualToString:kRouteParamVehicleLength])
            {
                _otherRoutingParameters.push_back(routingParameter);
            }
        }
        
        if (_drivingStyleParameters.size() > 0)
        {
            OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode groupName:kRouteParamGroupDrivingStyle];
            group.delegate = self;
            [self populateGroup:group params:_drivingStyleParameters];
            [self addParameterGroupRow:group parametersArr:tableSection];
        }
        
        if (_avoidParameters.size() > 0)
        {
            NSString *title;
            NSString *description;
            if ([self.appMode isDerivedRoutingFrom:OAApplicationMode.PUBLIC_TRANSPORT])
            {
                title = OALocalizedString(@"avoid_pt_types");
                description = OALocalizedString(@"avoid_pt_types_descr");
            }
            else
            {
                title = OALocalizedString(@"impassable_road");
                description = OALocalizedString(@"avoid_in_routing_descr_");
            }
            [tableSection addObject:@{
                typeKey : [OASimpleTableViewCell getCellIdentifier],
                titleKey : title,
                descriptionKey : description,
                iconKey : @"ic_custom_alert",
                valueKey : @([self checkIfAnyParameterIsSelected:_avoidParameters]),
                keyKey : avoidRoadsKey
            }];
        }
        
        if (_preferParameters.size() > 0)
        {
            [tableSection addObject:@{
                typeKey : [OASimpleTableViewCell getCellIdentifier],
                titleKey : OALocalizedString(@"prefer_in_routing_title"),
                iconKey : @"ic_custom_alert",
                valueKey : @([self checkIfAnyParameterIsSelected:_preferParameters]),
                keyKey : preferRoadsKey
            }];
        }
        
        if (_hazmatCategoryUSAParameters.size() > 0)
            [self setupHazmatUSACategoryPreference:tableSection];
        
        NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
        for (NSInteger i = 0; i < _otherRoutingParameters.size(); i++)
        {
            const auto& p = _otherRoutingParameters[i];
            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
            
            if ([paramId isEqualToString:kRouteParamAllowViaFerrata])
                [self setupViaFerrataPreference:tableSection param:p];
            else if ([paramId isEqualToString:kRouteParamHazmatCategory])
                [self setupHazmatCategoryPreference:tableSection param:p];
            else if ([paramId isEqualToString:kRouteParamGoodsRestrictions])
                [self setupGoodsRestrictionsPreference:tableSection param:p];
            else
                [self setupOtherBooleanParameterSummary:tableSection param:p];
        }
    }
    [self setupTimeConditionalRoutingPref:tableSection];
}

- (void) setupHazmatUSACategoryPreference:(NSMutableArray *)tableSection
{
    if ([_settings.drivingRegion get:self.appMode] == DR_US)
    {
        NSArray<NSArray<NSString *> *> *fetchedParams = [self getHazmatUsaParamsIds];
        NSMutableArray<NSString *> *paramsIds = fetchedParams[0];
        NSMutableArray<NSString *> *paramsNames = fetchedParams[1];
        NSMutableArray<NSString *> *enabledParamsIds = fetchedParams[2];
        [tableSection addObject:
         @{
            typeKey : [OAValueTableViewCell getCellIdentifier],
            keyKey : dangerousGoodsUsaKey,
            iconKey : [self getHazmatUsaIcon:enabledParamsIds],
            titleKey : OALocalizedString(@"dangerous_goods"),
            valueKey : [self getHazmatUsaDescription:enabledParamsIds],
            paramsIdsKey : paramsIds,
            paramsNamesKey : paramsNames
        }];
        _isDisplyedHazmatCategoryUSAParameters = YES;
    }
}

- (NSArray<NSArray<NSString *> *> *) getHazmatUsaParamsIds
{
    NSMutableArray<NSArray<NSString *> *> *params = [NSMutableArray array];
    NSMutableArray<NSString *> *paramsIds = [NSMutableArray array];
    NSMutableArray<NSString *> *paramsNames = [NSMutableArray array];
    NSMutableArray<NSString *> *enabledParamsIds = [NSMutableArray array];
    
    for (NSInteger i = 0; i < _hazmatCategoryUSAParameters.size(); i++)
    {
        RoutingParameter& parameter = _hazmatCategoryUSAParameters[i];
        NSString *paramId = [NSString stringWithUTF8String:parameter.id.c_str()];
        NSString *name = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:parameter.name.c_str()]];
        OACommonBoolean *pref = [_settings getCustomRoutingBooleanProperty:paramId defaultValue:parameter.defaultBoolean];
        NSString *enabled = [pref get:self.appMode] ? enabledKey : @"";
        [params addObject:@[paramId, name, enabled]];
    }
    
    [params sortUsingComparator:^NSComparisonResult(NSArray<NSString *> * _Nonnull obj1, NSArray<NSString *> *  _Nonnull obj2) {
        return [obj1[0] compare:obj2[0]];
    }];
    
    for (NSArray<NSString *> *param in params)
    {
        [paramsIds addObject:param[0]];
        [paramsNames addObject:param[1]];
        if ([param[2] isEqualToString:enabledKey])
            [enabledParamsIds addObject:param[0]];
    }
    return @[paramsIds, paramsNames, enabledParamsIds];
}

- (UIImage *) getHazmatUsaIcon:(NSArray<NSString *> *)paramsIds
{
    BOOL enabled = paramsIds.count > 0;
    return enabled ? [UIImage imageNamed:@"ic_custom_hazmat_limit_colored"] : [UIImage templateImageNamed:@"ic_custom_hazmat_limit"];
}

- (NSString *) getHazmatUsaDescription:(NSArray<NSString *> *)paramsIds
{
    if (paramsIds.count == 0)
        return OALocalizedString(@"shared_string_no");
    
    NSString *result = @"";
    for (int i = 0; i < paramsIds.count; i++)
    {
        NSString *paramsId = paramsIds[i];
        int hazmatClass = [self getHazmatUsaClass:paramsId];
        if (i > 0)
            result = [result stringByAppendingString:@", "];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%d", hazmatClass]];
    }
    result = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), OALocalizedString(@"shared_string_class"), result];
    return result;
}

- (int) getHazmatUsaClass:(NSString *)paramsId
{
    return [[paramsId stringByReplacingOccurrencesOfString:kRouteParamHazmatCategoryUsaPrefix withString:@""] intValue];
}

- (void) setupHazmatCategoryPreference:(NSMutableArray *)tableSection param:(RoutingParameter)param
{
    if (!_isDisplyedHazmatCategoryUSAParameters)
    {
        OAHazmatRoutingParameter *hazmatCategory = [[OAHazmatRoutingParameter alloc] initWithAppMode:self.appMode];
        hazmatCategory.routingParameter = param;
        
        NSString *description = OALocalizedString(@"shared_string_no");
        if ([hazmatCategory isSelected])
            description = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_comma"), OALocalizedString(@"shared_string_yes"), [hazmatCategory getValue]];
        
        [tableSection addObject:
         @{
            typeKey : [OAValueTableViewCell getCellIdentifier],
            keyKey : multiValuePrefKey,
            titleKey : OALocalizedString(@"transport_hazmat_title"),
            valueKey : description,
            paramKey : hazmatCategory
        }];
    }
}

- (void) setupViaFerrataPreference:(NSMutableArray *)tableSection param:(RoutingParameter)param
{
    NSString *paramId = [NSString stringWithUTF8String:param.id.c_str()];
    OACommonBoolean *pref = [_settings getCustomRoutingBooleanProperty:paramId defaultValue:param.defaultBoolean];
    OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
    rp.routingParameter = param;
    [tableSection addObject: @{
        typeKey : [OASwitchTableViewCell getCellIdentifier],
        nameKey : paramId,
        iconKey : @"ic_action_hill_climbing",
        titleKey : OALocalizedString(@"routing_attr_allow_via_ferrata_name"),
        valueKey : rp
    }];
}

- (void) setupGoodsRestrictionsPreference:(NSMutableArray *)tableSection param:(RoutingParameter)param
{
    NSString *paramId = [NSString stringWithUTF8String:param.id.c_str()];
    OACommonBoolean *pref = [_settings getCustomRoutingBooleanProperty:paramId defaultValue:param.defaultBoolean];
    OAGoodsDeliveryRoutingParameter *goodsParameter = [[OAGoodsDeliveryRoutingParameter alloc] initWithAppMode:self.appMode];
    goodsParameter.routingParameter = param;
    OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
    rp.routingParameter = param;
    [tableSection addObject: @{
        typeKey : [OASwitchTableViewCell getCellIdentifier],
        nameKey : paramId,
        iconKey : @"ic_custom_van",
        titleKey : OALocalizedString(@"routing_attr_goods_restrictions_name"),
        valueKey : goodsParameter
    }];
}

- (void) setupOtherBooleanParameterSummary:(NSMutableArray *)tableSection param:(RoutingParameter)param
{
    if (param.type == RoutingParameterType::BOOLEAN)
    {
        NSString *paramId = [NSString stringWithUTF8String:param.id.c_str()];
        OACommonBoolean *pref = [_settings getCustomRoutingBooleanProperty:paramId defaultValue:param.defaultBoolean];
        if ([paramId isEqualToString:kRouteParamHeightObstacles] && _reliefFactorParameters.size() > 0)
        {
            _reliefFactorParameters.insert(_reliefFactorParameters.begin(), param);
            
            OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:self.appMode groupName:kRouteParamReliefSmoothnessFactor];
            group.delegate = self;
            [self populateGroup:group params:_reliefFactorParameters];
            [self addParameterGroupRow:group parametersArr:tableSection];
        }
        else
        {
            NSString *paramId = [NSString stringWithUTF8String:param.id.c_str()];
            OACommonBoolean *pref = [_settings getCustomRoutingBooleanProperty:paramId defaultValue:param.defaultBoolean];
            OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:self.appMode];
            rp.routingParameter = param;
            
            NSString *iconName = [rp getIconName];
            if (!iconName)
                iconName = @"ic_custom_alert";
            
            [tableSection addObject: @{
                typeKey : [OASwitchTableViewCell getCellIdentifier],
                nameKey : paramId,
                iconKey : iconName,
                titleKey : [rp getText],
                valueKey : rp
            }];
        }
    }
}

- (void) setupTimeConditionalRoutingPref:(NSMutableArray *)tableSection
{
    [tableSection addObject:
    @{
        typeKey : [OASwitchTableViewCell getCellIdentifier],
        keyKey : tempLimitationKey,
        titleKey : OALocalizedString(@"temporary_conditional_routing"),
        iconKey : @"ic_custom_road_works",
        valueKey : @([_settings.enableTimeConditionalRouting get:self.appMode])
    }];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OALocalRoutingParameter *param = item[paramKey];
    NSString *cellType = param ? [param getCellType] : item[typeKey];
    if ([cellType isEqualToString:[OADeviceScreenTableViewCell getCellIdentifier]])
    {
        OADeviceScreenTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OADeviceScreenTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADeviceScreenTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADeviceScreenTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundImageView.image = [UIImage imageNamed:item[backgroundImageKey]].imageFlippedForRightToLeftLayoutDirection;
            cell.foregroundImageView.image = [UIImage imageNamed:item[foregroundImageKey]].imageFlippedForRightToLeftLayoutDirection;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.leftIconView.image = param && ![item.allKeys containsObject:iconKey] ? [param getIcon].imageFlippedForRightToLeftLayoutDirection : [item[iconKey] imageFlippedForRightToLeftLayoutDirection];
            if (param && ![param isSelected] && ![item.allKeys containsObject:iconKey])
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDisabled];
            else
                cell.leftIconView.tintColor = UIColorFromRGB(_iconColor);

            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDisabled];
            if ([item[keyKey] isEqualToString:recalculateRouteKey])
                cell.leftIconView.tintColor = [_settings.routeRecalculationDistance get:self.appMode] == -1 ? [UIColor colorNamed:ACColorNameIconColorDisabled] : UIColorFromRGB(_iconColor);
            
            cell.titleLabel.text = param ? [param getText] : item[titleKey];

            cell.valueLabel.text = param ? [param getValue] : item[valueKey];
            if ([param isKindOfClass:OAHazmatRoutingParameter.class])
                cell.valueLabel.text = item[valueKey];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[titleKey];
            cell.leftIconView.image = [UIImage templateImageNamed:item[iconKey]];
            cell.leftIconView.tintColor = [item[valueKey] boolValue] ? UIColorFromRGB(_iconColor) : [UIColor colorNamed:ACColorNameIconColorDisabled];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingToLeftOfContentWithIcon, 0., 0.);
        }
        if (cell)
        {
            cell.titleLabel.text = item[titleKey];
            cell.leftIconView.image = [UIImage templateImageNamed:item[iconKey]];
            id v = item[valueKey];

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
            cell.leftIconView.tintColor = cell.switchView.on ? UIColorFromRGB(_iconColor) : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == 2 && [OAPluginsHelper getPlugin:OAOsmandDevelopmentPlugin.class].isEnabled)
        return OALocalizedString(@"shared_string_development");
    
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OALocalRoutingParameter *parameter = item[paramKey];
    NSString *itemKey = item[keyKey];
    if ([itemKey isEqualToString:paramGroupKey])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [parameter rowSelectAction:self.tableView indexPath:indexPath];
        return;
    }

    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:recalculateRouteKey])
        settingsViewController = [[OARecalculateRouteViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:avoidRoadsKey])
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:YES];
    else if ([itemKey isEqualToString:multiValuePrefKey] && parameter)
        settingsViewController = [[OARouteParameterValuesViewController alloc] initWithRoutingParameter:parameter appMode:self.appMode];
    else if ([itemKey isEqualToString:multiValuePrefKey])
        settingsViewController = [[OARouteParameterValuesViewController alloc] initWithParameter:_otherRoutingParameters[[item[@"ind"] intValue]] appMode:self.appMode];
    else if ([itemKey isEqualToString:preferRoadsKey])
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:NO];
    else if ([itemKey isEqualToString:roadSpeedsKey])
        settingsViewController = [[OARoadSpeedsViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:angleStraightKey])
        settingsViewController = [[OAAngleStraightLineViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:routingAlgorithmKey])
        settingsViewController = [[OARouteParameterDevelopmentViewController alloc] initWithApplicationMode:self.appMode parameterType:ParameterTypeRoutingAlgorithm];
    else if ([itemKey isEqualToString:autoZoomKey])
        settingsViewController = [[OARouteParameterDevelopmentViewController alloc] initWithApplicationMode:self.appMode parameterType:ParameterTypeAutoZoom];
    else if ([itemKey isEqualToString:dangerousGoodsUsaKey])
        settingsViewController = [[OARouteParameterHazmatUsa alloc] initWithApplicationMode:self.appMode parameterIds:item[paramsIdsKey] parameterNames:item[paramsNamesKey]];
    
    if (settingsViewController)
    {
        settingsViewController.delegate = self;
        if ([itemKey isEqualToString:routingAlgorithmKey] || [itemKey isEqualToString:autoZoomKey])
            [self showMediumSheetViewController:settingsViewController isLargeAvailable:NO];
        else
            [self showModalViewController:settingsViewController];
    }
}

#pragma mark - Selectors

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        BOOL isChecked = ((UISwitch *) sender).on;
        if ([item[keyKey] isEqualToString:reverseDirKey])
        {
            [_settings.disableWrongDirectionRecalc set:!isChecked mode:self.appMode];
        }
        else if ([item[keyKey] isEqualToString:tempLimitationKey])
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
    newItem[valueKey] = [NSNumber numberWithBool:isChecked];
    newData[indexPath.section][indexPath.row] = [NSDictionary dictionaryWithDictionary:newItem];;
    _data = [NSArray arrayWithArray:newData];
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged;
{
    if (self.delegate)
        [self.delegate onSettingsChanged];
    
    [self generateData];
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
