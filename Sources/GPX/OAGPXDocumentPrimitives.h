//
//  OAGPXDocumentPrimitives.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"
#import "OsmAndSharedWrapper.h"

#define ICON_NAME_EXTENSION_KEY @"icon"
#define BACKGROUND_TYPE_EXTENSION_KEY @"background"
#define COLOR_NAME_EXTENSION_KEY @"color"
#define ADDRESS_EXTENSION_KEY @"address"
#define CALENDAR_EXTENSION @"calendar_event"
#define PICKUP_DATE @"pickup_date"
#define VISITED_TIME_EXTENSION @"visited_date"
#define CREATION_TIME_EXTENSION @"creation_date"
#define PICKUP_DATE_EXTENSION @"pickup_date"
#define DEFAULT_ICON_NAME_KEY @"special_star"
#define PROFILE_TYPE_EXTENSION_KEY @"profile"

#define PRIVATE_PREFIX @"amenity_"
#define AMENITY_ORIGIN_EXTENSION_KEY @"amenity_origin"
#define OSM_PREFIX_KEY @"osm_tag_"

static NSString * const kGapProfileTypeKey = @"gap";
static NSString * const kTrkptIndexExtension = @"trkpt_idx";

typedef NS_ENUM(NSInteger, EOAGPXColor)
{
    BLACK = 0,
    DARKGRAY,
    GRAY,
    LIGHTGRAY,
    WHITE,
    RED,
    GREEN,
    DARKGREEN,
    BLUE,
    YELLOW,
    CYAN,
    MAGENTA,
    AQUA,
    FUCHSIA,
    DARKGREY,
    GREY,
    LIGHTGREY,
    LIME,
    MAROON,
    NAVY,
    OLIVE,
    PURPLE,
    SILVER,
    TEAL
};

@interface OAGPXColor : NSObject

@property (nonatomic) EOAGPXColor type;
@property (nonatomic) NSString *name;
@property (nonatomic) int color;

+ (instancetype)withType:(EOAGPXColor)type name:(NSString *)name color:(int)color;

+ (NSArray<OAGPXColor *> *)values;
+ (OAGPXColor *)getColorFromName:(NSString *)name;

@end

@interface OALink : NSObject <NSCopying>

@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *type;

@end
