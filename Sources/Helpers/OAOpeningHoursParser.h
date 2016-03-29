//
//  OAOpeningHoursParser.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAOpeningHoursParser : NSObject

@property (nonatomic, readonly) NSString *openingHours;

- (instancetype)initWithOpeningHours:(NSString *) openingHours;

- (BOOL) isOpenedForTime:(NSDate *) time;

@end
