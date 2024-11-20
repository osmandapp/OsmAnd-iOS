//
//  OARoutePreferencesParameters.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

static const int calculate_osmand_route_without_internet_id = 100;
static const int fast_route_mode_id = 101;
static const int use_points_as_intermediates_id = 102;
static const int gpx_option_reverse_route_id = 103;
static const int gpx_option_from_start_point_id = 104;
static const int gpx_option_calculate_first_last_segment_id = 105;
static const int calculate_osmand_route_gpx_id = 106;
static const int speak_favorites_id = 107;
static const int connect_route_points_id = 108;

static NSString *kRouteParamGroupDrivingStyle = @"driving_style";
static NSString *kRouteParamIdReliefSmoothnessFactorPlain = @"relief_smoothness_factor_plains";
static NSString *kRouteParamIdReliefSmoothnessFactorMorePlain = @"relief_smoothness_factor_more_plains";
static NSString *kRouteParamIdReliefSmoothnessFactorHills = @"relief_smoothness_factor_hills";

static NSString *kRouteParamShortWay = @"short_way";
static NSString *kRouteParamHeightObstacles = @"height_obstacles";
static NSString *kRouteParamReliefSmoothnessFactor = @"relief_smoothness_factor";
static NSString *kRouteParamAvoidFerries = @"avoid_ferries";
static NSString *kRouteParamAvoidToll = @"avoid_toll";
static NSString *kRouteParamAvoidMotorway = @"avoid_motorway";
static NSString *kRouteParamAllowUnpaved = @"avoid_unpaved";
static NSString *kRouteParamPreferMotorway = @"prefer_motorway";
static NSString *kRouteParamAllowPrivate = @"allow_private";
static NSString *kRouteParamAllowPrivateTruck = @"allow_private_for_truck";
static NSString *kRouteParamHazmatCategory = @"hazmat_category";
static NSString *kRouteParamGoodsRestrictions = @"goods_restrictions";
static NSString *kRouteParamAllowMotorway = @"allow_motorway";
static NSString *kRouteParamAllowViaFerrata = @"allow_via_ferrata";

static NSString *kRouteParamAvoidParameterPrefix = @"avoid_";
static NSString *kRouteParamPreferParameterPrefix = @"prefer_";
static NSString *kRouteParamMotorType = @"motor_type";
static NSString *kRouteParamHazmatCategoryUsaPrefix = @"hazmat_category_usa_";

static NSString *kRouteParamVehicleHeight = @"height";
static NSString *kRouteParamVehicleWeight = @"weight";
static NSString *kRouteParamVehicleWidth = @"width";
static NSString *kRouteParamVehicleLength = @"length";
static NSString *kRouteParamVehicleMotorType = @"motor_type";
static NSString *kRouteParamVehicleMaxAxleLoad = @"maxaxleload";
static NSString *kRouteParamVehicleWeightRating = @"weightrating";

static NSString *kDefaultNumericValue = @"0.0";
static NSString *kDefaultSymbolicValue = @"-";

static NSString *cellTypeRouteSettingsKey = @"cellTypeRouteSettingsKey";
static NSString *keyRouteSettingsKey = @"keyRouteSettingsKey";
static NSString *titleRouteSettingsKey = @"titleRouteSettingsKey";
static NSString *valueRouteSettingsKey = @"valueRouteSettingsKey";
static NSString *iconRouteSettingsKey = @"iconRouteSettingsKey";
static NSString *iconTintRouteSettingsKey = @"iconTintRouteSettingsKey";
static NSString *paramsIdsRouteSettingsKey = @"paramsIdsRouteSettingsKey";
static NSString *paramsNamesRouteSettingsKey = @"paramsNamesRouteSettingsKey";
static NSString *dangerousGoodsRouteSettingsUsaKey = @"dangerousGoodsRouteSettingsUsaKey";

@class OAApplicationMode, OARoutingHelper, OAAppSettings;
@class OALocalRoutingParameterGroup, OALocalRoutingParameter;

struct RoutingParameter;

@protocol OARoutePreferencesParametersDelegate <NSObject>

@required
- (void) updateParameters;
- (void) openNavigationSettings;
- (void) openRouteLineAppearance;
- (void) showParameterGroupScreen:(OALocalRoutingParameterGroup *)group;
- (void) showParameterValuesScreen:(OALocalRoutingParameter *)parameter;
- (void) selectVoiceGuidance:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
- (void) showAvoidRoadsScreen;
- (void) showTripSettingsScreen;
- (void) showAvoidTransportScreen;
- (void) openSimulateNavigationScreen;
- (void) openShowAlongScreen;

@end

@interface OALocalRoutingParameter : NSObject

@property (nonatomic) OARoutingHelper *routingHelper;
@property (nonatomic) OAAppSettings *settings;

@property (nonatomic, weak) id<OARoutePreferencesParametersDelegate> delegate;

@property struct RoutingParameter routingParameter;

- (instancetype)initWithAppMode:(OAApplicationMode *)am;
- (void) commonInit;

- (NSString *) getText;
- (BOOL) isSelected;
- (void) setSelected:(BOOL)isChecked;
- (OAApplicationMode *) getApplicationMode;

- (BOOL) isChecked;
- (NSString *) getValue;
- (NSString *) getDescription;
- (UIImage *) getIcon;
- (NSString *) getIconName;
- (NSString *) getCellType;
- (BOOL) hasOptions;
- (UIColor *) getTintColor;

- (void) setControlAction:(UIControl *)control;
- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;

- (void)applyNewParameterValue:(BOOL)isChecked;

@end

@interface OALocalNonAvoidParameter : OALocalRoutingParameter

@end

@interface OAOtherLocalRoutingParameter : OALocalRoutingParameter

- (instancetype) initWithId:(int)paramId text:(NSString *)text selected:(BOOL)selected;

- (int) getId;

@end

@interface OALocalRoutingParameterGroup : OALocalRoutingParameter

- (instancetype) initWithAppMode:(OAApplicationMode *)am groupName:(NSString *)groupName;

- (void) addRoutingParameter:(RoutingParameter)routingParameter;
- (NSString *) getGroupName;
- (NSMutableArray<OALocalRoutingParameter *> *) getRoutingParameters;
- (OALocalRoutingParameter *) getSelected;

@end

@interface OAMuteSoundRoutingParameter : OALocalRoutingParameter
@end

@interface OAInterruptMusicRoutingParameter : OALocalRoutingParameter
@end

@interface OAAvoidRoadsRoutingParameter : OALocalRoutingParameter
@end

@interface OAShowAlongTheRouteItem : OALocalRoutingParameter
@end

@interface OAAvoidTransportTypesRoutingParameter : OALocalRoutingParameter
@end

@interface OAGpxLocalRoutingParameter : OALocalRoutingParameter
@end

@interface OASimulationRoutingParameter : OALocalRoutingParameter
@end

@interface OAConsiderLimitationsParameter : OALocalRoutingParameter
@end

@interface OAOtherSettingsRoutingParameter : OALocalRoutingParameter
@end

@interface OACustomizeRouteLineRoutingParameter : OALocalRoutingParameter
@end

@interface OAHazmatRoutingParameter : OALocalRoutingParameter

- (NSString *)getValue:(NSInteger)index;
- (void)setValue:(NSInteger)index;

@end

@interface OAGoodsDeliveryRoutingParameter : OALocalRoutingParameter

@end
