//
//  OAManageFavoritesViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/10/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialogController.h>

typedef enum
{
    kManageFavoriteActionTypeManage = 0,
    kManageFavoriteActionTypeShare
}
kManageFavoriteActionType;

@interface OAManageFavoritesViewController : QuickDialogController

- (instancetype)initWithAction:(kManageFavoriteActionType)action;

@property kManageFavoriteActionType manageFavoriteActionType;


@end
