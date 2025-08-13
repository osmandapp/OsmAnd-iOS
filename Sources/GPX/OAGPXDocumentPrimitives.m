//
//  OAGPXDocumentPrimitives.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"
#import "OADefaultFavorite.h"
#import "OAPOI.h"
#import "Osmand_Maps-Swift.h"

@implementation OAGPXColor

+ (instancetype)withType:(EOAGPXColor)type name:(NSString *)name color:(int)color
{
    OAGPXColor *obj = [[OAGPXColor alloc] init];
    if (obj)
    {
        obj.type = type;
        obj.name = name;
        obj.color = color;
    }
    return obj;
}

+ (NSArray<OAGPXColor *> *)values
{
    return @[
            [OAGPXColor withType:BLACK name:@"BLACK" color:0xFF000000],
            [OAGPXColor withType:DARKGRAY name:@"DARKGRAY" color:0xFF444444],
            [OAGPXColor withType:GRAY name:@"GRAY" color:0xFF888888],
            [OAGPXColor withType:LIGHTGRAY name:@"LIGHTGRAY" color:0xFFCCCCCC],
            [OAGPXColor withType:WHITE name:@"WHITE" color:0xFFFFFFFF],
            [OAGPXColor withType:RED name:@"RED" color:0xFFFF0000],
            [OAGPXColor withType:GREEN name:@"GREEN" color:0xFF00FF00],
            [OAGPXColor withType:DARKGREEN name:@"DARKGREEN" color:0xFF006400],
            [OAGPXColor withType:BLUE name:@"BLUE" color:0xFF0000FF],
            [OAGPXColor withType:YELLOW name:@"YELLOW" color:0xFFFFFF00],
            [OAGPXColor withType:CYAN name:@"CYAN" color:0xFF00FFFF],
            [OAGPXColor withType:MAGENTA name:@"MAGENTA" color:0xFFFF00FF],
            [OAGPXColor withType:AQUA name:@"AQUA" color:0xFF00FFFF],
            [OAGPXColor withType:FUCHSIA name:@"FUCHSIA" color:0xFFFF00FF],
            [OAGPXColor withType:DARKGREY name:@"DARKGREY" color:0xFF444444],
            [OAGPXColor withType:GREY name:@"GREY" color:0xFF888888],
            [OAGPXColor withType:LIGHTGREY name:@"LIGHTGREY" color:0xFFCCCCCC],
            [OAGPXColor withType:LIME name:@"LIME" color:0xFF00FF00],
            [OAGPXColor withType:MAROON name:@"MAROON" color:0xFF800000],
            [OAGPXColor withType:NAVY name:@"NAVY" color:0xFF000080],
            [OAGPXColor withType:OLIVE name:@"OLIVE" color:0xFF808000],
            [OAGPXColor withType:PURPLE name:@"PURPLE" color:0xFF800080],
            [OAGPXColor withType:SILVER name:@"SILVER" color:0xFFC0C0C0],
            [OAGPXColor withType:TEAL name:@"TEAL" color:0xFF008080]
    ];
}

+ (OAGPXColor *)getColorFromName:(NSString *)name
{
    for (OAGPXColor *c in [self values])
    {
        if ([c.name caseInsensitiveCompare:name] == NSOrderedSame)
            return c;
    }
    return nil;
}

@end

@implementation OALink
@end
