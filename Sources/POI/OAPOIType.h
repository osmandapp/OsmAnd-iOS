//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPOI;

@interface OAPOIType : NSObject<NSCopying>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

@property (nonatomic) NSString *nameLocalizedEN;
@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) NSString *category;
@property (nonatomic) NSString *categoryLocalizedEN;
@property (nonatomic) NSString *categoryLocalized;

@property (nonatomic) NSString *filter;
@property (nonatomic) NSString *filterLocalizedEN;
@property (nonatomic) NSString *filterLocalized;

@property (nonatomic, assign) BOOL reference;
@property (nonatomic, assign) BOOL mapOnly;

@property (weak, nonatomic) OAPOI *parent;

- (UIImage *)icon;
- (UIImage *)mapIcon;

@end
