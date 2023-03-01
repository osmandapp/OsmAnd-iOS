//
//  OABaseCarPlayListController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayListController.h"

#import <CarPlay/CarPlay.h>

@implementation OABaseCarPlayListController
{
    CPListTemplate *_listTemplate;
}


- (NSString *) screenTitle
{
    return @""; // Override
}

- (void) present
{
    _listTemplate = [[CPListTemplate alloc] initWithTitle:self.screenTitle sections:[self generateSections]];
    [self.interfaceController pushTemplate:_listTemplate animated:YES completion:nil];
}

- (NSArray<CPListSection *> *) generateSections
{
    return @[]; // Override
}

- (void) updateSections:(NSArray<CPListSection *> *)sections
{
    [_listTemplate updateSections:sections];
}

@end
