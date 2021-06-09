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

@property (nonatomic) OAGpxWpt *point;
@property (nonatomic) UIColor *color;
@property (nonatomic) NSArray *groups;

@property (nonatomic, assign) CGFloat direction;
@property (nonatomic) NSString* distance;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic) NSString *docPath;

- (UIImage *) getCompositeIcon;

@end
