//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAPOIBaseType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"

@class OAPOI;

@interface OAPOIType : OAPOIBaseType

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

@property (nonatomic) OAPOICategory *category;
@property (nonatomic) OAPOIFilter *filter;

@property (nonatomic, assign) BOOL isText;
@property (nonatomic, assign) BOOL reference;
@property (nonatomic, assign) BOOL mapOnly;

@property (nonatomic, assign) int order;

@property (nonatomic) OAPOIBaseType *parentType;

@property (weak, nonatomic) OAPOI *parent;

- (instancetype)initWithName:(NSString *)name category:(OAPOICategory *)category;

- (void)setAdditional:(OAPOIBaseType *)parentType;

- (UIImage *)mapIcon;

@end
