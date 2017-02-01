//
//  OACustomSearchButton.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACustomSearchButton.h"
#import "Localization.h"

@implementation OACustomSearchButton

- (instancetype)initWithClickFunction:(OACustomSearchButtonOnClick)onClickFunction
{
    self = [super init];
    if (self)
    {
        _onClickFunction = onClickFunction;
    }
    return self;
}

-(NSString *)getName
{
    return OALocalizedString(@"custom_search");
}

@end
