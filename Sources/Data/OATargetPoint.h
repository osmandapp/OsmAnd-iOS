//
//  OATargetPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPointDescription;

typedef NS_ENUM(NSInteger, OATargetPointType)
{
    OATargetNone = -1,
    OATargetLocation = 0,
    OATargetContext,
    OATargetMyLocation,
    OATargetDestination,
    OATargetFavorite,
    OATargetParking,
    OATargetWiki,
    OATargetOsmEdit,
    OATargetOsmNote,
    OATargetOsmOnlineNote,
    OATargetWpt,
    OATargetPOI,
    OATargetTransportStop,
    OATargetTransportRoute,
    OATargetGPX,
    OATargetGPXRoute,
    OATargetGPXEdit,
    OATargetHistoryItem,
    OATargetAddress,
    OATargetTurn,
    OATargetRouteStart,
    OATargetRouteStartSelection,
    OATargetRouteFinish,
    OATargetRouteFinishSelection,
    OATargetRouteIntermediate,
    OATargetRouteIntermediateSelection,
    OATargetImpassableRoad,
    OATargetImpassableRoadSelection,
    OATargetMapillaryImage,
    OATargetHomeSelection,
    OATargetWorkSelection,
    OATargetRouteDetails,
    OATargetRouteDetailsGraph,
    OATargetChangePosition,
    OATargetTransportRouteDetails,
    OATargetDownloadMapSource,
    OATargetRoutePlanning,
    OATargetMapDownload
};

@interface OATargetPoint : NSObject

@property (nonatomic) OATargetPointType type;
@property (nonatomic) UIImage *icon;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *titleSecond;
@property (nonatomic) NSString *titleAddress;
@property (nonatomic) NSString *openingHoursStr;

@property (nonatomic) NSDictionary *values;
@property (nonatomic) NSDictionary *localizedNames;
@property (nonatomic) NSDictionary *localizedContent;

@property (nonatomic) id targetObj;

@property (nonatomic) BOOL toolbarNeeded;
@property (nonatomic) NSInteger segmentIndex;
@property (nonatomic) BOOL centerMap;
@property (nonatomic) BOOL addressFound;
@property (nonatomic) BOOL minimized;

@property (nonatomic) NSAttributedString *ctrlAttrTypeStr;
@property (nonatomic) NSString *ctrlTypeStr;

@property (nonatomic, readonly) OAPointDescription *pointDescription;

@property (nonatomic) int symbolId;
@property (nonatomic) unsigned long long obfId;
@property (nonatomic) NSInteger sortIndex;
@property (nonatomic) NSString* symbolGroupId;

@end
