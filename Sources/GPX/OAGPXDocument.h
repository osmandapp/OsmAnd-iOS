//
//  OAGPXDocument.h
//  OsmAnd
//
//  Created by Admin on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OsmAndCore/GpxDocument.h"


typedef enum
{
    Unknown = -1,
    None,
    PositionOnly,
    PositionAndElevation,
    DGPS,
    PPS
    
} OAGpxFixType;


@interface OAExtraData : NSObject
@end

@interface OALink : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *text;

@end

@interface OAMetadata : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) OAExtraData *extraData;

@end

@interface OALocationMark : NSObject

@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) CLLocationDistance elevation;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *links;
@property (nonatomic) OAExtraData *extraData;

@end

@interface OATrackPoint : OALocationMark

@end

@interface OATrackSegment : NSObject

@property (nonatomic) NSArray *points;
@property (nonatomic) OAExtraData *extraData;

@end

@interface OATrack : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSArray *segments;
@property (nonatomic) OAExtraData *extraData;

@end

@interface OARoutePoint : OALocationMark

@end

@interface OARoute : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSArray *points;
@property (nonatomic) OAExtraData *extraData;

@end



@interface OAGpxExtension : OAExtraData

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *value;
@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSArray *subextensions;

@end

@interface OAGpxExtensions : OAExtraData

@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSString *value;
@property (nonatomic) NSArray *extensions;

@end

@interface OAGpxLink : OALink

@property (nonatomic) NSString *type;

@end

@interface OAGpxMetadata : OAMetadata

@end

@interface OAGpxWpt : OALocationMark

@property (nonatomic) double magneticVariation;
@property (nonatomic) double geoidHeight;
@property (nonatomic) NSString *source;
@property (nonatomic) NSString *symbol;
@property (nonatomic) OAGpxFixType fixType;
@property (nonatomic) int satellitesUsedForFixCalculation;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double positionDilutionOfPrecision;
@property (nonatomic) double ageOfGpsData;
@property (nonatomic) int dgpsStationId;

@end

@interface OAGpxTrkPt : OATrackPoint

@property (nonatomic) double magneticVariation;
@property (nonatomic) double geoidHeight;
@property (nonatomic) NSString *source;
@property (nonatomic) NSString *symbol;
@property (nonatomic) OAGpxFixType fixType;
@property (nonatomic) int satellitesUsedForFixCalculation;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double positionDilutionOfPrecision;
@property (nonatomic) double ageOfGpsData;
@property (nonatomic) int dgpsStationId;

@end

@interface OAGpxTrkSeg : OATrackSegment

@end

@interface OAGpxTrk : OATrack

@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;

@end

@interface OAGpxRtePt : OARoutePoint

@property (nonatomic) double magneticVariation;
@property (nonatomic) double geoidHeight;
@property (nonatomic) NSString *source;
@property (nonatomic) NSString *symbol;
@property (nonatomic) OAGpxFixType fixType;
@property (nonatomic) int satellitesUsedForFixCalculation;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double positionDilutionOfPrecision;
@property (nonatomic) double ageOfGpsData;
@property (nonatomic) int dgpsStationId;

@end

@interface OAGpxRte : OARoute

@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;

@end



@interface OAGPXDocument : NSObject

@property (nonatomic) OAMetadata* metadata;
@property (nonatomic) NSArray *locationMarks;
@property (nonatomic) NSArray *tracks;
@property (nonatomic) NSArray *routes;
@property (nonatomic) OAExtraData *extraData;

@property (nonatomic) NSString *version;
@property (nonatomic) NSString *creator;

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;
- (id)initWithGpxFile:(NSString *)filename;

- (void) saveTo:(NSString *)filename;

@end















