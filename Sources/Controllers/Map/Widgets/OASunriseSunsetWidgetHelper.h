//
//  OASunriseSunsetWidgetHelper.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 14.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface OASunriseSunsetWidgetHelper : NSObject

+ (NSArray<NSString *> *) getNextSunriseSunset:(BOOL)isSunrise;
+ (NSArray<NSString *> *) getTimeLeftUntilSunriseSunset:(BOOL)isSunrise;

@end
