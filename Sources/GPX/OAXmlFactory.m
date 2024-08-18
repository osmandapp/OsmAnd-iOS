//
//  OAXmlFactory.m
//  OsmAnd Maps
//
//  Created by Alexey K on 16.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAXmlFactory.h"
#import "OAXmlStreamReader.h"
#import "OAXmlStreamWriter.h"

@implementation OAXmlFactory

- (id<OASXmlPullParserAPI>)createXmlPullParserApi __attribute__((swift_name("createXmlPullParserApi()")))
{
    return [[OAXmlStreamReader alloc] init];
}

- (id<OASXmlSerializerAPI>)createXmlSerializerApi __attribute__((swift_name("createXmlSerializerApi()")))
{
    return [[OAXmlStreamWriter alloc] init];
}

@end
