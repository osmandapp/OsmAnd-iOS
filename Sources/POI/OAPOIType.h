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
@property (nonatomic) NSString *tag2;
@property (nonatomic) NSString *value2;

@property (nonatomic) NSString *editTag;
@property (nonatomic) NSString *editValue;

@property (nonatomic) OAPOICategory *category;
@property (nonatomic) OAPOIFilter *filter;

@property (nonatomic, assign) BOOL isText;
@property (nonatomic, assign) BOOL reference;
@property (nonatomic, assign) BOOL mapOnly;
@property (nonatomic, assign) BOOL filterOnly;

@property (nonatomic, assign) int order;

@property (nonatomic) OAPOIBaseType *parentType;
@property (nonatomic) OAPOIType *referenceType;

@property (weak, nonatomic) OAPOI *parent;
@property (nonatomic) NSString *poiAdditionalCategory;
@property (nonatomic) NSString *poiAdditionalCategoryLocalized;

- (instancetype)initWithName:(NSString *)name category:(OAPOICategory *)category;
- (instancetype)initWithName:(NSString *)name category:(OAPOICategory *)category filter:(OAPOIFilter *)filter;

- (void)setAdditional:(OAPOIBaseType *)parentType;

- (UIImage *)mapIcon;

- (NSString *) getEditOsmTag;
-(NSString *) getEditOsmValue;
-(NSString *) getOsmValue;
-(NSString *) getOsmValue2;
-(NSString *) getOsmTag;
-(NSString *) getOsmTag2;

- (BOOL) isReference;
- (NSString *) getCheckedIconName;

@end
