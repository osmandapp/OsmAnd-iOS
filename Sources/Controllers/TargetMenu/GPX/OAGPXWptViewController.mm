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
#import "OAGPXDocumentPrimitives.h"
#import "OAMapViewController.h"
#import "OACollapsableWaypointsView.h"
#import "OAPOI.h"
#import "OAPOIViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OACollapsableCoordinatesView.h"
#import "OATextMultilineTableViewCell.h"
#import "OAPOIHelper.h"
#import "OANativeUtilities.h"
#import "GeneratedAssetSymbols.h"
#import "OAMapPanelViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OASelectedGPXHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OAGPXWptViewController
{
    OsmAndAppInstance _app;
    NSString *_gpxFileName;
    OAPOI *_originObject;
    std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>> _openingHoursInfo;
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
        NSDictionary<NSString *, NSString *> *extensions = [self.wpt.point getExtensionsToRead];
        NSString *key = [PRIVATE_PREFIX stringByAppendingString:OPENING_HOURS_TAG];
        NSString *openingHoursExt = extensions[key];
        _openingHoursInfo = OpeningHoursParser::getInfo(openingHoursExt && openingHoursExt ? openingHoursExt.UTF8String : "");
        [self acquireOriginObject];
        self.topToolbarType = ETopToolbarTypeMiddleFixed;
        self.leftControlButton = [[OATargetMenuControlButton alloc] init];
        self.leftControlButton.title = OALocalizedString(@"shared_string_open_track");
    }
    return self;
}

- (void) acquireOriginObject
{
    _originObject = [OAPOIHelper findPOIByOriginName:_wpt.getAmenityOriginName lat:_wpt.point.getLatitude lon:_wpt.point.getLongitude];
    if (!_originObject)
        _originObject = [_wpt getAmenity];
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
    
    if (self.wpt.point.link.length > 0)
    {
        [rows addObject:[[OARowInfo alloc] initWithKey:nil
                                                  icon:[OATargetInfoViewController getIcon:@"mx_website"]
                                            textPrefix:nil
                                                  text:self.wpt.point.link
                                             textColor:UIColorFromRGB(kHyperlinkColor)
                                                isText:NO
                                             needLinks:YES
                                                 order:2
                                              typeName:@""
                                         isPhoneNumber:NO
                                                 isUrl:YES]];
    }
    
    //TODO: add extra fields
    //wpt.speed
    //wpt.ele
    //wpt.hdop
    
    if ( _originObject && [ _originObject isKindOfClass:OAPOI.class])
    {
        OAPOIViewController *builder = [[OAPOIViewController alloc] initWithPOI: _originObject];
        builder.location = CLLocationCoordinate2DMake(_wpt.point.lat, _wpt.point.lon);
        NSMutableArray<OARowInfo *> *internalRows = [NSMutableArray array];
        [builder buildRowsInternal:internalRows];
        [rows addObjectsFromArray:internalRows];
    }
    else
    {
        [self buildCoordinateRows:rows];
    }

    [self setRows:rows];
}

- (void) buildWaypointsView:(NSMutableArray<OARowInfo *> *)rows
{
    NSString *name = OALocalizedString(@"context_menu_points_of_group");
    NSString *gpxName = self.wpt.docPath == nil ? OALocalizedString(@"shared_string_currently_recording_track") : [self.wpt.docPath.lastPathComponent stringByDeletingPathExtension];
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
    return OALocalizedString(@"shared_string_waypoint");
}

- (NSAttributedString *) getAttributedTypeStr
{
    return [self getAttributedTypeStr:[self getTypeStr]];
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group
{
    NSAttributedString *attributedTypeStr = [self getAttributedTypeStr:group color:[self getItemColor]];
    NSMutableAttributedString *mutAttributedTypeStr = [[NSMutableAttributedString alloc] initWithAttributedString:attributedTypeStr];
    NSString *rawAddress = [self.wpt.point getAddress];
    if (rawAddress && rawAddress.length > 0) {
        NSString *address = [@"\n" stringByAppendingString:rawAddress];
        [mutAttributedTypeStr appendAttributedString:[[NSAttributedString alloc] initWithString:address]];
    }
    
    [mutAttributedTypeStr addAttributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],
                                           NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary] }
                                  range:NSMakeRange(0, mutAttributedTypeStr.length)];
    return mutAttributedTypeStr;
}

- (UIColor *) getAdditionalInfoColor
{
    return [OANativeUtilities getOpeningHoursColor:_openingHoursInfo];
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return [OANativeUtilities getOpeningHoursDescr:_openingHoursInfo];
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
    return (self.wpt.point.category ? self.wpt.point.category : @"");
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

- (void) leftControlButtonPressed
{
    OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.wpt.docPath]];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel targetHideMenu:0 backButtonClicked:YES onComplete:^{
        if (gpx)
        {
            auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
            trackItem.dataItem = gpx;
            [mapPanel openTargetViewWithGPX:trackItem selectedTab:EOATrackMenuHudOverviewTab selectedStatisticsTab:EOATrackMenuHudSegmentsStatisticsOverviewTab openedFromMap:YES];
        }
    }];
}

@end
