//
//  OAAmenityLocationPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OALocationPoint.h"

@class OAPOI;

@interface OAAmenityLocationPoint : NSObject<OALocationPoint>

@property (nonatomic, readonly) OAPOI *poi;

@end
