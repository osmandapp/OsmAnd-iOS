//
//  OAOpeningHoursSelectionViewController.h
//  OsmAnd
//
//  Created by Paul on 2/27/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#include <openingHoursParser.h>

NS_ASSUME_NONNULL_BEGIN

@class OAEditPOIData;

@interface OAOpeningHoursSelectionViewController : OACompoundViewController

-(id)initWithEditData:(OAEditPOIData *)poiData openingHours:(std::shared_ptr<OpeningHoursParser::OpeningHours>)openingHours ruleIndex:(NSInteger)ruleIndex;

@end

NS_ASSUME_NONNULL_END
