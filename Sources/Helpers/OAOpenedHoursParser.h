//
//  OAOpenedHoursParser.h
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@interface OAOpenedHoursParser : NSObject

- (instancetype)initWithString:(NSString *)openingHours;

- (NSString *)toLocalString;
- (BOOL)isOpenedForTime;

- (UIColor *)getColor;

- (UIColor *)getOpeningHoursColor;
- (NSAttributedString *)getOpeningHoursDescr;

@end
