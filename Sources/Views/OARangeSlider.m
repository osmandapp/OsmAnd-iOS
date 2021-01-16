//
//  OARangeSlider.m
//  OsmAnd
//
//  Created by nnngrach on 13.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARangeSlider.h"


@implementation OARangeSlider
{
    NSMutableArray<NSNumber *> *_hostVCGestureRecognizersStateBackup;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self disableHostVCScroll];
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self restoreHostVCScroll];
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void) disableHostVCScroll
{
    NSArray<__kindof UIGestureRecognizer *> *hostVCRecognizers = [self getHostVCGestureRecognizers];
    if (hostVCRecognizers)
    {
        for (int i = 0; i < hostVCRecognizers.count; i++)
        {
            UIGestureRecognizer *recognizer = hostVCRecognizers[i];
            [_hostVCGestureRecognizersStateBackup addObject:[NSNumber numberWithBool:recognizer.isEnabled]];
            [recognizer setEnabled:NO];
        }
    }
}

- (void) restoreHostVCScroll
{
    NSArray<__kindof UIGestureRecognizer *> *hostVCRecognizers = [self getHostVCGestureRecognizers];
    if (hostVCRecognizers)
    {
        for (int i = 0; i < hostVCRecognizers.count; i++)
        {
            UIGestureRecognizer *recognizer = hostVCRecognizers[i];
            [recognizer setEnabled:_hostVCGestureRecognizersStateBackup[i]];
        }
    }
}

- (NSArray<__kindof UIGestureRecognizer *> *) getHostVCGestureRecognizers
{
    UIViewController *hostVC = [self findHostViewController];
    if (hostVC)
        return hostVC.presentationController.presentedView.gestureRecognizers;
    else
        return nil;
}

- (UIViewController *) findHostViewController
{
    UIResponder *host = self;
    while (![host isKindOfClass: [UIViewController class]])
        host = [host nextResponder];
    
    return (UIViewController *)host;
}

@end
