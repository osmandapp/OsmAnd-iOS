//
//  OAMenuTitleController.m
//  OsmAnd
//
//  Created by Alexey on 25/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMenuTitleController.h"
#import "OAPointDescription.h"
#import "OAMenuController.h"
#import "OAReverseGeocoder.h"

@interface OAMenuTitleController ()

@property (nonatomic) NSString *rightIconId;
@property (nonatomic) UIImage *rightIcon;
@property (nonatomic) NSString *nameStr;
@property (nonatomic) NSString *typeStr;
@property (nonatomic) NSString *commonTypeStr;
@property (nonatomic) UIImage *secondLineTypeIcon;
@property (nonatomic) NSString *streetStr;

@property (nonatomic) NSString *addressNotFoundStr;

@end

@implementation OAMenuTitleController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.nameStr = @"";
        self.typeStr = @"";
        self.commonTypeStr = @"";
        self.streetStr = @"";
    }
    return self;
}

// abstract
- (CLLocationCoordinate2D) getLatLon
{
    return kCLLocationCoordinate2DInvalid;
}

// abstract
- (OAPointDescription *) getPointDescription
{
    return nil;
}

// abstract
- (NSObject *) getObject
{
    return nil;
}

// abstract
- (OAMenuController *) getMenuController
{
    return nil;
}


- (NSString *) getTitleStr
{
    return self.nameStr;
}

- (BOOL) displayStreetNameInTitle
{
    OAMenuController *menuController = [self getMenuController];
    return menuController && [menuController displayStreetNameInTitle];
}

// Has title which does not equal to "Looking up address" and "No address determined"
- (BOOL) hasValidTitle
{
    NSString *title = [self getTitleStr];
    return ![self.addressNotFoundStr isEqualToString:title];
}

- (NSString *) getRightIconId
{
    return self.rightIconId;
}

- (UIImage *) getRightIcon
{
    return self.rightIcon;
}

- (UIImage *) getTypeIcon
{
    return self.secondLineTypeIcon;
}

- (NSString *) getTypeStr
{
    OAMenuController *menuController = [self getMenuController];
    if (menuController && [menuController needTypeStr])
        return self.typeStr;
    else
        return @"";
}

- (NSString *) getStreetStr
{
    if ([self needStreetName])
        return self.streetStr;
    else
        return @"";
}

- (void) initTitle
{
    self.addressNotFoundStr = [OAPointDescription getAddressNotFoundStr];
    
    [self acquireIcons];
    [self acquireNameAndType];
    if ([self needStreetName])
        [self acquireStreetName];
}

- (BOOL) needStreetName
{
    OAMenuController *menuController = [self getMenuController];
    BOOL res = [self getObject] != nil || [self getPointDescription].name.length == 0;
    if (res && menuController)
        res = [menuController needStreetName];
    
    return res;
}

- (void) acquireIcons
{
    OAMenuController *menuController = [self getMenuController];
    
    self.rightIconId = nil;
    self.rightIcon = nil;
    self.secondLineTypeIcon = nil;
    
    if (menuController)
    {
        self.rightIconId = [menuController getRightIconId];
        self.rightIcon = [menuController getRightIcon];
        self.secondLineTypeIcon = [menuController getSecondLineTypeIcon];
    }
}

- (void) acquireNameAndType
{
    NSString *firstNameStr = @"";
    self.nameStr = @"";
    self.typeStr = @"";
    self.commonTypeStr = @"";
    self.streetStr = @"";
    
    OAMenuController *menuController = [self getMenuController];
    if (menuController)
    {
        firstNameStr = [menuController getFirstNameStr];
        self.nameStr = [menuController getNameStr];
        self.typeStr = [menuController getTypeStr];
        self.commonTypeStr = [menuController getCommonTypeStr];
    }
    
    if (self.nameStr.length == 0)
    {
        self.nameStr = self.typeStr;
        self.typeStr = self.commonTypeStr;
    }
    else if (self.typeStr.length == 0)
    {
        self.typeStr = self.commonTypeStr;
    }
    
    if (firstNameStr.length > 0)
        self.nameStr = [NSString stringWithFormat:@"%@ (%@)", firstNameStr, self.nameStr];
}

- (void) acquireStreetName
{
    NSString *streetStr;
    NSString *address = nil;
    CLLocationCoordinate2D latLon = [self getLatLon];
    if (CLLocationCoordinate2DIsValid(latLon))
        address = [[OAReverseGeocoder instance] lookupAddressAtLat:latLon.latitude lon:latLon.longitude];
    
    if (address.length == 0)
        streetStr = [OAPointDescription getAddressNotFoundStr];
    else
        streetStr = address;
    
    if ([self displayStreetNameInTitle])
    {
        self.nameStr = streetStr;
        [[self getPointDescription] setName:self.nameStr];
    }
}

@end
