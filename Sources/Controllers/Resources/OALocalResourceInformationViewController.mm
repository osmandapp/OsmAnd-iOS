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
    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Details");
    rootElement.grouped = YES;

    QSection* mainSection = [[QSection alloc] init];
    [rootElement addSection:mainSection];

    // Size
    QLabelElement* sizeField = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Size")
                                                              Value:nil];
    [mainSection addElement:sizeField];

    // Timestamp
    QDateTimeElement* timestampField = [[QDateTimeElement alloc] initWithTitle:OALocalizedString(@"Created on")
                                                                          date:[NSDate date]];
    [mainSection addElement:timestampField];

    self = [super initWithRoot:rootElement];
    if (self) {
        const auto& resource = [OsmAndApp instance].resourcesManager->getLocalResource(QString::fromNSString(resourceId));
        const auto installedResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(resource);
        if (!resource || !installedResource)
            return self;

        // Size
        sizeField.value = [NSByteCountFormatter stringFromByteCount:resource->size
                                                         countStyle:NSByteCountFormatterCountStyleFile];

        // Timestamp
        timestampField.dateValue = [NSDate dateWithTimeIntervalSince1970:installedResource->timestamp / 1000];
    }
    return self;
}

@end
