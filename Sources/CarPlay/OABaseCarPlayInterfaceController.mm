//
//  OABaseCarPlayInterfaceController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapActions.h"
#import "OAApplicationMode.h"
#import <CarPlay/CarPlay.h>

@implementation OABaseCarPlayInterfaceController

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController
{
    self = [super init];
    if (self) {
        _interfaceController = interfaceController;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    // override
}

- (void) present
{
    // override
}

- (void) handleTemplateOperation:(NSString *)operation completed:(BOOL)completed error:(NSError *)error
{
    if (!completed || error)
        NSLog(@"[CarPlay] handleTemplateOperation %@ failed. completed=%@ error=%@", operation, completed ? @"YES" : @"NO", error);
}

- (void) safeSetRootTemplate:(CPTemplate *)cpTemplate animated:(BOOL)animated
{
    __weak __typeof(self) weakSelf = self;

    [self.interfaceController setRootTemplate:cpTemplate animated:animated completion:^(BOOL completed, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf handleTemplateOperation:@"setRootTemplate" completed:completed error:error];
    }];
}

- (void) safePushTemplate:(CPTemplate *)cpTemplate animated:(BOOL)animated
{
    __weak __typeof(self) weakSelf = self;

    [self.interfaceController pushTemplate:cpTemplate animated:animated completion:^(BOOL completed, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf handleTemplateOperation:@"pushTemplate" completed:completed error:error];
    }];
}

- (void) safePopTemplateAnimated:(BOOL)animated completion:(nullable OACarPlayTemplateCompletion)completion
{
    __weak __typeof(self) weakSelf = self;

    [self.interfaceController popTemplateAnimated:animated completion:^(BOOL completed, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf handleTemplateOperation:@"popTemplate" completed:completed error:error];
        if (completion)
            completion(completed, error);
    }];
}

- (void) safePopToRootTemplateAnimated:(BOOL)animated
{
    __weak __typeof(self) weakSelf = self;

    [self.interfaceController popToRootTemplateAnimated:animated completion:^(BOOL completed, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        [strongSelf handleTemplateOperation:@"popToRootTemplate" completed:completed error:error];
    }];
}

- (void) startNavigationGivenLocation:(CLLocation *)loc historyName:(nullable OAPointDescription *)historyName
{
    if (loc)
    {
        [OARoutingHelper.sharedInstance setAppMode:OAApplicationMode.CAR];
        [OATargetPointsHelper.sharedInstance navigateToPoint:loc updateRoute:YES intermediate:-1 historyName:historyName];
        [OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:NO showDialog:NO];
    }
}

- (NSArray<CPListSection *> *) generateSingleItemSectionWithTitle:(NSString *)title
{
    CPListItem *item = [[CPListItem alloc] initWithText:title detailText:nil];
    CPListSection *section = [[CPListSection alloc] initWithItems:@[item]];
    return @[section];
}

@end
