//
//  OAMenuController.h
//  OsmAnd
//
//  Created by Alexey on 25/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseMenuController.h"
#include <openingHoursParser.h>

@class OAMapContextMenu;
@class OAMenuBuilder;
@class OATitleButtonController, OATitleProgressController;

typedef NS_ENUM(NSInteger, EOAMenuState) {
    EOAMenuStateHeaderOnly = 1,
    EOAMenuStateHalfScreen = 2,
    EOAMenuStateFullScreen = 4
};

typedef NS_ENUM(NSInteger, EOAMenuType) {
    EOAMenuTypeStandard,
    EOAMenuTypeMultiline
};

@interface OAMenuController : OABaseMenuController

@property (nonatomic) OAMapContextMenu *mapContextMenu;
@property (nonatomic) OAMenuBuilder *builder;

@property (nonatomic) OATitleButtonController *leftTitleButtonController;
@property (nonatomic) OATitleButtonController *rightTitleButtonController;
@property (nonatomic) OATitleButtonController *bottomTitleButtonController;

@property (nonatomic) OATitleButtonController *leftDownloadButtonController;
@property (nonatomic) OATitleButtonController *rightDownloadButtonController;
@property (nonatomic) OATitleProgressController *titleProgressController;

//@property (nonatomic) TopToolbarController toolbarController;

//@property (nonatomic) IndexItem indexItem;
@property (nonatomic) BOOL downloaded;

- (BOOL) displayDistanceDirection;
- (BOOL) needStreetName;
- (BOOL) needTypeStr;
- (BOOL) displayStreetNameInTitle;

- (NSString *) getRightIconId;
- (UIImage *) getRightIcon;
- (UIImage *) getSecondLineTypeIcon;
- (UIImage *) getSubtypeIcon;

- (NSString *) getCommonTypeStr;
- (NSString *) getNameStr;
- (NSString *) getFirstNameStr;
- (NSString *) getTypeStr;
- (NSString *) getSubtypeStr;

@end
