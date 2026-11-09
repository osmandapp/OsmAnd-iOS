//
//  OABaseCarPlayListController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayListController.h"

#import <CarPlay/CarPlay.h>

NSNotificationName const OACarPlayTemplatesDidChangeNotification = @"OACarPlayTemplatesDidChangeNotification";
NSNotificationName const OACarPlayDidDisconnectNotification = @"OACarPlayDidDisconnectNotification";

@implementation OABaseCarPlayListController
{
    CPListTemplate *_listTemplate;
    BOOL _templateDismissed;
}


- (NSString *) screenTitle
{
    return @""; // Override
}

- (void) present
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:OACarPlayTemplatesDidChangeNotification object:self.interfaceController];
    [NSNotificationCenter.defaultCenter removeObserver:self name:OACarPlayDidDisconnectNotification object:self.interfaceController];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onTemplatesChanged:) name:OACarPlayTemplatesDidChangeNotification object:self.interfaceController];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onCarPlayDisconnected:) name:OACarPlayDidDisconnectNotification object:self.interfaceController];
    _templateDismissed = NO;
    _listTemplate = [[CPListTemplate alloc] initWithTitle:self.screenTitle sections:[self generateSections]];
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

- (void)onTemplatesChanged:(NSNotification *)notification
{
    if (![self.interfaceController.templates containsObject:_listTemplate])
        [self dismissTemplate];
}

- (void)onCarPlayDisconnected:(NSNotification *)notification
{
    [self dismissTemplate];
}

- (void)dismissTemplate
{
    if (_templateDismissed)
        return;
    _templateDismissed = YES;
    [NSNotificationCenter.defaultCenter removeObserver:self name:OACarPlayTemplatesDidChangeNotification object:self.interfaceController];
    [NSNotificationCenter.defaultCenter removeObserver:self name:OACarPlayDidDisconnectNotification object:self.interfaceController];
    [self onTemplateDismissed];
}

- (void)onTemplateDismissed
{
}

@end
