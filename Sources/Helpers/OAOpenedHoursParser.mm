//
//  OAOpenedHoursParser.mm
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAOpenedHoursParser.h"
#import "OANativeUtilities.h"
#import "OAColors.h"

#include <openingHoursParser.h>

@implementation OAOpenedHoursParser
{
    std::shared_ptr<OpeningHoursParser::OpeningHours> _parser;
    std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>> _openingHoursInfo;
}

- (instancetype)initWithString:(NSString *)openingHours
{
    self = [super init];
    if (self)
    {
        _parser = OpeningHoursParser::parseOpenedHours([openingHours UTF8String]);
        _openingHoursInfo = _parser->getInfo();
    }
    return self;
}

- (NSString *)toLocalString
{
    return [NSString stringWithUTF8String:_parser->toLocalString().c_str()];
}

- (BOOL)isOpenedForTime
{
    return _parser->isOpenedForTime([NSDate.date toTm]);
}

- (UIColor *)getColor
{
    return [self isOpenedForTime] ? UIColorFromRGB(color_place_open) : UIColorFromRGB(color_place_closed);
}

- (UIColor *)getOpeningHoursColor
{
    return [OANativeUtilities getOpeningHoursColor:_openingHoursInfo];
}

- (NSAttributedString *)getOpeningHoursDescr
{
    return [OANativeUtilities getOpeningHoursDescr:_openingHoursInfo];
}

@end
