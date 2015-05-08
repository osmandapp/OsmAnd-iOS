//
//  OAPOIFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAPOIFilter : NSObject<NSCopying>

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *nameLocalizedEN;
@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) NSString *category;
@property (nonatomic) NSString *categoryLocalizedEN;
@property (nonatomic) NSString *categoryLocalized;

@property (nonatomic) BOOL top;

- (UIImage *)icon;

@end
