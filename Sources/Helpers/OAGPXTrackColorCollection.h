//
//  OAGPXTrackColorCollection.h
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAMapViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAGPXTrackColor : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) UIColor *color;
@property (nonatomic) NSInteger colorValue;

-(instancetype)initWithName:(NSString *)name colorValue:(NSInteger)colorValue;

@end

@interface OAGPXTrackColorCollection : NSObject

-(instancetype)initWithMapViewController:(OAMapViewController *)mapViewController;

-(NSArray<OAGPXTrackColor *> *) getAvailableGPXColors;
-(OAGPXTrackColor *) getColorForValue:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
