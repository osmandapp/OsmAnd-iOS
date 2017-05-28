//
//  OACommonWords.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/binary/CommonWords.java
//  git revision 5da5d0d41d977acc31473eb7051b4ff0f4f8d118

#import <Foundation/Foundation.h>

@interface OACommonWords : NSObject

+ (int) getCommon:(NSString *)name;
+ (int) getCommonSearch:(NSString *)name;
+ (int) getCommonGeocoding:(NSString *)name;

@end
