//
//  OAGpxWptItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAFavoritesHelper.h"
#import "OAPOI.h"
#import "OADefaultFavorite.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGpxWptItem
{
    OASWptPt *_originalPointSnapshot;
}

+ (instancetype)withGpxWpt:(OASWptPt *)gpxWpt
{
    OAGpxWptItem *gpxWptItem = [[OAGpxWptItem alloc] init];
    if (gpxWptItem)
    {
        gpxWptItem.point = gpxWpt;
    }
    return gpxWptItem;
}

- (void)setPoint:(OASWptPt *)point
{
    _point = point;
    self.originalPoint = point;
    _gpxFile = nil;
    [self acquireColor];
}

- (void)setOriginalPoint:(OASWptPt *)originalPoint
{
    _originalPoint = originalPoint;
    // A hidden track can be reloaded after the original in-memory point was edited.
    _originalPointSnapshot = originalPoint ? [[OASWptPt alloc] initWithWptPt:originalPoint] : nil;
}

- (void)prepareForEditing
{
    if (_point && _point == _originalPoint)
        _point = [[OASWptPt alloc] initWithWptPt:_point];
}

+ (NSArray<OASWptPt *> *)storedPointsForItems:(NSArray<OAGpxWptItem *> *)items inGpxFile:(OASGpxFile *)gpxFile
{
    if (!gpxFile)
        return nil;

    NSPointerFunctionsOptions identity = NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality;
    NSHashTable<OASWptPt *> *stored = [NSHashTable hashTableWithOptions:identity];
    for (OASWptPt *point in gpxFile.getPointsList)
        [stored addObject:point];
    NSMapTable<OASWptPt *, OASWptPt *> *snapshots = [NSMapTable mapTableWithKeyOptions:identity valueOptions:NSPointerFunctionsStrongMemory];
    for (OAGpxWptItem *item in items)
    {
        if (item.originalPoint)
            [snapshots setObject:item->_originalPointSnapshot forKey:item.originalPoint];
    }

    NSMutableArray<NSString *> *storedKeys = nil;
    NSMutableDictionary<NSString *, NSMutableIndexSet *> *matches = [NSMutableDictionary dictionary];
    NSMapTable<OASGpxFile *, NSCountedSet<NSString *> *> *sourceKeys = [NSMapTable mapTableWithKeyOptions:identity valueOptions:NSPointerFunctionsStrongMemory];
    NSMapTable<OASGpxFile *, NSNumber *> *unchangedSources = [NSMapTable mapTableWithKeyOptions:identity valueOptions:NSPointerFunctionsStrongMemory];
    NSHashTable<OASWptPt *> *selected = [NSHashTable hashTableWithOptions:identity];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithCapacity:items.count];
    for (OAGpxWptItem *item in items)
    {
        OASWptPt *point = item.originalPoint;
        if (!point)
            return nil;
        NSUInteger sourceIndex = item.gpxFile ? [item.gpxFile.getPointsList indexOfObjectIdenticalTo:point] : NSNotFound;
        if (item.gpxFile && sourceIndex == NSNotFound)
            return nil; // A deleted waypoint must not resolve to an equal remaining point.

        if (![stored containsObject:point])
        {
            // Only reloads need value matching. Build each document's keys once per operation.
            if (!storedKeys)
            {
                storedKeys = [NSMutableArray array];
                for (OASWptPt *candidate in gpxFile.getPointsList)
                {
                    NSString *key = [self matchingKeyForPoint:candidate inGpxFile:gpxFile];
                    if (!matches[key])
                        matches[key] = [NSMutableIndexSet indexSet];
                    [matches[key] addIndex:storedKeys.count];
                    [storedKeys addObject:key];
                }
            }
            if (item.gpxFile && ![sourceKeys objectForKey:item.gpxFile])
            {
                NSMutableArray<NSString *> *keys = [NSMutableArray array];
                for (OASWptPt *candidate in item.gpxFile.getPointsList)
                    [keys addObject:[self matchingKeyForPoint:([snapshots objectForKey:candidate] ?: candidate) inGpxFile:gpxFile]];
                [sourceKeys setObject:[[NSCountedSet alloc] initWithArray:keys] forKey:item.gpxFile];
                [unchangedSources setObject:@([keys isEqualToArray:storedKeys]) forKey:item.gpxFile];
            }
            NSString *key = [self matchingKeyForPoint:item->_originalPointSnapshot inGpxFile:gpxFile];
            NSIndexSet *indexes = matches[key];
            NSCountedSet<NSString *> *source = item.gpxFile ? [sourceKeys objectForKey:item.gpxFile] : nil;
            NSUInteger index = NSNotFound;
            if (indexes.count == 1 && [source countForObject:key] <= 1)
                index = indexes.firstIndex;
            else if (item.gpxFile && [[unchangedSources objectForKey:item.gpxFile] boolValue])
                index = sourceIndex; // Identical duplicates retain their order in an unchanged list.
            if (index == NSNotFound)
                return nil;
            point = gpxFile.getPointsList[index];
        }
        if ([selected containsObject:point])
            return nil;
        [selected addObject:point];
        [points addObject:point];
    }
    return points;
}

+ (NSString *)matchingKeyForPoint:(OASWptPt *)point inGpxFile:(OASGpxFile *)gpxFile
{
    OASGpxFormatter *formatter = OASGpxFormatter.shared;
    NSArray *fields = @[[formatter formatLatLonValue:point.lat], [formatter formatLatLonValue:point.lon],
                       @(point.time / 1000), [formatter formatDecimalValue:point.ele], [formatter formatDecimalValue:point.hdop],
                       point.name ?: @"", point.category ?: @"", point.desc ?: @"", point.comment ?: @"",
                       [self linksForPoint:point], [self extensionsForPoint:point group:gpxFile.pointsGroups[point.category ?: @""]]];
    // Canonical serialization keeps dictionary insertion order out of the lookup key.
    NSData *data = [NSJSONSerialization dataWithJSONObject:fields options:NSJSONWritingSortedKeys error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSArray<NSArray<NSString *> *> *)linksForPoint:(OASWptPt *)point
{
    NSMutableArray *links = [NSMutableArray array];
    for (OASLink *link in point.links)
    {
        if (![OASKAlgorithms.shared isBlankS:link.href])
            [links addObject:@[link.href, link.text ?: @"", link.type ?: @""]];
    }
    return links;
}

+ (NSDictionary<NSString *, NSString *> *)extensionsForPoint:(OASWptPt *)point group:(OASGpxUtilitiesPointsGroup *)group
{
    NSMutableDictionary<NSString *, NSString *> *extensions = [point.getExtensionsToRead mutableCopy];
    // The shared GPX reader drops blank values but preserves whitespace in nonblank values.
    for (NSString *key in extensions.allKeys)
    {
        if ([OASKAlgorithms.shared isBlankS:extensions[key]])
            [extensions removeObjectForKey:key];
    }
    // Match the fields serialized by the shared GPX writer, including its omitted route tags.
    [extensions removeObjectsForKeys:@[PROFILE_TYPE_EXTENSION_KEY, kTrkptIndexExtension]];
    if (point.speed > 0)
        extensions[@"speed"] = [OASGpxFormatter.shared formatDecimalValue:point.speed];
    if (!isnan(point.heading))
        extensions[@"heading"] = @(rint(point.heading)).stringValue;
    else if (extensions[@"heading"])
    {
        NSDecimalNumber *heading = [NSDecimalNumber decimalNumberWithString:extensions[@"heading"]];
        if (![heading isEqualToNumber:NSDecimalNumber.notANumber])
            extensions[@"heading"] = heading.stringValue;
    }
    NSString *color = extensions[COLOR_NAME_EXTENSION_KEY] ?: extensions[@"colour"] ?: extensions[@"displaycolor"] ?: extensions[@"displaycolour"];
    extensions[COLOR_NAME_EXTENSION_KEY] = @([OASGpxUtilities.shared parseColorColorString:color].intValue ?: group.color).stringValue;
    extensions[ICON_NAME_EXTENSION_KEY] = extensions[ICON_NAME_EXTENSION_KEY] ?: group.iconName ?: @"";
    extensions[BACKGROUND_TYPE_EXTENSION_KEY] = extensions[BACKGROUND_TYPE_EXTENSION_KEY] ?: group.backgroundType ?: @"";
    return extensions;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self applyColor];
}

- (OAPOI *)getAmenity
{
    NSDictionary<NSString *, NSString *> *extensions = [_point getExtensionsToRead];
    if (extensions.count > 0)
    {
        return [OAPOI fromTagValue:extensions privatePrefix:@"amenity_" osmPrefix:@"osm_tag_"];
    }
    return nil;
}

- (void) setAmenity:(OAPOI *)amenity
{
     [_point setAmenity:amenity];
}

- (NSString *) getAmenityOriginName
{
    return [_point getAmenityOriginName];
}

- (void) setAmenityOriginName:(NSString *)originName
{
    [_point setAmenityOriginNameOriginName:originName];
}

- (void) applyColor
{
    if (!self.point)
        return;
    OASInt *color = [[OASInt alloc] initWithInt:[self.color toARGBNumber]];
    [self.point setColorColor:color];
}

- (void)acquireColor
{
    _color = UIColorFromARGB(self.point.getColor);
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;
    
    OAGpxWptItem *wptItem = (OAGpxWptItem *) o;
    if (!self.docPath && wptItem.docPath)
        return NO;
    if (self.docPath && ![self.docPath isEqualToString:wptItem.docPath])
        return NO;
    if (!self.point && wptItem.point)
        return NO;
    if (self.point && ![self.point isEqual:wptItem.point])
        return NO;
    if (!self.color && wptItem.color)
        return NO;
    if (self.color && ![self.color isEqual:wptItem.color])
        return NO;
    if (self.groups.count != wptItem.groups.count)
        return NO;

    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = self.docPath ? [self.docPath hash] : 0;
    result = 31 * result + (self.groups ? [self.groups hash] : 0);
    result = 31 * result + (self.color ? [self.color hash] : 0);
    return result;
}

- (UIImage *) getCompositeIcon
{
    NSString *iconName = _point.getIconName ?: DEFAULT_ICON_NAME_KEY;
    NSString *backgroundIconName = _point.getBackgroundType ?: DEFAULT_ICON_SHAPE_KEY;
    return [OAFavoritesHelper getCompositeIcon:iconName backgroundIcon:backgroundIconName color:UIColorFromARGB([_point getColor])];
}

- (UIImage *)compositeIconWithDefaultColor
{
    NSString *iconName = _point.getIconName ?: DEFAULT_ICON_NAME_KEY;
    NSString *backgroundIconName = _point.getBackgroundType ?: DEFAULT_ICON_SHAPE_KEY;
    NSInteger color = [_point getColor];
    return [OAFavoritesHelper getCompositeIcon:iconName backgroundIcon:backgroundIconName color:color == 0 ? [OADefaultFavorite getDefaultColor] : UIColorFromARGB(color)];
}

@end
