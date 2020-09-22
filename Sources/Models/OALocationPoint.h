//
//  OALocationPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/LocationPoint.java
//  git revision a196c4b11c6d74d8896eb9d51279871804d5b4b5

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class OAPointDescription;

@protocol OALocationPoint <NSObject>
@required

- (double) getLatitude;
- (double) getLongitude;

- (UIColor *) getColor;
- (BOOL) isVisible;
- (OAPointDescription *) getPointDescription;

@end
