//
//  OAMenuController.m
//  OsmAnd
//
//  Created by Alexey on 25/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMenuController.h"
#import "OAPointDescription.h"

#include <openingHoursParser.h>

@interface OAMenuController ()

@property (nonatomic) int currentMenuState;
@property (nonatomic) EOAMenuType menuType;
@property (nonatomic) OAPointDescription *pointDescription;
@property (nonatomic) CLLocationCoordinate2D latLon;
@property (nonatomic) BOOL active;

//private BinaryMapDataObject downloadMapDataObject;
//private WorldRegion downloadRegion;
//private DownloadIndexesThread downloadThread;

@property (nonatomic) std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>> openingHoursInfo;

@end

@implementation OAMenuController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.menuType = EOAMenuTypeStandard;
    }
    return self;
}

- (BOOL) displayDistanceDirection
{
    return NO;
}

- (BOOL) needStreetName
{
    return ![self displayDistanceDirection];
}

- (BOOL) needTypeStr
{
    return YES;
}

- (BOOL) displayStreetNameInTitle
{
    return NO;
}

- (NSString *) getRightIconId
{
    return nil;
}

- (UIImage *) getRightIcon
{
    return nil;
}

- (UIImage *) getSecondLineTypeIcon
{
    return nil;
}

- (UIImage *) getSubtypeIcon
{
    return nil;
}

- (NSString *) getCommonTypeStr
{
    return @"";
}

- (NSString *) getNameStr
{
    return self.pointDescription.name;
}

- (NSString *) getFirstNameStr
{
    return @"";
}

- (NSString *) getTypeStr
{
    return @"";
}

- (NSString *) getSubtypeStr
{
    return @"";
}

@end
