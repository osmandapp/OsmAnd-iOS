#import "OAAisObjectViewController.h"
#import "OAAmenityInfoRow.h"
#import "OAPluginsHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAAisObjectViewController
{
    AisObject *_object;
}

- (instancetype)initWithAisObject:(AisObject *)object
{
    self = [super init];
    if (self)
    {
        _object = object;
        self.location = CLLocationCoordinate2DMake(object.latitude, object.longitude);
        self.showTitleIfTruncated = NO;
        self.customOnlinePhotosPosition = YES;
    }
    return self;
}

- (id)getTargetObj
{
    return _object;
}

- (UIImage *)getIcon
{
    return [UIImage imageNamed:@"ic_plugin_nautical"];
}

- (NSString *)getTypeStr
{
    return OALocalizedString(@"plugin_ais_tracker_name");
}

- (NSString *)getCommonTypeStr
{
    return [self getTypeStr];
}

- (BOOL)needAddress
{
    return NO;
}

- (BOOL)showDetailsButton
{
    return NO;
}

- (void)buildDescription:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    [self addRow:rows key:@"mmsi" prefix:@"MMSI" text:[NSString stringWithFormat:@"%ld", (long)_object.mmsi] order:0];
    if (_object.imo > 0)
        [self addRow:rows key:@"imo" prefix:@"IMO" text:[NSString stringWithFormat:@"%ld", (long)_object.imo] order:1];
    if (_object.shipName.length > 0)
        [self addRow:rows key:@"ship_name" prefix:OALocalizedString(@"shared_string_name") text:_object.shipName order:2];
    if (_object.callSign.length > 0)
        [self addRow:rows key:@"callsign" prefix:OALocalizedString(@"ais_call_sign") text:_object.callSign order:3];
    [self addRow:rows key:@"object_type" prefix:OALocalizedString(@"ais_object_type") text:[self objectTypeName:_object.objectClass] order:4];
    if (_object.shipType != 0)
        [self addRow:rows key:@"ship_type" prefix:OALocalizedString(@"ais_ship_type") text:_object.shipTypeString order:5];
}

- (void)buildInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    NSInteger order = 100;
    OAAisTrackerPlugin *plugin = (OAAisTrackerPlugin *)[OAPluginsHelper getPlugin:OAAisTrackerPlugin.class];
    if (plugin)
        [plugin updateCpaFor:_object];

    if (_object.hasPosition)
    {
        [self addRow:rows key:@"position" prefix:OALocalizedString(@"ais_position") text:[NSString stringWithFormat:@"%.5f, %.5f", _object.latitude, _object.longitude] order:order++];
    }
    if (plugin)
    {
        double distance = [plugin distanceInNauticalMilesTo:_object];
        if (distance >= 0)
            [self addRow:rows key:@"distance" prefix:OALocalizedString(@"shared_string_distance") text:[NSString stringWithFormat:@"%.2f nm", distance] order:order++];
        double bearing = [plugin bearingTo:_object];
        if (bearing >= 0)
            [self addRow:rows key:@"bearing" prefix:OALocalizedString(@"shared_string_bearing") text:[NSString stringWithFormat:@"%.0f°", bearing] order:order++];
    }
    if (_object.messageTypesString.length > 0)
        [self addRow:rows key:@"message_types" prefix:OALocalizedString(@"ais_message_types") text:_object.messageTypesString order:order++];
    if (_object.sog != 1023.0)
        [self addRow:rows key:@"sog" prefix:@"SOG" text:[NSString stringWithFormat:@"%.1f kn", _object.sog] order:order++];
    if (_object.cog != 360.0)
        [self addRow:rows key:@"cog" prefix:@"COG" text:[NSString stringWithFormat:@"%.0f°", _object.cog] order:order++];
    if (_object.heading != 511)
        [self addRow:rows key:@"heading" prefix:OALocalizedString(@"ais_heading") text:[NSString stringWithFormat:@"%ld°", (long)_object.heading] order:order++];
    if (_object.navStatus != 15)
        [self addRow:rows key:@"nav_status" prefix:OALocalizedString(@"ais_navigation_status") text:_object.navStatusString order:order++];
    if (_object.maneuverIndicator != 0)
        [self addRow:rows key:@"maneuver" prefix:OALocalizedString(@"ais_maneuver") text:_object.maneuverIndicatorString order:order++];
    if (_object.rot != 128.0)
        [self addRow:rows key:@"rot" prefix:@"ROT" text:[NSString stringWithFormat:@"%.1f", _object.rot] order:order++];
    if (_object.altitude != 4095)
        [self addRow:rows key:@"altitude" prefix:OALocalizedString(@"altitude") text:[NSString stringWithFormat:@"%ld m", (long)_object.altitude] order:order++];
    if (_object.aidType != 0)
        [self addRow:rows key:@"aid_type" prefix:OALocalizedString(@"ais_aid_type") text:_object.aidTypeString order:order++];

    NSInteger length = _object.dimensionToBow + _object.dimensionToStern;
    NSInteger width = _object.dimensionToPort + _object.dimensionToStarboard;
    if (length > 0 || width > 0)
        [self addRow:rows key:@"dimensions" prefix:OALocalizedString(@"ais_dimensions") text:[NSString stringWithFormat:@"%ld x %ld m", (long)length, (long)width] order:order++];
    if (_object.dimensionToBow > 0 || _object.dimensionToStern > 0 || _object.dimensionToPort > 0 || _object.dimensionToStarboard > 0)
        [self addRow:rows key:@"antenna" prefix:OALocalizedString(@"ais_antenna") text:[NSString stringWithFormat:OALocalizedString(@"ais_antenna_offsets_format"), (long)_object.dimensionToBow, (long)_object.dimensionToStern, (long)_object.dimensionToPort, (long)_object.dimensionToStarboard] order:order++];
    if (_object.draught > 0)
        [self addRow:rows key:@"draught" prefix:OALocalizedString(@"ais_draught") text:[NSString stringWithFormat:@"%.1f m", _object.draught] order:order++];
    if (_object.destination.length > 0)
        [self addRow:rows key:@"destination" prefix:OALocalizedString(@"ais_destination") text:_object.destination order:order++];
    if (_object.etaMonth > 0 && _object.etaDay > 0)
        [self addRow:rows key:@"eta" prefix:@"ETA" text:[NSString stringWithFormat:@"%02ld/%02ld %02ld:%02ld", (long)_object.etaMonth, (long)_object.etaDay, (long)_object.etaHour, (long)_object.etaMinute] order:order++];

    [self addRow:rows key:@"last_update" prefix:OALocalizedString(@"ais_last_update") text:[NSDateFormatter localizedStringFromDate:_object.lastUpdate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle] order:order++];
    if (_object.cpa.valid)
    {
        [self addRow:rows key:@"cpa" prefix:@"CPA" text:[NSString stringWithFormat:@"%.2f nm", _object.cpa.cpaDistance] order:order++];
        [self addRow:rows key:@"tcpa" prefix:@"TCPA" text:[self formatTcpa:_object.cpa.tcpa] order:order++];
    }
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
                                                        textColor:nil
                                                           isText:YES
                                                        needLinks:NO
                                                            order:order
                                                         typeName:key
                                                    isPhoneNumber:NO
                                                            isUrl:NO];
    [rows addObject:row];
}

- (NSString *)objectTypeName:(AisObjType)type
{
    switch (type)
    {
        case AisObjTypeVessel: return OALocalizedString(@"ais_type_vessel");
        case AisObjTypeVesselSport: return OALocalizedString(@"ais_type_sport_vessel");
        case AisObjTypeVesselFast: return OALocalizedString(@"ais_type_high_speed_vessel");
        case AisObjTypeVesselPassenger: return OALocalizedString(@"ais_type_passenger_vessel");
        case AisObjTypeVesselFreight: return OALocalizedString(@"ais_type_cargo_tanker");
        case AisObjTypeVesselCommercial: return OALocalizedString(@"ais_type_commercial_vessel");
        case AisObjTypeVesselAuthorities: return OALocalizedString(@"ais_type_authorities_vessel");
        case AisObjTypeVesselSar: return OALocalizedString(@"ais_type_sar_vessel");
        case AisObjTypeLandStation: return OALocalizedString(@"ais_type_base_station");
        case AisObjTypeAirplane: return OALocalizedString(@"ais_type_sar_aircraft");
        case AisObjTypeSart: return OALocalizedString(@"ais_type_sart");
        case AisObjTypeAton: return OALocalizedString(@"ais_type_aid_to_navigation");
        case AisObjTypeAtonVirtual: return OALocalizedString(@"ais_type_virtual_aid_to_navigation");
        case AisObjTypeVesselOther: return OALocalizedString(@"ais_type_other_vessel");
        default: return OALocalizedString(@"ais_type_object");
    }
}

- (NSString *)formatTcpa:(double)tcpa
{
    BOOL future = tcpa >= 0;
    double absTcpa = fabs(tcpa);
    NSInteger hours = (NSInteger)absTcpa;
    NSInteger minutes = (NSInteger)round((absTcpa - hours) * 60.0);
    NSString *value = hours > 0 ? [NSString stringWithFormat:@"%ld h %ld min", (long)hours, (long)minutes] : [NSString stringWithFormat:@"%ld min", (long)minutes];
    return future ? value : [NSString stringWithFormat:@"-%@", value];
}

@end
