//
//  OARoutePreferencesParameters.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define calculate_osmand_route_without_internet_id 100
#define fast_route_mode_id 101
#define use_points_as_intermediates_id 102
#define gpx_option_reverse_route_id 103
#define gpx_option_from_start_point_id 104
#define gpx_option_calculate_first_last_segment_id 105
#define calculate_osmand_route_gpx_id 106
#define speak_favorites_id 107

@class OAApplicationMode, OARoutingHelper, OAAppSettings;
@class OALocalRoutingParameterGroup;

struct RoutingParameter;

@protocol OARoutePreferencesParametersDelegate <NSObject>

@required
- (void) updateParameters;
- (void) openNavigationSettings;
- (void) showParameterGroupScreen:(OALocalRoutingParameterGroup *)group;
- (void) selectVoiceGuidance:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
- (void) showAvoidRoadsScreen;
- (void) showTripSettingsScreen;
- (void) showAvoidTransportScreen;

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
- (NSString *) getCellType;
- (UIImage *) getSecondaryIcon;
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
