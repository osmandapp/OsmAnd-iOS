//
//  OAGpxWptItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OASWptPt, OAPOI, OASGpxFile, OASGpxUtilitiesPointsGroup;

@interface OAGpxWptItem : NSObject

+ (instancetype)withGpxWpt:(OASWptPt *)gpxWpt;

@property (nonatomic) OASWptPt *point;
@property (nonatomic) UIColor *color;
@property (nonatomic) NSArray *groups;
@property (nonatomic, copy) NSArray<OASGpxUtilitiesPointsGroup *> *pendingGroups;

- (void)applyPendingGroupsToFile:(OASGpxFile *)file;

@property (nonatomic, assign) CGFloat direction;
@property (nonatomic) NSString* distance;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL routePoint;

@property (nonatomic) NSString *docPath;

- (UIImage *) getCompositeIcon;
- (UIImage *)compositeIconWithDefaultColor;

- (NSString *) getAmenityOriginName;
- (void) setAmenityOriginName:(NSString *)originName;

- (OAPOI *) getAmenity;
- (void) setAmenity:(OAPOI *)amenity;

@end
