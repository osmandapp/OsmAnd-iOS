//
//  OADiscountHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OADiscountHelper : NSObject

+ (OADiscountHelper *)instance;

- (void) checkAndDisplay;

@end
