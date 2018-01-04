//
//  OAAvoidSpecificRoads.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/QtExtensions.h>
#include <QList>

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Road.h>

@interface OAAvoidSpecificRoads : NSObject

+ (OAAvoidSpecificRoads *) instance;

- (const QList<std::shared_ptr<const OsmAnd::Road>>) getImpassableRoads;

@end
