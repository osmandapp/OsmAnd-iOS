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
    BOOL _templateDismissed;
}


- (NSString *) screenTitle
{
    return @""; // Override
}

- (void) present
{
    _templateDismissed = NO;
    _listTemplate = [[CPListTemplate alloc] initWithTitle:self.screenTitle sections:[self generateSections]];
    id delegate = self.interfaceController.delegate;
    if ([delegate conformsToProtocol:@protocol(OACarPlayListLifecycleDelegate)])
        [(id<OACarPlayListLifecycleDelegate>)delegate registerListController:self];
    [self safePushTemplate:_listTemplate animated:YES];
}

- (NSArray<CPListSection *> *) generateSections
{
    return @[]; // Override
}

- (void) updateSections:(NSArray<CPListSection *> *)sections
{
    if (!_templateDismissed)
        [_listTemplate updateSections:sections];
}

- (void)dismissTemplate
{
    if (_templateDismissed)
        return;
    _templateDismissed = YES;
    [self onTemplateDismissed];
}

- (void)onTemplateDismissed
{
}

@end
