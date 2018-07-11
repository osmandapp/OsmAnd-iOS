//
//  OATargetHistoryItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetHistoryItemViewController.h"
#import "OAHistoryItem.h"
#import "Localization.h"

@interface OATargetHistoryItemViewController ()

@end

@implementation OATargetHistoryItemViewController

- (id) initWithHistoryItem:(OAHistoryItem *)historyItem
{
    self = [self init];
    if (self)
    {
        _historyItem = historyItem;
    }
    return self;
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"history");
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

@end
