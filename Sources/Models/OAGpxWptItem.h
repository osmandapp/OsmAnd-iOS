//
//  OAGpxWptItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGpxWpt;

@interface OAGpxWptItem : NSObject

@property OAGpxWpt *point;
@property CGFloat direction;
@property NSString* distance;
@property double distanceMeters;

@end
