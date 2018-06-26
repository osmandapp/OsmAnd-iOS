//
//  OAMenuTitleController.h
//  OsmAnd
//
//  Created by Alexey on 25/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPointDescription;
@class OAMenuController;

@interface OAMenuTitleController : NSObject

// abstract
- (CLLocationCoordinate2D) getLatLon;
- (OAPointDescription *) getPointDescription;
- (NSObject *) getObject;
- (OAMenuController *) getMenuController;

// virtual
- (NSString *) getTitleStr;
- (BOOL) displayStreetNameInTitle;
- (BOOL) hasValidTitle;
- (NSString *) getRightIconId;
- (UIImage *) getRightIcon;
- (UIImage *) getTypeIcon;
- (NSString *) getTypeStr;
- (NSString *) getStreetStr;

@end
