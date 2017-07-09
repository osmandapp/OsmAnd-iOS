//
//  OALocationPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/LocationPoint.java
//  git revision e5a489637a08d21827a1edd2cf6581339b5f748a

#import <Foundation/Foundation.h>

@class OAPointDescription;

@protocol OALocationPoint <NSObject>
@required

- (double) getLatitude;
- (double) getLongitude;

- (UIColor *) getColor;
- (BOOL) isVisible;
- (OAPointDescription *) getPointDescription;

@end
