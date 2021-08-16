//
//  OADestinationItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OADestination.h"

@interface OADestinationItem : NSObject

@property (nonatomic) OADestination *destination;
@property (nonatomic, assign) CGFloat distance;
@property (nonatomic) NSString *distanceStr;
@property (nonatomic, assign) CGFloat direction;

@end
