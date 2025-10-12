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

static NSString * ICON_NAME_EXTENSION_KEY = @"icon";
static NSString * BACKGROUND_TYPE_EXTENSION_KEY = @"background";
static NSString * COLOR_NAME_EXTENSION_KEY = @"color";
static NSString * ADDRESS_EXTENSION_KEY = @"address";
static NSString * CALENDAR_EXTENSION = @"calendar_event";
static NSString * PICKUP_DATE = @"pickup_date";
static NSString * VISITED_TIME_EXTENSION = @"visited_date";
static NSString * CREATION_TIME_EXTENSION = @"creation_date";
static NSString * PICKUP_DATE_EXTENSION = @"pickup_date";
static NSString * DEFAULT_ICON_NAME_KEY = @"special_star";
static NSString * DEFAULT_ICON_SHAPE_KEY = @"circle";
static NSString * PROFILE_TYPE_EXTENSION_KEY = @"profile";

static NSString * AMENITY_PREFIX = @"amenity_";
static NSString * AMENITY_ORIGIN_EXTENSION_KEY = @"amenity_origin";
static NSString * OSM_PREFIX_KEY = @"osm_tag_";

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
