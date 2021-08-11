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

- (id) initWithDestination:(OADestination *)destination
{
    self = [self init];
    if (self)
    {
        _destination = destination;
    }
    return self;
}

-(NSString *) getCommonTypeStr
{
    return OALocalizedString(@"ctx_mnu_direction");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportsForceClose
{
    return YES;
}

- (BOOL) shouldEnterContextModeManually
{
    return YES;
}

- (BOOL)hasDismissButton
{
    return YES;
}

@end
