//
//  OAConfigureMenuScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OADashboardScreen.h"

typedef NS_ENUM(NSInteger, EConfigureMenuScreen)
{
    EConfigureMenuScreenUndefined = -1,
    EConfigureMenuScreenMain = 0,
    EConfigureMenuScreenVisibility = 1,
};

@protocol OAConfigureMenuScreen <NSObject, OADashboardScreen, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly) EConfigureMenuScreen configureMenuScreen;

@end
