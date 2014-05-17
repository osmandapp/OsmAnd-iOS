//
//  OALocalResourceInformationViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALocalResourceInformationViewController.h"

#import <QuickDialog.h>

#import "OsmAndApp.h"
#include "Localization.h"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

#define _(name) OALocalResourceInformationViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OALocalResourceInformationViewController ()
@end

@implementation OALocalResourceInformationViewController
{
    OsmAndAppInstance _app;
}

- (instancetype)initWithLocalResourceId:(NSString*)resourceId
{
    self = [super init];
    if (self) {
        [self ctor];
        _resourceId = resourceId;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
}

- (void)ctor
{
    _app = [OsmAndApp instance];
}

- (void)dtor
{
}

@synthesize resourceId = _resourceId;

- (void)setResourceId:(NSString*)resourceId
{
    _resourceId = resourceId;

    [self loadInformationFrom:resourceId];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_resourceId != nil)
        [self loadInformationFrom:_resourceId];
}

- (void)loadInformationFrom:(NSString*)resourceId
{
    QRootElement* rootElement = [[QRootElement alloc] init];

    const auto& resource = _app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    const auto installedResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(resource);
    if (!resource || !installedResource)
    {
        rootElement.title = @"NOT FOUND";
        self.root = rootElement;
        return;
    }

    rootElement.title = OALocalizedString(@"Details");
    rootElement.grouped = NO;
    QSection* mainSection = [[QSection alloc] init];
    [rootElement addSection:mainSection];

    // Size
    [mainSection addElement:[[QLabelElement alloc] initWithTitle:OALocalizedString(@"Size")
                                                           Value:[NSByteCountFormatter stringFromByteCount:resource->size
                                                                                                countStyle:NSByteCountFormatterCountStyleFile]]];

    // Timestamp
    [mainSection addElement:[[QDateTimeElement alloc] initWithTitle:OALocalizedString(@"Created on")
                                                               date:[NSDate dateWithTimeIntervalSince1970:installedResource->timestamp / 1000]]];

    self.root = rootElement;
}

@end
