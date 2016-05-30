//
//  OATargetDestinationViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetDestinationViewController.h"
#import "OADestination.h"
#import "Localization.h"

@interface OATargetDestinationViewController ()

@end

@implementation OATargetDestinationViewController

- (id)initWithDestination:(OADestination *)destination
{
    self = [self init];
    if (self)
    {
        _destination = destination;
    }
    return self;
}

-(NSString *)getCommonTypeStr
{
    return OALocalizedString(@"ctx_mnu_direction");
}

@end
