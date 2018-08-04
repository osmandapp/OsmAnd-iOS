//
//  OASharedVariables.h
//  OsmAnd
//
//  Created by Alexey on 04/08/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OASharedVariables : NSObject

+ (void) setStatusBarHeight:(CGFloat)statusBarHeight;
+ (CGFloat) getStatusBarHeight;

@end
