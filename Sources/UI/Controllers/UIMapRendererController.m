//
//  UIMapRendererController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "UIMapRendererController.h"

#import "UIMapRendererView.h"

@interface UIMapRendererController ()

@end

@implementation UIMapRendererController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)ctor
{
}

- (void)dtor
{
}

- (void)loadView
{
    // Inflate map renderer view
    self.view = [UIMapRendererView new];
#if !__has_feature(objc_arc)
    self.view = [self.view autorelease];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    // Resume rendering
    UIMapRendererView* mapView = (UIMapRendererView*)self.view;
    [mapView resumeRendering];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // Suspend rendering
    UIMapRendererView* mapView = (UIMapRendererView*)self.view;
    [mapView suspendRendering];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
