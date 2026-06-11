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

#ifdef DEBUG
#define OAAisMenuLog(format, ...) NSLog((@"[AIS][Menu] " format), ##__VA_ARGS__)
#else
#define OAAisMenuLog(format, ...)
#endif

@implementation OAAisObjectViewController
{
    AisObject *_object;
    NSMutableArray<OAAmenityInfoRow *> *_menuRows;
    NSMutableSet<NSString *> *_aisValueRowKeys;
}

- (instancetype)initWithAisObject:(AisObject *)object
{
    self = [super initWithNibName:@"OATargetInfoViewController" bundle:nil];
    if (self)
    {
        _object = object;
        self.location = CLLocationCoordinate2DMake(object.latitude, object.longitude);
        self.showTitleIfTruncated = NO;
        self.customOnlinePhotosPosition = YES;
        OAAisMenuLog(@"init %@", object.debugSummary);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:[OAValueTableViewCell reuseIdentifier] bundle:nil]
          forCellReuseIdentifier:[OAValueTableViewCell reuseIdentifier]];
    OAAisMenuLog(@"viewDidLoad table=%@ height=%.1f %@", self.tableView ? @"yes" : @"no", [self contentHeight], _object.debugSummary);
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
    OAAisMenuLog(@"buildMenu rows=%lu height=%.1f %@", (unsigned long)rows.count, [self contentHeight], _object.debugSummary);
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

    [self addRow:rows key:@"mmsi" prefix:@"MMSI" text:[NSString stringWithFormat:@"%ld", (long)_object.mmsi] order:order++];
    if (_object.hasPosition)
    {
        [self addRow:rows key:@"position" prefix:@"Position" text:[self formatPosition] order:order++];
    }
    if (plugin)
    {
        double distance = [plugin distanceInNauticalMilesTo:_object];
        if (distance >= 0)
            [self addRow:rows key:@"distance" prefix:@"Distance" text:[NSString stringWithFormat:@"%.1f nm", distance] order:order++];
        double bearing = [plugin bearingTo:_object];
        if (bearing >= 0)
            [self addRow:rows key:@"bearing" prefix:@"Bearing" text:[NSString stringWithFormat:@"%.0f", bearing] order:order++];
    }
    if (_object.cpa.valid)
    {
        [self addRow:rows key:@"cpa" prefix:@"CPA" text:[NSString stringWithFormat:@"%.1f nm", _object.cpa.cpaDistance] order:order++];
        [self addRow:rows key:@"tcpa" prefix:@"TCPA" text:[self formatTcpa:_object.cpa.tcpa] order:order++];
    }

    if (_object.objectClass == AisObjTypeAton || _object.objectClass == AisObjTypeAtonVirtual)
    {
        if (_object.aidType != 0)
            [self addRow:rows key:@"aid_type" prefix:@"Aid Type" text:_object.aidTypeString order:order++];
        order = [self addDimensionRows:rows order:order];
    }
    else if (_object.objectClass == AisObjTypeAirplane)
    {
        [self addRow:rows key:@"object_type" prefix:@"Object Type" text:[self objectTypeName:_object.objectClass] order:order++];
        order = [self addCourseRows:rows order:order includeHeading:NO includeNavStatus:NO];
        if (_object.altitude != 4095)
            [self addRow:rows key:@"altitude" prefix:@"Altitude" text:[NSString stringWithFormat:@"%ld m", (long)_object.altitude] order:order++];
    }
    else
    {
        if (_object.callSign.length > 0)
            [self addRow:rows key:@"callsign" prefix:@"Callsign" text:_object.callSign order:order++];
        if (_object.imo > 0 && _object.hasImoMessage)
            [self addRow:rows key:@"imo" prefix:@"IMO" text:[NSString stringWithFormat:@"%ld", (long)_object.imo] order:order++];
        if (_object.shipName.length > 0)
            [self addRow:rows key:@"ship_name" prefix:@"Shipname" text:_object.shipName order:order++];
        if (_object.shipType != 0 && _object.hasShipTypeMessage)
            [self addRow:rows key:@"ship_type" prefix:@"Shiptype" text:_object.shipTypeString order:order++];
        order = [self addCourseRows:rows order:order includeHeading:YES includeNavStatus:YES];
        order = [self addDimensionRows:rows order:order];
        if (_object.draught > 0)
            [self addRow:rows key:@"draught" prefix:@"Draught" text:[NSString stringWithFormat:@"%.1f m", _object.draught] order:order++];
        if (_object.destination.length > 0)
            [self addRow:rows key:@"destination" prefix:@"Destination" text:_object.destination order:order++];
        if (_object.etaMonth > 0 && _object.etaDay > 0)
            [self addRow:rows key:@"eta" prefix:@"ETA" text:[NSString stringWithFormat:@"%02ld.%02ld. %02ld:%02ld", (long)_object.etaDay, (long)_object.etaMonth, (long)_object.etaHour, (long)_object.etaMinute] order:order++];
    }

    [self addRow:rows key:@"last_update" prefix:@"Last Update" text:[self formatLastUpdate] order:order++];
    if (_object.messageTypesString.length > 0)
        [self addRow:rows key:@"message_types" prefix:@"Message Type(s)" text:_object.messageTypesString order:order++];
    OAAisMenuLog(@"buildInternal rows=%lu %@", (unsigned long)rows.count, _object.debugSummary);
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
    if (includeNavStatus && _object.navStatus != 15)
        [self addRow:rows key:@"nav_status" prefix:@"Navigation Status" text:_object.navStatusString.upperCase order:order++];
    if (_object.cog != 360.0)
        [self addRow:rows key:@"cog" prefix:@"COG" text:[NSString stringWithFormat:@"%.0f", _object.cog] order:order++];
    if (_object.sog != 1023.0)
        [self addRow:rows key:@"sog" prefix:@"SOG" text:[NSString stringWithFormat:@"%.1f KTS", _object.sog] order:order++];
    if (includeHeading && _object.heading != 511)
        [self addRow:rows key:@"heading" prefix:@"Heading" text:[NSString stringWithFormat:@"%ld", (long)_object.heading] order:order++];
    if (includeHeading && _object.rot != 128.0)
        [self addRow:rows key:@"rot" prefix:@"Rate of Turn" text:[NSString stringWithFormat:@"%.1f", _object.rot] order:order++];
    return order;
}

- (NSInteger)addDimensionRows:(NSMutableArray<OAAmenityInfoRow *> *)rows order:(NSInteger)order
{
    NSInteger length = _object.dimensionToBow + _object.dimensionToStern;
    NSInteger width = _object.dimensionToPort + _object.dimensionToStarboard;
    if (length > 0 && width > 0)
        [self addRow:rows key:@"dimensions" prefix:@"Dimension" text:[NSString stringWithFormat:@"%ldm x %ldm", (long)length, (long)width] order:order++];
    return order;
}

- (NSString *)formatPosition
{
    NSString *lat = [OALocationConvert convertLatitude:_object.latitude outputType:FORMAT_MINUTES addCardinalDirection:YES];
    NSString *lon = [OALocationConvert convertLongitude:_object.longitude outputType:FORMAT_MINUTES addCardinalDirection:YES];
    return [NSString stringWithFormat:@"%@, %@", lat, lon];
}

- (NSString *)formatLastUpdate
{
    NSInteger seconds = MAX(0, (NSInteger)round(-[_object.lastUpdate timeIntervalSinceNow]));
    if (seconds > 60)
        return [NSString stringWithFormat:@"%ld min %ld sec", (long)(seconds / 60), (long)(seconds % 60)];
    return [NSString stringWithFormat:@"%ld sec", (long)seconds];
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
