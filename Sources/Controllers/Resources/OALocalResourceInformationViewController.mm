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

@interface OALocalResourceInformationViewController ()
@end

@implementation OALocalResourceInformationViewController
{
}

- (instancetype)initWithLocalResourceId:(NSString*)resourceId
{
    QRootElement* rootElement = [OALocalResourceInformationViewController inflateRootWithLocalResourceId:resourceId
                                                                                               forRegion:nil];
    self = [super initWithRoot:rootElement];
    if (self) {
    }
    return self;
}

- (instancetype)initWithLocalResourceId:(NSString*)resourceId
                              forRegion:(OAWorldRegion*)region
{
    QRootElement* rootElement = [OALocalResourceInformationViewController inflateRootWithLocalResourceId:resourceId
                                                                                               forRegion:region];
    self = [super initWithRoot:rootElement];
    if (self) {
    }
    return self;
}

+ (QRootElement*)inflateRootWithLocalResourceId:(NSString*)resourceId
                                      forRegion:(OAWorldRegion*)region
{
    const auto& resource = [OsmAndApp instance].resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    const auto localResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource);
    if (!resource || !localResource)
        return nil;
    const auto installedResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = region ? region.name : OALocalizedString(@"Details");
    rootElement.grouped = YES;

    QSection* mainSection = [[QSection alloc] init];
    [rootElement addSection:mainSection];

    // Type
    QLabelElement* typeField = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Type")
                                                              Value:nil];
    [mainSection addElement:typeField];
    switch (localResource->type)
    {
        case OsmAnd::ResourcesManager::ResourceType::MapRegion:
            typeField.value = OALocalizedString(@"Map");
            break;

        default:
            typeField.value = OALocalizedString(@"Unknown");
            break;
    }

    // Size
    QLabelElement* sizeField = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Size")
                                                              Value:[NSByteCountFormatter stringFromByteCount:localResource->size
                                                                                                   countStyle:NSByteCountFormatterCountStyleFile]];
    [mainSection addElement:sizeField];

    if (installedResource)
    {
        // Timestamp
        QDateTimeElement* timestampField = [[QDateTimeElement alloc] initWithTitle:OALocalizedString(@"Created on")
                                                                              date:[NSDate dateWithTimeIntervalSince1970:installedResource->timestamp / 1000]];
        [mainSection addElement:timestampField];
    }

    return rootElement;
}

@end
