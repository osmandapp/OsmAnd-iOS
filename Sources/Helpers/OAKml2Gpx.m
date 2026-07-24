//
//  OAKml2Gpx.m
//  OsmAnd
//
//  Created by Paul on 7/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAKml2Gpx.h"
#import <BRCybertron/BRCybertron.h>

@implementation OAKml2Gpx

+ (NSString *) toGpx:(NSData *)inputData
{
    id<CYInputSource> input = [[CYDataInputSource alloc] initWithData:inputData
                                                              options:CYParsingDefaultOptions];
    
    NSString *path = [[NSBundle mainBundle] URLForResource:@"kml2gpx" withExtension:@"xslt"].path;
    CYTemplate *xslt = [CYTemplate templateWithContentsOfFile:path];
    
    return [xslt transformToString:input parameters:nil error:nil];
}

@end
