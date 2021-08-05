//
//  OACarPlayMarkersListController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayMarkersListController.h"
#import "Localization.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"

#import <CarPlay/CarPlay.h>

@implementation OACarPlayMarkersListController
{
    OADestinationsHelper *_destinationsHelper;
}

- (void) commonInit
{
    _destinationsHelper = OADestinationsHelper.instance;
}

- (NSString *) screenTitle
{
    return OALocalizedString(@"map_markers");
}

- (NSArray<CPListSection *> *) generateSections
{
    NSMutableArray<CPListItem *> *items = [NSMutableArray new];
    if (_destinationsHelper.sortedDestinations.count > 0)
    {
        [_destinationsHelper.sortedDestinations enumerateObjectsUsingBlock:^(OADestination * _Nonnull destination, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *imageName = [destination.markerResourceName stringByAppendingString:@"_small"];
            CPListItem *item = [[CPListItem alloc] initWithText:destination.desc detailText:nil image:[UIImage imageNamed:imageName]];
            item.userInfo = destination;
            [items addObject:item];
        }];
    }
    else
    {
        [items addObject:[[CPListItem alloc] initWithText:OALocalizedString(@"map_markers_empty") detailText:nil]];
    }
    
    return @[[[CPListSection alloc] initWithItems:items]];
}

// MARK: CPListTemplateDelegate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
    OADestination *destination = item.userInfo;
    if (!destination)
    {
        completionHandler();
        return;
    }
    [self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude]];
    [self.interfaceController popToRootTemplateAnimated:YES];
    
    completionHandler();
}

@end
