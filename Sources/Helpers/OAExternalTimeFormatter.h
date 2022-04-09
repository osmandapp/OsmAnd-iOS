//
//  OAExternalTimeFormatter.h
//  OsmAnd
//
//  Created by nnngrach on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>

@interface OAExternalTimeFormatter : NSObject

+ (BOOL) isCurrentRegionWithAmpmOnLeft;
+ (std::function<std::string (int, int, bool)> ) getExternalTimeFormatterCallback;
+ (std::vector<std::string>) getLocalizedWeekdays;
+ (std::vector<std::string>) getLocalizedMonths;

@end
