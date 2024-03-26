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
#import "OAPointDescription.h"

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
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        [_destinationsHelper.sortedDestinations enumerateObjectsUsingBlock:^(OADestination * _Nonnull destination, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *imageName = [destination.markerResourceName stringByAppendingString:@"_small"];
            CPListItem *listItem = [[CPListItem alloc] initWithText:destination.desc
                                                         detailText:nil
                                                              image:[UIImage imageNamed:imageName]
                                                     accessoryImage:nil
                                                      accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            listItem.userInfo = destination;
            listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [self onItemSelected:item completionHandler:completionBlock];
            };
            [items addObject:listItem];
            if (items.count >= maximumItemCount)
                *stop = YES;
        }];
    }
    else
    {
        [items addObject:[[CPListItem alloc] initWithText:OALocalizedString(@"map_markers_empty") detailText:nil]];
    }
    
    return @[[[CPListSection alloc] initWithItems:items]];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    OADestination *destination = item.userInfo;
    if (!destination)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    OAPointDescription *historyName = [[OAPointDescription alloc] initWithType:POINT_TYPE_MARKER name:destination.desc];
    [self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude] historyName:historyName];
    [self.interfaceController popToRootTemplateAnimated:YES completion:nil];

    if (completionBlock)
        completionBlock();
}

@end
