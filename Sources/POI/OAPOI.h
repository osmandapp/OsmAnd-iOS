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
@property (nonatomic, assign) BOOL hasOpeningHours;
@property (nonatomic) NSString *openingHours;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic) NSString *distance;
@property (nonatomic, assign) double direction;

@property (nonatomic) NSDictionary *localizedNames;
@property (nonatomic) NSDictionary *localizedContent;

- (UIImage *)icon;

@end
