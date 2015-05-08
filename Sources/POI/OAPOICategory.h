//
//  OAPOICategory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAPOICategory : NSObject<NSCopying>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *tag;

@property (nonatomic) NSString *nameLocalizedEN;
@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) BOOL top;

- (UIImage *)icon;

@end
