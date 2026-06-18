//
//  OAAisObjectViewController.m
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAAisObjectViewController.h"
#import "OAAmenityInfoRow.h"
#import "OAPluginsHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OALocationConvert.h"
#import "OAValueTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

static const NSInteger kAisRowStartOrder = 100;
static const NSInteger kAisRowHeight = 50;

static BOOL OAAisTypeEquals(OASAisObjType *type, OASAisObjType *expected)
{
    return type == expected || [type isEqual:expected];
}

static NSDate *OAAisLastUpdateDate(OASAisObject *object)
{
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)object.lastUpdate / 1000.0];
}

static BOOL OAAisHasMessageType(OASAisObject *object, int type)
{
    return [object.msgTypes containsObject:[[OASInt alloc] initWithInt:type]];
}

static NSString *OAAisMessageTypesString(OASAisObject *object)
{
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (OASInt *type in object.msgTypes)
        [values addObject:[NSString stringWithFormat:@"%d", type.intValue]];
    [values sortUsingSelector:@selector(compare:)];
    return [values componentsJoinedByString:@", "];
}

@implementation OAAisObjectViewController
{
    OASAisObject *_object;
    NSMutableArray<OAAmenityInfoRow *> *_menuRows;
    NSMutableSet<NSString *> *_aisValueRowKeys;
}

- (instancetype)initWithAisObject:(OASAisObject *)object
{
    self = [super initWithNibName:@"OATargetInfoViewController" bundle:nil];
    if (self)
    {
        _object = object;
        if (object.position)
            self.location = CLLocationCoordinate2DMake(object.position.latitude, object.position.longitude);
        self.showTitleIfTruncated = NO;
        self.customOnlinePhotosPosition = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:[OAValueTableViewCell reuseIdentifier] bundle:nil]
          forCellReuseIdentifier:[OAValueTableViewCell reuseIdentifier]];
}

- (id)getTargetObj
{
    return _object;
}

- (UIImage *)getIcon
{
    return [[UIImage imageNamed:ACImageNameIcActionSailBoatDark]
            imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (NSString *)getTypeStr
{
    return [self objectTypeName:_object.objectClass];
}

- (NSString *)getCommonTypeStr
{
    return [self getTypeStr];
}

- (NSString *)getNameStr
{
    return [NSString stringWithFormat:OALocalizedString(@"ais_object_with_mmsi"), (long)_object.mmsi];
}

- (NSAttributedString *)getAdditionalInfoStr
{
    return nil;
}

- (BOOL)needAddress
{
    return NO;
}

- (BOOL)showDetailsButton
{
    return NO;
}

- (BOOL)showNearestWiki
{
    return NO;
}

- (BOOL)showNearestPoi
{
    return NO;
}

- (void)buildDescription:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
}

- (void)buildTopInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
}

- (void)buildMenu:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    _menuRows = rows;
    _aisValueRowKeys = [NSMutableSet set];
    [super buildMenu:rows];
}

- (void)buildPluginRows:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
}

- (void)buildInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    NSInteger order = kAisRowStartOrder;
    AisTrackerPlugin *plugin = (AisTrackerPlugin *)[OAPluginsHelper getPlugin:AisTrackerPlugin.class];
    if (plugin)
        [plugin updateCpaFor:_object];

    [self addRow:rows key:@"mmsi" prefix:OALocalizedString(@"ais_mmsi") text:[NSString stringWithFormat:@"%ld", (long)_object.mmsi] order:order++];
    if (_object.position)
    {
        [self addRow:rows key:@"position" prefix:OALocalizedString(@"ais_position") text:[self formatPosition] order:order++];
    }
    if (plugin)
    {
        double distance = [plugin distanceInNauticalMilesTo:_object];
        if (distance >= 0)
            [self addRow:rows key:@"distance" prefix:OALocalizedString(@"shared_string_distance") text:[NSString stringWithFormat:@"%.1f nm", distance] order:order++];
        double bearing = [plugin bearingTo:_object];
        if (bearing >= 0)
            [self addRow:rows key:@"bearing" prefix:OALocalizedString(@"shared_string_bearing") text:[NSString stringWithFormat:@"%.0f", bearing] order:order++];
    }
    if (_object.cpa.valid)
    {
        [self addRow:rows key:@"cpa" prefix:OALocalizedString(@"ais_cpa") text:[NSString stringWithFormat:@"%.1f nm", _object.cpa.cpa] order:order++];
        [self addRow:rows key:@"tcpa" prefix:OALocalizedString(@"ais_tcpa") text:[self formatTcpa:_object.cpa.tcpa] order:order++];
    }

    if (OAAisTypeEquals(_object.objectClass, OASAisObjType.aisAton) || OAAisTypeEquals(_object.objectClass, OASAisObjType.aisAtonVirtual))
    {
        if (_object.aidType != OASAisObjectConstants.shared.UNSPECIFIED_AID_TYPE)
            [self addRow:rows key:@"aid_type" prefix:OALocalizedString(@"ais_aid_type") text:[_object getAidTypeString] order:order++];
        order = [self addDimensionRows:rows order:order];
    }
    else if (OAAisTypeEquals(_object.objectClass, OASAisObjType.aisAirplane))
    {
        [self addRow:rows key:@"object_type" prefix:OALocalizedString(@"ais_object_type") text:[self objectTypeName:_object.objectClass] order:order++];
        order = [self addCourseRows:rows order:order includeHeading:NO includeNavStatus:NO];
        if (_object.altitude != OASAisObjectConstants.shared.INVALID_ALTITUDE)
            [self addRow:rows key:@"altitude" prefix:OALocalizedString(@"altitude") text:[NSString stringWithFormat:@"%ld m", (long)_object.altitude] order:order++];
    }
    else
    {
        if (_object.callSign.length > 0)
            [self addRow:rows key:@"callsign" prefix:OALocalizedString(@"ais_call_sign") text:_object.callSign order:order++];
        if (_object.imo > 0 && OAAisHasMessageType(_object, 5))
            [self addRow:rows key:@"imo" prefix:OALocalizedString(@"ais_imo") text:[NSString stringWithFormat:@"%ld", (long)_object.imo] order:order++];
        if (_object.shipName.length > 0)
            [self addRow:rows key:@"ship_name" prefix:OALocalizedString(@"ais_ship_name") text:_object.shipName order:order++];
        if (OAAisHasMessageType(_object, 5) || OAAisHasMessageType(_object, 19) || OAAisHasMessageType(_object, 24))
            [self addRow:rows key:@"ship_type" prefix:OALocalizedString(@"ais_ship_type") text:[_object getShipTypeString] order:order++];
        order = [self addCourseRows:rows order:order includeHeading:YES includeNavStatus:YES];
        order = [self addDimensionRows:rows order:order];
        if (_object.draught != OASAisObjectConstants.shared.INVALID_DRAUGHT)
            [self addRow:rows key:@"draught" prefix:OALocalizedString(@"ais_draught") text:[NSString stringWithFormat:@"%.1f m", _object.draught] order:order++];
        if (_object.destination.length > 0)
            [self addRow:rows key:@"destination" prefix:OALocalizedString(@"ais_destination") text:_object.destination order:order++];
        if (_object.etaMon != OASAisObjectConstants.shared.INVALID_ETA && _object.etaDay != OASAisObjectConstants.shared.INVALID_ETA)
            [self addRow:rows key:@"eta" prefix:OALocalizedString(@"ais_eta") text:[NSString stringWithFormat:@"%02ld.%02ld. %02ld:%02ld", (long)_object.etaDay, (long)_object.etaMon, (long)_object.etaHour, (long)_object.etaMin] order:order++];
    }

    [self addRow:rows key:@"last_update" prefix:OALocalizedString(@"ais_last_update") text:[self formatLastUpdate] order:order++];
    NSString *messageTypesString = OAAisMessageTypesString(_object);
    if (messageTypesString.length > 0)
        [self addRow:rows key:@"message_types" prefix:OALocalizedString(@"ais_message_types") text:messageTypesString order:order++];
}

- (BOOL)needBuildCoordinatesRow
{
    return YES;
}

- (void)addRow:(NSMutableArray<OAAmenityInfoRow *> *)rows key:(NSString *)key prefix:(NSString *)prefix text:(NSString *)text order:(NSInteger)order
{
    if (text.length == 0)
        return;
    OAAmenityInfoRow *row = [[OAAmenityInfoRow alloc] initWithKey:key
                                                             icon:nil
                                                       textPrefix:prefix
                                                             text:text
                                                        textColor:[UIColor colorNamed:ACColorNameTextColorPrimary]
                                                           isText:YES
                                                        needLinks:NO
                                                            order:order
                                                         typeName:key
                                                    isPhoneNumber:NO
                                                            isUrl:NO];
    row.height = kAisRowHeight;
    [rows addObject:row];
    [_aisValueRowKeys addObject:key];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAAmenityInfoRow *row = indexPath.row < _menuRows.count ? _menuRows[indexPath.row] : nil;
    if (row.key.length > 0 && [_aisValueRowKeys containsObject:row.key])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell reuseIdentifier]];

        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        [cell valueVisibility:YES];
        [cell setupValueLabelFlexible];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.titleLabel.text = row.textPrefix;
        cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.titleLabel.numberOfLines = 0;
        cell.valueLabel.text = row.text;
        cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
        cell.valueLabel.font = [UIFont scaledSystemFontOfSize:16.0 weight:UIFontWeightMedium];
        cell.valueLabel.numberOfLines = 0;
        cell.accessibilityLabel = row.textPrefix;
        cell.accessibilityValue = row.text;
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSInteger)addCourseRows:(NSMutableArray<OAAmenityInfoRow *> *)rows
                     order:(NSInteger)order
            includeHeading:(BOOL)includeHeading
          includeNavStatus:(BOOL)includeNavStatus
{
    if (includeNavStatus && _object.navStatus != OASAisObjectConstants.shared.INVALID_NAV_STATUS)
        [self addRow:rows key:@"nav_status" prefix:OALocalizedString(@"ais_navigation_status") text:[_object getNavStatusString].upperCase order:order++];
    if (_object.cog != OASAisObjectConstants.shared.INVALID_COG)
        [self addRow:rows key:@"cog" prefix:OALocalizedString(@"ais_cog") text:[NSString stringWithFormat:@"%.0f", _object.cog] order:order++];
    if (_object.sog != OASAisObjectConstants.shared.INVALID_SOG)
        [self addRow:rows key:@"sog" prefix:OALocalizedString(@"ais_sog") text:[NSString stringWithFormat:@"%.1f %@", _object.sog, OALocalizedString(@"shared_string_kts")] order:order++];
    if (includeHeading && _object.heading != OASAisObjectConstants.shared.INVALID_HEADING)
        [self addRow:rows key:@"heading" prefix:OALocalizedString(@"ais_heading") text:[NSString stringWithFormat:@"%ld", (long)_object.heading] order:order++];
    if (includeHeading && _object.rot != OASAisObjectConstants.shared.INVALID_ROT)
        [self addRow:rows key:@"rot" prefix:OALocalizedString(@"ais_rate_of_turn") text:[NSString stringWithFormat:@"%.1f", _object.rot] order:order++];
    return order;
}

- (NSInteger)addDimensionRows:(NSMutableArray<OAAmenityInfoRow *> *)rows order:(NSInteger)order
{
    const int32_t invalidDimension = OASAisObjectConstants.shared.INVALID_DIMENSION;
    NSInteger length = _object.dimensionToBow + _object.dimensionToStern;
    NSInteger width = _object.dimensionToPort + _object.dimensionToStarboard;
    if ((_object.dimensionToBow != invalidDimension || _object.dimensionToStern != invalidDimension)
        && (_object.dimensionToPort != invalidDimension || _object.dimensionToStarboard != invalidDimension))
        [self addRow:rows key:@"dimension" prefix:OALocalizedString(@"ais_dimension") text:[NSString stringWithFormat:@"%ldm x %ldm", (long)length, (long)width] order:order++];
    return order;
}

- (NSString *)formatPosition
{
    NSString *lat = [OALocationConvert convertLatitude:_object.position.latitude outputType:FORMAT_MINUTES addCardinalDirection:YES];
    NSString *lon = [OALocationConvert convertLongitude:_object.position.longitude outputType:FORMAT_MINUTES addCardinalDirection:YES];
    return [NSString stringWithFormat:@"%@, %@", lat, lon];
}

- (NSString *)formatLastUpdate
{
    NSInteger seconds = MAX(0, (NSInteger)round(-[OAAisLastUpdateDate(_object) timeIntervalSinceNow]));
    if (seconds > 60)
        return [NSString stringWithFormat:@"%ld %@ %ld %@", (long)(seconds / 60), OALocalizedString(@"shared_string_minute_lowercase"), (long)(seconds % 60), OALocalizedString(@"shared_string_sec")];
    return [NSString stringWithFormat:@"%ld %@", (long)seconds, OALocalizedString(@"shared_string_sec")];
}

- (NSString *)objectTypeName:(OASAisObjType *)type
{
    if (OAAisTypeEquals(type, OASAisObjType.aisVessel))
        return OALocalizedString(@"ais_type_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselSport))
        return OALocalizedString(@"ais_type_sport_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselFast))
        return OALocalizedString(@"ais_type_high_speed_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselPassenger))
        return OALocalizedString(@"ais_type_passenger_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselFreight))
        return OALocalizedString(@"ais_type_cargo_tanker");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselCommercial))
        return OALocalizedString(@"ais_type_commercial_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselAuthorities))
        return OALocalizedString(@"ais_type_authorities_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselSar))
        return OALocalizedString(@"ais_type_sar_vessel");
    if (OAAisTypeEquals(type, OASAisObjType.aisLandstation))
        return OALocalizedString(@"ais_type_base_station");
    if (OAAisTypeEquals(type, OASAisObjType.aisAirplane))
        return OALocalizedString(@"ais_type_sar_aircraft");
    if (OAAisTypeEquals(type, OASAisObjType.aisSart))
        return OALocalizedString(@"ais_type_sart");
    if (OAAisTypeEquals(type, OASAisObjType.aisAton))
        return OALocalizedString(@"ais_type_aid_to_navigation");
    if (OAAisTypeEquals(type, OASAisObjType.aisAtonVirtual))
        return OALocalizedString(@"ais_type_virtual_aid_to_navigation");
    if (OAAisTypeEquals(type, OASAisObjType.aisVesselOther))
        return OALocalizedString(@"ais_type_other_vessel");
    return OALocalizedString(@"ais_type_object");
}

- (NSString *)formatTcpa:(double)tcpa
{
    BOOL future = tcpa >= 0;
    double absTcpa = fabs(tcpa);
    NSInteger hours = (NSInteger)absTcpa;
    NSInteger minutes = (NSInteger)round((absTcpa - hours) * 60.0);
    NSString *value = hours > 0 ? [NSString stringWithFormat:@"%ld %@ %ld %@", (long)hours, OALocalizedString(@"int_hour"), (long)minutes, OALocalizedString(@"shared_string_minute_lowercase")] : [NSString stringWithFormat:@"%ld %@", (long)minutes, OALocalizedString(@"shared_string_minute_lowercase")];
    return future ? value : [NSString stringWithFormat:@"-%@", value];
}

@end
