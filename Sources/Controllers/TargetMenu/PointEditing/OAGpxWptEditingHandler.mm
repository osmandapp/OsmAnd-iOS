//
//  OAGpxWptEditingHandler.mm
//  OsmAnd Maps
//
//  Created by Skalii on 02.06.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAGpxWptEditingHandler.h"
#import "OAGpxWptItem.h"
#import "OAFavoriteItem.h"
#import "OAPOI.h"
#import "OADefaultFavorite.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAEditPointViewController.h"
#import "OASavingTrackHelper.h"
#import "OAGPXAppearanceCollection.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGpxWptEditingHandler
{
    OAGpxWptItem *_gpxWpt;
    OsmAndAppInstance _app;
    NSString *_gpxFileName;
    OASGpxFile *_gpxDocument;
    NSMutableArray<OASGpxUtilitiesPointsGroup *> *_pendingGroups;
    NSString *_iconName;
}

- (instancetype)initWithItem:(OAGpxWptItem *)gpxWpt
{
    self = [super init];
    if (self)
    {
        _gpxWpt = gpxWpt;
        _gpxFileName = _gpxWpt.docPath;
        _iconName = _gpxWpt.point.getIconName;

        [self commonInit];
    }
    return self;
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedLocation address:(NSString *)address gpxFileName:(NSString*)gpxFileName poi:(OAPOI *)poi
{
    return [self initWithLocation:location title:formattedLocation address:address gpxFileName:gpxFileName poi:poi gpxFile:nil];
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedLocation address:(NSString *)address gpxFileName:(NSString*)gpxFileName poi:(OAPOI *)poi gpxFile:(OASGpxFile *)gpxFile
{
    self = [super init];
    if (self)
    {
        _gpxFileName = gpxFileName;
        _gpxDocument = gpxFile;
        UIColor *color = [OADefaultFavorite getDefaultColor];

        OAGpxWptItem *wpt = [[OAGpxWptItem alloc] init];
        OASWptPt* p = [[OASWptPt alloc] init];
        p.name = formattedLocation;
        p.lat = location.latitude;
        p.lon = location.longitude;
        p.time = (long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        OASInt *colorToSave = [[OASInt alloc] initWithInt:[color toARGBNumber]];
        
        [p setColorColor:colorToSave];
        p.desc = @"";
        
        _iconName = nil;
        NSString *poiIconName = [self.class getPoiIconName:poi];
        if (poiIconName && poiIconName.length > 0)
            _iconName = poiIconName;
        
        [p setIconNameIconName:_iconName];
        [p setBackgroundTypeBackType:DEFAULT_ICON_SHAPE_KEY];
        [p setAddressAddress:address];
        NSDictionary<NSString *, NSString *> *extensions = [poi toTagValue:AMENITY_PREFIX osmPrefix:OSM_PREFIX_KEY];
        [[p getExtensionsToWrite] addEntriesFromDictionary:extensions];
        
        NSString *originName = poi.toStringEn;
        if (originName.length > 0)
            [p setAmenityOriginNameOriginName:originName];

        wpt.color = color;
        wpt.point = p;

        _gpxWpt = wpt;

        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    if (_gpxDocument != nil)
        return;

    if (_gpxFileName.length > 0)
    {
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_gpxFileName];
        _gpxDocument = [OASGpxUtilities.shared loadGpxFileFile:file];
    }
    else
    {
        _gpxDocument =  [[OASavingTrackHelper sharedInstance] currentTrack];
    }
}

- (UIColor *)getColor
{
    return _gpxWpt.color ? _gpxWpt.color : UIColorFromARGB([_gpxWpt.point getColor]);
}

- (NSString *)getGroupTitle
{
    return _gpxWpt.point.category && _gpxWpt.point.category.length > 0 ? _gpxWpt.point.category : OALocalizedString(@"shared_string_waypoints");
}

- (OASGpxFile *)getGpxDocument
{
    return _gpxDocument;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getWaypointCategoriesWithAllData:(BOOL)withDefaultCategory
{
    NSMapTable<NSString *, NSDictionary *> *map = [NSMapTable new];
    for (OASWptPt *point in _gpxDocument.getPointsList)
    {
        NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
        NSString *title = point.category == nil ? @"" : point.category;
        categories[@"title"] = title;
        NSString *color = UIColorFromARGB([point getColor]).toHexARGBString;
        NSString *count = @"1";
        categories[@"count"] = count;
        categories[@"hidden"] = _gpxDocument.pointsGroups[title].hidden ? @"true" : @"false";

        BOOL emptyCategory = title.length == 0;
        if (!emptyCategory)
        {
            NSDictionary<NSString *, NSString *> *existing = [map objectForKey:title];
            if (existing)
            {
                count = [NSString stringWithFormat:@"%i", existing[@"count"].intValue + 1];
                color = existing[@"color"];
                categories[@"count"] = count;
                categories[@"color"] = color;
            }

            if (!existing || (existing[@"color"].length == 0 && color.length != 0))
                categories[@"color"] = color;

            [map setObject:categories forKey:title];
        }
        else if (withDefaultCategory)
        {
            categories[@"title"] = title;
            categories[@"color"] = color;
            categories[@"count"] = [NSString stringWithFormat:@"%i", [[map objectForKey:title][@"count"] intValue] + 1];
            [map setObject:categories forKey:title];
        }
    }
    [_gpxDocument.pointsGroups enumerateKeysAndObjectsUsingBlock:^(NSString *key, OASGpxUtilitiesPointsGroup *group, BOOL *stop) {
        NSString *title = key ?: @"";
        if ((title.length > 0 || withDefaultCategory) && ![map objectForKey:title])
        {
            NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
            categories[@"title"] = title;
            categories[@"color"] = UIColorFromARGB(group.color).toHexARGBString;
            categories[@"count"] = @"0";
            categories[@"hidden"] = group.hidden ? @"true" : @"false";
            [map setObject:categories forKey:title];
        }
    }];
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *groups = [NSMutableArray new];
    for (NSDictionary<NSString *, NSString *> *category in map.objectEnumerator)
    {
        NSMutableDictionary<NSString *, NSString *> *group = [category mutableCopy];
        int color = _gpxDocument.pointsGroups[group[@"title"]].color;
        if (color == 0)
            color = [UIColor toNumberFromString:group[@"color"]];
        if (color == 0)
            color = [[OADefaultFavorite getDefaultColor] toARGBNumber];
        group[@"color"] = UIColorFromARGB(color).toHexARGBString;
        group[@"category"] = group[@"title"];
        [groups addObject:[group copy]];
    }
    return [groups copy];
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getGroups
{
    NSArray<NSDictionary<NSString *, NSString *> *> *groups = [self getWaypointCategoriesWithAllData:YES];

    NSMutableArray *combinedGroups = [groups mutableCopy];
    for (OASGpxUtilitiesPointsGroup *pendingGroup in _pendingGroups)
    {
        if (_gpxDocument.pointsGroups[pendingGroup.name])
            continue;
        NSUInteger index = [combinedGroups indexOfObjectPassingTest:^BOOL(NSDictionary *group, NSUInteger index, BOOL *stop) {
            return [group[@"category"] isEqualToString:pendingGroup.name];
        }];
        NSString *count = index == NSNotFound ? @"0" : combinedGroups[index][@"count"];
        NSDictionary *group = @{@"title": pendingGroup.name,
                               @"category": pendingGroup.name,
                               @"color": UIColorFromARGB(pendingGroup.color).toHexARGBString,
                               @"count": count};
        if (index == NSNotFound)
            [combinedGroups addObject:group];
        else
            combinedGroups[index] = group;
    }
    groups = combinedGroups;

    BOOL hasDefaultGroup = NO;
    for (NSDictionary<NSString *, NSString *> *group in groups)
    {
        if ([group[@"title"] isEqualToString:@""])
        {
            NSMutableDictionary *newGroup = [group mutableCopy];
            newGroup[@"title"] = OALocalizedString(@"shared_string_waypoints");
            NSMutableArray *newGroups = [groups mutableCopy];
            [newGroups removeObject:group];
            [newGroups insertObject:newGroup atIndex:0];
            groups = newGroups;
            hasDefaultGroup = YES;
            break;
        }
    }
    if (!hasDefaultGroup)
    {
        NSMutableDictionary<NSString *, NSString *> *defaultGroup = [NSMutableDictionary new];
        defaultGroup[@"title"] = OALocalizedString(@"shared_string_waypoints");
        defaultGroup[@"category"] = @"";
        defaultGroup[@"color"] = [OADefaultFavorite getDefaultColor].toHexARGBString;
        defaultGroup[@"count"] = @"0";
        NSMutableArray *newGroups = [groups mutableCopy];
        [newGroups insertObject:defaultGroup atIndex:0];
        groups = newGroups;
    }

    NSMutableArray *immutableGroups = [NSMutableArray new];
    for (NSDictionary *group in groups)
        [immutableGroups addObject:[group copy]];
    return [immutableGroups copy];
}

- (NSDictionary<NSString *, NSString *> *)getGroupsWithColors
{
    NSMutableDictionary<NSString *, NSString *> *colors = [NSMutableDictionary new];
    for (NSDictionary<NSString *, NSString *> *group in [self getGroups])
        colors[group[@"category"]] = group[@"color"];
    return [colors copy];
}

- (NSString *)getName
{
    return _gpxWpt.point.name;
}

- (NSString *)getIcon
{
    return _iconName;
}

- (NSString *)getBackgroundIcon
{
    return [_gpxWpt.point getBackgroundType];
}

- (NSString *)getAddress
{
    return [_gpxWpt.point getAddress];
}

- (void)setGroup:(NSString *)groupName color:(UIColor *)color
{
    BOOL hasGroup = [self getGroupsWithColors][groupName ?: @""] != nil;
    _gpxWpt.point.category = groupName.length > 0 ? groupName : nil;
    OASInt *colorToSave = [[OASInt alloc] initWithInt:[color toARGBNumber]];
    [_gpxWpt.point setColorColor:colorToSave];
    _gpxWpt.color = color;

    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[color toARGBNumber]]];

    if (groupName.length > 0 && !hasGroup)
    {
        if (!_pendingGroups)
            _pendingGroups = [NSMutableArray new];
        [_pendingGroups addObject:[[OASGpxUtilitiesPointsGroup alloc] initWithName:groupName
                                                                       iconName:nil
                                                                 backgroundType:nil
                                                                          color:color.toARGBNumber
                                                                         hidden:NO]];
    }
}

- (void)addGroupWithName:(NSString *)name color:(UIColor *)color iconName:(NSString *)iconName backgroundIconName:(NSString *)backgroundIconName
{
    [self setGroup:name color:color];
    for (OASGpxUtilitiesPointsGroup *group in _pendingGroups)
    {
        if ([group.name isEqualToString:name])
        {
            group.iconName = iconName;
            group.backgroundType = backgroundIconName;
            break;
        }
    }
}

- (void)deleteItem
{
    if (self.gpxWptDelegate)
        [self.gpxWptDelegate deleteGpxWpt:_gpxWpt docPath:_gpxFileName];
}

- (void)deleteItem:(BOOL)isNewItemAdding
{
    [self deleteItem];
}

- (void)savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint
{
    [_gpxWpt.point setName:data.name.length > 0 ? data.name : nil];
    [_gpxWpt.point setDesc:data.descr.length > 0 ? data.descr : nil];
    [self setGroup:data.category color:data.color];
    [_gpxWpt.point setIconNameIconName:data.icon];
    [_gpxWpt.point setBackgroundTypeBackType:data.backgroundIcon];
    
    auto extension = _gpxWpt.point.getExtensionsToWrite;
    extension[ADDRESS_EXTENSION_KEY] = data.address.length > 0 ? data.address : nil;
    _gpxWpt.point.extensions = extension;
    
    _gpxWpt.docPath = _gpxFileName;
    _gpxWpt.pendingGroups = [_pendingGroups copy];

    if (newPoint)
    {
        if (self.gpxWptDelegate)
            [self.gpxWptDelegate saveGpxWpt:_gpxWpt gpxFileName:_gpxFileName];
    }
    else
    {
        if (self.gpxWptDelegate)
            [self.gpxWptDelegate updateGpxWpt:_gpxWpt docPath:_gpxFileName updateMap:YES];
    }
}

@end
