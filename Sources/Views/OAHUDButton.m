//
//  OAHUDButton.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAHUDButton.h"

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"

#define _(name) OAHUDButton__##name
#define commonInit _(commonInit)

@implementation OAHUDButton
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _appearanceChangeObserver;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

    _appearanceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onAppearanceChanged)
                                                           andObserve:_app.appearanceChangeObservable];

    [self updateAppearance];
}

- (void)updateAppearance
{
    [self setBackgroundImage:[self backgroundImage]
                    forState:UIControlStateNormal];
}

- (UIImage*)backgroundImage
{
    return nil;
}

- (void)onAppearanceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAppearance];
    });
}

@end
