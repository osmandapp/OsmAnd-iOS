//
//  OAGPXWptViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXWptViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAAppSettings.h"
#import "OALog.h"
#import "OADefaultFavorite.h"
#import <UIAlertView+Blocks.h>
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAMapViewController.h"
#import "OACollapsableWaypointsView.h"
#import "OAPOI.h"
#import "OAPOIViewController.h"
#import "OAColors.h"
#import "OACollapsableCoordinatesView.h"
#import "OATextMultiViewCell.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/GpxDocument.h>
#include "Localization.h"
#include "OARootViewController.h"
#include "OASelectedGPXHelper.h"


@implementation OAGPXWptViewController
{
    OsmAndAppInstance _app;
    NSString *_gpxFileName;
    OAPOI *_originObject;
}

- (id) initWithItem:(OAGpxWptItem *)wpt headerOnly:(BOOL)headerOnly
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        if (!wpt.docPath)
        {
            wpt.docPath = [[OASelectedGPXHelper instance] getSelectedGpx:wpt.point].path;
        }
        self.wpt = wpt;
        [self acquireOriginObject];
        self.topToolbarType = ETopToolbarTypeMiddleFixed;
    }
    return self;
}

- (id) initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation gpxFileName:(NSString *)gpxFileName
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        _gpxFileName = gpxFileName;
        
        // Create wpt
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger defaultColor = 0;
        if ([userDefaults objectForKey:kWptDefaultColorKey])
            defaultColor = [userDefaults integerForKey:kWptDefaultColorKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][defaultColor];
        UIColor* color = favCol.color;

        NSString *groupName;
        if ([userDefaults objectForKey:kWptDefaultGroupKey])
            groupName = [userDefaults stringForKey:kWptDefaultGroupKey];
        
        OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
        OAWptPt* p = [[OAWptPt alloc] init];
        p.name = formattedLocation;
        p.position = location;
        p.type = groupName;
        p.time = (long)[[NSDate date] timeIntervalSince1970];
        wpt.point = p;
        wpt.color = color;
        
        self.wpt = wpt;
        [self acquireOriginObject];
        self.topToolbarType = ETopToolbarTypeMiddleFixed;
    }
    return self;
}

- (void) acquireOriginObject
{
    _originObject = [_wpt getAmenity];
    if (!_originObject)
    {
        //TODO: find poi by latlon
        //String originObjectName = wpt.comment;
        //originObject = findAmenityObject(originObjectName, wpt.lat, wpt.lon);
    }
}

- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows
{
    [super buildTopRows:rows];
    [self buildWaypointsView:rows];
}

- (void) buildDescription:(NSMutableArray<OARowInfo *> *)rows
{
    NSString *desc = [self getItemDesc];
    if (desc && desc.length > 0)
    {
        OARowInfo *descriptionRow = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:OALocalizedString(@"enter_description") text:desc textColor:nil isText:NO needLinks:NO order:0 typeName:kDescriptionRowType isPhoneNumber:NO isUrl:NO];
        [rows addObject:descriptionRow];
    }
}

- (void) buildRowsInternal:(NSMutableArray<OARowInfo *> *)rows
{
    [self buildTopRows:rows];
    
    if ([self getTimestamp] && [[self getTimestamp] timeIntervalSince1970] > 0)
    {
        [self buildDateRow:rows timestamp:[self getTimestamp]];
    }
    if (self.wpt.point.comment)
    {
        [self buildCommentRow:rows comment:self.wpt.point.comment];
    }
    
    //TODO: add extra fields
    //wpt.speed
    //wpt.ele
    //wpt.hdop
    //wpt.desc
    //wpt.comment
    
    if ( _originObject && [ _originObject isKindOfClass:OAPOI.class])
    {
        OAPOIViewController *builder = [[OAPOIViewController alloc] initWithPOI: _originObject];
        builder.location = CLLocationCoordinate2DMake(_wpt.point.position.latitude, _wpt.point.position.longitude);
        [builder buildRowsInternal:rows];
    }
    [self setRows:rows];
}

- (void) buildWaypointsView:(NSMutableArray<OARowInfo *> *)rows
{
    NSString *name = OALocalizedString(@"all_group_points");
    NSString *gpxName = self.wpt.docPath == nil ? OALocalizedString(@"track_recording_name") : [self.wpt.docPath.lastPathComponent stringByDeletingPathExtension];
    UIColor *color = [self getItemColor];
    UIImage *icon = [UIImage templateImageNamed:@"ic_custom_folder"];
    
    OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:icon textPrefix:name text:gpxName textColor:color isText:NO needLinks:NO order:1 typeName:kGroupRowType isPhoneNumber:NO isUrl:NO];
    rowInfo.collapsed = YES;
    rowInfo.collapsable = YES;
    rowInfo.height = 64;
    rowInfo.collapsableView = [self getCollapsableWaypointsView:_wpt];
    
    [rows addObject:rowInfo];
}

- (OACollapsableWaypointsView *) getCollapsableWaypointsView:(OAGpxWptItem *)wpt
{
    OACollapsableWaypointsView *collapsableGroupView = [[OACollapsableWaypointsView alloc] init];
    [collapsableGroupView setData:wpt];
    collapsableGroupView.collapsed = YES;
    return collapsableGroupView;
}

- (NSString *) getGpxFileName
{
    return [[_gpxFileName lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL) showNearestWiki;
{
    return YES;
}

- (BOOL) showNearestPoi
{
    return YES;
}

- (NSString *)getTypeStr
{
    NSString *group = [self getItemGroup];
    if (group.length > 0)
        return group;
    else
        return [self getCommonTypeStr];
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"gpx_waypoint");
}

- (NSAttributedString *) getAttributedTypeStr
{
    return [self getAttributedTypeStr:[self getTypeStr]];
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group
{
    return [self getAttributedTypeStr:group color:[self getItemColor]];
}

- (NSString *) getItemName
{
    return self.wpt.point.name;
}

- (UIColor *) getItemColor
{
    return self.wpt.color ? self.wpt.color : ((OAFavoriteColor *) OADefaultFavorite.builtinColors.firstObject).color;
}

- (NSString *) getItemGroup
{
    return (self.wpt.point.type ? self.wpt.point.type : @"");
}

- (NSArray *) getItemGroups
{
    return self.wpt.groups;
}

- (NSString *) getItemDesc
{
    return self.wpt.point.desc;
}

- (NSDate *) getTimestamp
{
    long timestamp = self.wpt.point.time;
    if (timestamp > 0)
        return [NSDate dateWithTimeIntervalSince1970:timestamp];
    else
        return nil;
}

@end
