//
//  OARegionDownloadsViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OARegionDownloadsViewController.h"

#import "OsmAndApp.h"
#import "OATableViewCellWithButton.h"
#include "Localization.h"

#define _(name) OARegionDownloadsViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OARegionDownloadsViewController ()

@end

@implementation OARegionDownloadsViewController
{
    OsmAndAppInstance _app;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _app = [OsmAndApp instance];
}

- (void)setWorldRegion:(OAWorldRegion *)worldRegion
{
    [super setWorldRegion:worldRegion];

    // Set the title
    self.title = worldRegion.name;
}

@end
