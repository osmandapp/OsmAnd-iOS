//
//  OADestinationsHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OADestination;

@interface OADestinationsHelper : NSObject

@property (nonatomic, readonly) NSArray* topDestinations;

+ (OADestinationsHelper *)instance;

- (void)refreshTopDestinations;
- (NSInteger)pureDestinationsCount;

- (void)showDestinationOnTop:(OADestination *)destination;

@end
