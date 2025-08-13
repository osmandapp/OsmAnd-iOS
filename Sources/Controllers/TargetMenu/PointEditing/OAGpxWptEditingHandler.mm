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
    NSString *_newGroupTitle;
    UIColor *_newGroupColor;
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
    self = [super init];
    if (self)
    {
        _gpxFileName = gpxFileName;
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
        NSDictionary<NSString *, NSString *> *extensions = [poi toTagValue:PRIVATE_PREFIX osmPrefix:OSM_PREFIX_KEY];
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
        NSString *color = point.category == nil ? @"" : UIColorFromARGB([point getColor]).toHexARGBString;
        NSString *count = @"1";
        categories[@"count"] = count;

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
    return map.objectEnumerator.allObjects;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getGroups
{
    NSArray<NSDictionary<NSString *, NSString *> *> *groups = [self getWaypointCategoriesWithAllData:YES];

    if (_newGroupTitle)
    {
        NSMutableDictionary<NSString *, NSString *> *newGroup = [NSMutableDictionary new];
        newGroup[@"title"] = _newGroupTitle;
        newGroup[@"color"] = _newGroupColor.toHexARGBString;
        newGroup[@"count"] = @"0";

        NSMutableArray *newGroups = [NSMutableArray arrayWithArray:groups];
        [newGroups addObject:newGroup];
        groups = newGroups;
    }

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
        defaultGroup[@"color"] = [OADefaultFavorite getDefaultColor].toHexARGBString;
        defaultGroup[@"count"] = @"0";
        NSMutableArray *newGroups = [groups mutableCopy];
        [newGroups insertObject:defaultGroup atIndex:0];
        groups = newGroups;
    }

    return groups;
}

- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithColors:(BOOL)withDefaultCategory
{
    NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
    for (OASWptPt *point in _gpxDocument.getPointsList)
    {
        NSString *title = point.category == nil ? @"" : point.category;
        NSString *color = point.category == nil ? @"" : UIColorFromARGB([point getColor]).toHexARGBString;
        BOOL emptyCategory = title.length == 0;
        if (!emptyCategory)
        {
            NSString *existingColor = categories[title];
            if (!existingColor || (existingColor.length == 0 && color.length != 0))
                categories[title] = color;
        }
        else if (withDefaultCategory)
        {
            categories[title] = color;
        }
    }
    return categories;
}

- (NSDictionary<NSString *, NSString *> *)getGroupsWithColors
{
    NSDictionary<NSString *, NSString *> *groups = [self getWaypointCategoriesWithColors:NO];

    if (_newGroupTitle)
    {
        NSMutableDictionary<NSString *, NSString *> *newGroups = [NSMutableDictionary dictionaryWithDictionary:groups];
        newGroups[@"title"] = _newGroupTitle;
        newGroups[@"color"] = _newGroupColor.toHexARGBString;
        groups = newGroups;
    }

    return groups;
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

- (void)setGroup:(NSString *)groupName color:(UIColor *)color save:(BOOL)save
{
    _gpxWpt.point.category = groupName.length > 0 ? groupName : nil;
    OASInt *colorToSave = [[OASInt alloc] initWithInt:[color toARGBNumber]];
    [_gpxWpt.point setColorColor:colorToSave];
    _gpxWpt.color = color;

    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[color toARGBNumber]]];

    if (![_gpxWpt.groups containsObject:groupName] && groupName.length > 0)
    {
        _gpxWpt.groups = [_gpxWpt.groups arrayByAddingObject:groupName];
        _newGroupTitle = groupName;
        _newGroupColor = color;
    }
    else
    {
        _newGroupTitle = nil;
        _newGroupColor = nil;
    }

    if (save && self.gpxWptDelegate)
        [self.gpxWptDelegate saveItemToStorage:_gpxWpt];
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
    [self setGroup:data.category color:data.color save:NO];
    [_gpxWpt.point setIconNameIconName:data.icon];
    [_gpxWpt.point setBackgroundTypeBackType:data.backgroundIcon];
    
    auto extension = _gpxWpt.point.getExtensionsToWrite;
    extension[ADDRESS_EXTENSION_KEY] = data.address.length > 0 ? data.address : nil;
    _gpxWpt.point.extensions = extension;
    
    _gpxWpt.docPath = _gpxFileName;

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
