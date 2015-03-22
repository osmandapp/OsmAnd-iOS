//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAPOIType.h"

@interface OAPOI : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) OAPOIType *type;
@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double distanceMeters;
@property (nonatomic) NSString *distance;
@property (nonatomic) double direction;

- (UIImage *)icon;

@end
