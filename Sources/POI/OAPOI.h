//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAPOI : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *valueLocalized;

@property (nonatomic) NSString *category;
@property (nonatomic) NSString *filter;

@end
