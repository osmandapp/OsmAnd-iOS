//
//  OAMapWidgetRegInfo.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapWidgetRegInfo.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OATextInfoWidget.h"
#import "OAWidgetState.h"

@implementation OAMapWidgetRegInfo
{
    NSString *_imageId;
    NSString *_itemId;
    NSString *_message;
    OAWidgetState *_widgetState;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _visibleCollapsible = [NSMutableSet set];
        _visibleModes = [NSMutableSet set];
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key widget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message priorityOrder:(int)priorityOrder left:(BOOL)left
{
    self = [self init];
    if (self)
    {
        _key = key;
        _widget = widget;
        _imageId = imageId;
        _message = message;
        _priorityOrder = priorityOrder;
        _left = left;
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key widget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState priorityOrder:(int)priorityOrder left:(BOOL)left
{
    self = [self init];
    if (self)
    {    _key = key;
        _widget = widget;
        _widgetState = widgetState;
        _priorityOrder = priorityOrder;
        _left = left;
    }
    return self;
}

- (NSString *) getImageId
{
    if (_widgetState)
        return [_widgetState getMenuIconId];
    else
        return _imageId;
}

- (NSString *) getMessage
{
    if (_widgetState)
        return [_widgetState getMenuTitle];
    else
        return _message;
}

- (NSString *) getItemId
{
    if (_widgetState)
        return [_widgetState getMenuItemId];
    else
        return _key;
}

- (NSArray<NSString *> *) getImageIds
{
    if (_widgetState)
        return [_widgetState getMenuIconIds];
    else
        return nil;
}

- (NSArray<NSString *> *) getMessages
{
    if (_widgetState)
        return [_widgetState getMenuTitles];
    else
        return nil;
}

- (NSArray<NSString *> *) getItemIds
{
    if (_widgetState)
        return [_widgetState getMenuItemIds];
    else
        return nil;
}

- (void) changeState:(NSString *)stateId
{
    if (_widgetState)
        [_widgetState changeState:stateId];
}

- (BOOL) visibleCollapsed:(OAApplicationMode *)mode
{
    return [_visibleCollapsible containsObject:mode];
}

- (BOOL) visible:(OAApplicationMode *)mode
{
    return [_visibleModes containsObject:mode];
}

- (OAMapWidgetRegInfo *) required:(NSArray<OAApplicationMode *> *)modes
{
    [_visibleModes addObjectsFromArray:modes];
    return self;
}

- (NSUInteger) hash
{
    if (_message)
        return [_message hash];
    
    return [[self getItemId] hash];
}

- (BOOL) isEqual:(id)obj
{
    if (self == obj)
        return YES;
    else if (!obj)
        return NO;
    else if (![obj isKindOfClass:[OAMapWidgetRegInfo class]])
        return NO;

    OAMapWidgetRegInfo *other = (OAMapWidgetRegInfo *) obj;
    return [[self getItemId] isEqual:[other getItemId]];
}

- (NSComparisonResult) compare:(OAMapWidgetRegInfo *)another
{
    if ([[self getItemId] isEqual:[another getItemId]])
        return NSOrderedSame;

    if (_priorityOrder == another.priorityOrder)
    {
        return [[self getItemId] compare:[another getItemId]];
    }
    return [@(_priorityOrder) compare:@(another.priorityOrder)];
}

@end
